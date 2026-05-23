from sqlalchemy import (
    Column, String, Float, Integer, Boolean, DateTime, 
    Text, JSON, ForeignKey, Enum
)
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid
import enum

from app.core.database import Base


class UserRole(str, enum.Enum):
    ADMIN = "admin"
    RESEARCHER = "researcher"
    USER = "user"


class BatchStatus(str, enum.Enum):
    PENDING = "pending"
    ACTIVE = "active"
    REVIEW = "review"
    PASSED = "passed"
    FAILED = "failed"
    ARCHIVED = "archived"


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    firebase_uid = Column(String(128), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    name = Column(String(255), nullable=False)
    role = Column(Enum(UserRole), default=UserRole.RESEARCHER, nullable=False)
    is_active = Column(Boolean, default=True)
    avatar_url = Column(String(500), nullable=True)
    organization = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_login = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    batches = relationship("Batch", back_populates="owner")
    predictions = relationship("Prediction", back_populates="user")
    reports = relationship("Report", back_populates="user")


class Batch(Base):
    __tablename__ = "batches"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    batch_id = Column(String(50), unique=True, nullable=False, index=True)
    owner_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    # Formulation
    drug_name = Column(String(255), nullable=False)
    dosage_form = Column(String(100), nullable=False)
    strength_mg = Column(Float, nullable=False)
    drug_load_percent = Column(Float, nullable=False)
    batch_size_kg = Column(Float, nullable=False)
    
    # Excipients (JSON)
    excipients = Column(JSON, default={})
    
    # Manufacturing
    manufacturer = Column(String(255), nullable=True)
    manufacturing_date = Column(DateTime(timezone=True), nullable=True)
    expiry_date = Column(DateTime(timezone=True), nullable=True)
    
    # Packaging
    packaging_type = Column(String(100), nullable=True)
    
    # Status
    status = Column(Enum(BatchStatus), default=BatchStatus.PENDING)
    
    # Results
    stability_score = Column(Float, nullable=True)
    degradation_risk = Column(Float, nullable=True)
    predicted_shelf_life_months = Column(Float, nullable=True)
    
    # Metadata
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    owner = relationship("User", back_populates="batches")
    predictions = relationship("Prediction", back_populates="batch")
    simulations = relationship("SimulationLog", back_populates="batch")
    stability_reports = relationship("StabilityReport", back_populates="batch")


class Prediction(Base):
    __tablename__ = "predictions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    batch_id = Column(UUID(as_uuid=True), ForeignKey("batches.id"), nullable=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    # Input parameters
    input_params = Column(JSON, nullable=False)
    
    # AI model outputs
    model_type = Column(String(100), nullable=False)  # 'lstm', 'xgboost', 'bayesian', 'ensemble'
    
    # Predictions
    shelf_life_months = Column(Float, nullable=True)
    shelf_life_lower = Column(Float, nullable=True)
    shelf_life_upper = Column(Float, nullable=True)
    confidence = Column(Float, nullable=True)
    
    stability_score = Column(Float, nullable=True)
    stability_timeline = Column(JSON, nullable=True)
    stability_upper_ci = Column(JSON, nullable=True)
    stability_lower_ci = Column(JSON, nullable=True)
    
    degradation_risk = Column(Float, nullable=True)
    dissolution_profile = Column(JSON, nullable=True)
    failure_probability = Column(Float, nullable=True)
    
    # XAI
    feature_importance = Column(JSON, nullable=True)
    explanation = Column(Text, nullable=True)
    
    # Anomaly detection
    is_anomaly = Column(Boolean, default=False)
    anomaly_score = Column(Float, nullable=True)
    
    # Status
    status = Column(String(50), default="completed")
    error_message = Column(Text, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    batch = relationship("Batch", back_populates="predictions")
    user = relationship("User", back_populates="predictions")


class SimulationLog(Base):
    __tablename__ = "simulation_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    batch_id = Column(UUID(as_uuid=True), ForeignKey("batches.id"), nullable=True)
    
    # Simulation parameters
    simulation_type = Column(String(100), nullable=False)  # 'stability', 'environmental', 'monte_carlo'
    parameters = Column(JSON, nullable=False)
    
    # Results
    results = Column(JSON, nullable=True)
    summary = Column(Text, nullable=True)
    
    # Monte Carlo specific
    n_simulations = Column(Integer, nullable=True)
    mean_shelf_life = Column(Float, nullable=True)
    std_shelf_life = Column(Float, nullable=True)
    percentile_5 = Column(Float, nullable=True)
    percentile_95 = Column(Float, nullable=True)
    
    duration_seconds = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    batch = relationship("Batch", back_populates="simulations")


class StabilityReport(Base):
    __tablename__ = "stability_reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    batch_id = Column(UUID(as_uuid=True), ForeignKey("batches.id"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    report_type = Column(String(100), nullable=False)
    title = Column(String(500), nullable=False)
    
    # Stability data
    ich_zone = Column(String(20), nullable=True)  # 'I', 'II', 'III', 'IVa', 'IVb'
    temperature_c = Column(Float, nullable=True)
    humidity_rh = Column(Float, nullable=True)
    
    # Time points
    time_points_months = Column(JSON, nullable=True)
    assay_results = Column(JSON, nullable=True)
    degradation_products = Column(JSON, nullable=True)
    dissolution_results = Column(JSON, nullable=True)
    physical_appearance = Column(JSON, nullable=True)
    
    # Conclusions
    conclusion = Column(Text, nullable=True)
    recommended_shelf_life = Column(Float, nullable=True)
    recommended_storage = Column(String(255), nullable=True)
    
    # File
    pdf_path = Column(String(500), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    batch = relationship("Batch", back_populates="stability_reports")
    user = relationship("User", back_populates="reports")


class Report(Base):
    __tablename__ = "reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    title = Column(String(500), nullable=False)
    report_type = Column(String(100), nullable=False)
    content = Column(JSON, nullable=True)
    pdf_path = Column(String(500), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="reports")


class AIModelMetadata(Base):
    __tablename__ = "ai_model_metadata"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    model_name = Column(String(100), nullable=False)
    model_type = Column(String(100), nullable=False)
    version = Column(String(50), nullable=False)
    
    # Performance metrics
    mae = Column(Float, nullable=True)
    rmse = Column(Float, nullable=True)
    r2_score = Column(Float, nullable=True)
    accuracy = Column(Float, nullable=True)
    
    # Training info
    training_samples = Column(Integer, nullable=True)
    training_date = Column(DateTime(timezone=True), nullable=True)
    hyperparameters = Column(JSON, nullable=True)
    feature_names = Column(JSON, nullable=True)
    
    is_active = Column(Boolean, default=True)
    model_path = Column(String(500), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class CalibrationHistory(Base):
    __tablename__ = "calibration_history"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    model_name = Column(String(100), nullable=False)
    
    predicted_value = Column(Float, nullable=False)
    actual_value = Column(Float, nullable=False)
    error = Column(Float, nullable=False)
    
    batch_id = Column(UUID(as_uuid=True), ForeignKey("batches.id"), nullable=True)
    calibration_params = Column(JSON, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
