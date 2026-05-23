from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel, EmailStr
from datetime import datetime, timedelta
from typing import Optional
import jwt
import logging

from app.core.database import get_db
from app.core.config import settings
from app.core.firebase import verify_firebase_token
from app.models.models import User, UserRole

router = APIRouter()
security = HTTPBearer()
logger = logging.getLogger(__name__)


# ─── Schemas ───────────────────────────────────────────────────────────────

class FirebaseLoginRequest(BaseModel):
    id_token: str


class RegisterRequest(BaseModel):
    firebase_uid: str
    email: EmailStr
    name: str
    role: str = "researcher"
    id_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    role: str
    user_id: str
    name: str


class RefreshRequest(BaseModel):
    refresh_token: str


class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    role: str
    is_active: bool
    created_at: datetime
    organization: Optional[str] = None

    class Config:
        from_attributes = True


# ─── JWT helpers ────────────────────────────────────────────────────────────

def create_access_token(user_id: str, email: str, role: str) -> str:
    payload = {
        "sub": user_id,
        "email": email,
        "role": role,
        "type": "access",
        "exp": datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_refresh_token(user_id: str) -> str:
    payload = {
        "sub": user_id,
        "type": "refresh",
        "exp": datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    token = credentials.credentials
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token")
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="User not found or inactive")

    return user


async def require_admin(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user


# ─── Endpoints ──────────────────────────────────────────────────────────────

@router.post("/login", response_model=TokenResponse)
async def login(request: FirebaseLoginRequest, db: AsyncSession = Depends(get_db)):
    """Exchange Firebase ID token for JWT."""
    try:
        decoded = verify_firebase_token(request.id_token)
        firebase_uid = decoded["uid"]
        email = decoded.get("email", "")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid Firebase token: {e}")

    # Find or create user
    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()

    if not user:
        # Auto-create user from Firebase data
        user = User(
            firebase_uid=firebase_uid,
            email=email,
            name=decoded.get("name", email.split("@")[0]),
            role=UserRole.RESEARCHER,
        )
        db.add(user)
        await db.flush()

    user.last_login = datetime.utcnow()

    access_token = create_access_token(str(user.id), user.email, user.role)
    refresh_token = create_refresh_token(str(user.id))

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        role=user.role,
        user_id=str(user.id),
        name=user.name,
    )


@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register(request: RegisterRequest, db: AsyncSession = Depends(get_db)):
    """Register a new user."""
    try:
        decoded = verify_firebase_token(request.id_token)
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid Firebase token: {e}")

    # Check existing
    result = await db.execute(select(User).where(User.email == request.email))
    if result.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="User already exists")

    role_map = {
        "admin": UserRole.ADMIN,
        "researcher": UserRole.RESEARCHER,
        "user": UserRole.USER,
    }

    user = User(
        firebase_uid=request.firebase_uid,
        email=request.email,
        name=request.name,
        role=role_map.get(request.role.lower(), UserRole.RESEARCHER),
    )
    db.add(user)
    await db.flush()

    return {"message": "User registered successfully", "user_id": str(user.id)}


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(request: RefreshRequest, db: AsyncSession = Depends(get_db)):
    """Refresh access token."""
    try:
        payload = jwt.decode(
            request.refresh_token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid refresh token")
        user_id = payload.get("sub")
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Refresh token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    access_token = create_access_token(str(user.id), user.email, user.role)
    new_refresh_token = create_refresh_token(str(user.id))

    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,
        role=user.role,
        user_id=str(user.id),
        name=user.name,
    )


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """Get current user profile."""
    return current_user


@router.post("/forgot-password")
async def forgot_password(email: EmailStr):
    """Send password reset email (handled by Firebase on client)."""
    return {"message": "If this email exists, a reset link has been sent."}
