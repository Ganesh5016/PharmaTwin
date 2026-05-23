# PharmaTwin AI 🧬

> **Advanced AI-Powered Pharmaceutical Digital Twin Platform**  
> Predictive stability assessment and performance optimization of oral solid dosage forms.

---

## 📱 App Preview

PharmaTwin AI is a production-ready Android application featuring:
- 🤖 **5 AI models**: LSTM, XGBoost, Bayesian NN, GRU, Autoencoder
- 🧪 **Digital twin simulation** of tablets/capsules in 3D
- 📊 **Monte Carlo stochastic engine** (1000–10,000 iterations)
- 🌡️ **ICH stability zones** (I, II, III, IVa, IVb, VI)
- 🔐 Firebase Authentication + JWT
- 📄 PDF report generation
- 🎨 Futuristic glassmorphism dark UI

---

## 🗂️ Project Structure

```
pharmatwin_ai/
├── frontend/                    # Flutter Android app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── theme/           # Dark futuristic theme
│   │   │   ├── network/         # Dio API client
│   │   │   ├── constants/       # App constants
│   │   │   ├── providers/       # Auth provider
│   │   │   ├── router/          # GoRouter navigation
│   │   │   └── di/              # Dependency injection
│   │   ├── features/
│   │   │   ├── auth/            # Login, Register, ForgotPassword
│   │   │   ├── dashboard/       # Main analytics dashboard
│   │   │   ├── digital_twin/    # 3D tablet/capsule simulation
│   │   │   ├── predictions/     # AI prediction engine UI
│   │   │   ├── batch/           # Batch management
│   │   │   ├── simulation/      # Monte Carlo simulation
│   │   │   ├── reports/         # PDF report generation
│   │   │   └── admin/           # Admin panel
│   │   └── shared/
│   │       └── widgets/         # Reusable components
│   ├── android/                 # Android-specific config
│   └── pubspec.yaml
│
├── backend/                     # FastAPI Python backend
│   ├── main.py                  # FastAPI app entry point
│   ├── app/
│   │   ├── api/v1/              # REST API endpoints
│   │   │   ├── auth.py          # Authentication
│   │   │   ├── predictions.py   # AI predictions
│   │   │   ├── batches.py       # Batch management
│   │   │   ├── simulations.py   # Monte Carlo
│   │   │   ├── reports.py       # Report generation
│   │   │   ├── dashboard.py     # Dashboard summary
│   │   │   └── admin.py         # Admin endpoints
│   │   ├── core/
│   │   │   ├── config.py        # Settings
│   │   │   ├── database.py      # Async SQLAlchemy
│   │   │   └── firebase.py      # Firebase Admin SDK
│   │   └── models/
│   │       └── models.py        # SQLAlchemy ORM models
│   ├── ml/
│   │   └── inference/
│   │       └── predictor.py     # AI ensemble predictor
│   ├── database/
│   │   └── init.sql             # PostgreSQL schema + seed data
│   ├── Dockerfile
│   ├── requirements.txt
│   └── .env.example
│
├── docker-compose.yml           # Full stack orchestration
└── README.md
```

---

## ⚡ Quick Start

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | ≥ 3.16.0 |
| Dart | ≥ 3.0.0 |
| Python | ≥ 3.11 |
| Docker | ≥ 24.0 |
| PostgreSQL | ≥ 16 (or use Docker) |

---

### 1. Clone & Setup

```bash
git clone <your-repo-url>
cd pharmatwin_ai
```

---

### 2. Backend Setup

#### Option A: Docker (Recommended)

```bash
# Start all services (PostgreSQL + Redis + FastAPI)
docker-compose up -d

# View logs
docker-compose logs -f backend

# API will be available at http://localhost:8000
# Docs: http://localhost:8000/docs
```

#### Option B: Local Python

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment config
cp .env.example .env
# Edit .env with your values

# Start PostgreSQL (if not using Docker)
# Make sure PostgreSQL is running and create the database:
# psql -c "CREATE DATABASE pharmatwin_db;"
# psql -c "CREATE USER pharmatwin WITH PASSWORD 'pharmatwin123';"
# psql -c "GRANT ALL ON DATABASE pharmatwin_db TO pharmatwin;"

# Run migrations (creates tables)
python -c "import asyncio; from app.core.database import engine, Base; asyncio.run(engine.begin().__aenter__().run_sync(Base.metadata.create_all))"

# Start server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

### 3. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project: **pharmatwin-ai**
3. Enable **Authentication** → Email/Password + Google
4. Download `google-services.json` → place in `frontend/android/app/`
5. Generate Admin SDK credentials:
   - Project Settings → Service Accounts → Generate new private key
   - Save as `backend/firebase-credentials.json`

---

### 4. Flutter Frontend Setup

```bash
cd frontend

# Get dependencies
flutter pub get

# Add fonts (create placeholder files for build)
mkdir -p assets/fonts assets/images assets/animations

# For actual Orbitron & SpaceMono fonts, download from Google Fonts:
# https://fonts.google.com/specimen/Orbitron
# https://fonts.google.com/specimen/Space+Mono
# Place in assets/fonts/

# Run on Android emulator
flutter run

# Or build release APK
flutter build apk --release

# The APK will be at:
# build/app/outputs/flutter-apk/app-release.apk
```

---

### 5. Configure API URL

In `frontend/lib/core/constants/app_constants.dart`:

```dart
// Android emulator (default)
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

// Real device (same WiFi network)
static const String baseUrl = 'http://192.168.x.x:8000/api/v1';

// Production
static const String baseUrl = 'https://your-api.example.com/api/v1';
```

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | Firebase token → JWT |
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/refresh` | Refresh JWT token |
| GET  | `/api/v1/auth/me` | Current user profile |
| POST | `/api/v1/predictions/` | Run AI ensemble prediction |
| GET  | `/api/v1/predictions/` | List predictions |
| GET  | `/api/v1/predictions/{id}` | Get prediction detail |
| POST | `/api/v1/batches/` | Create batch |
| GET  | `/api/v1/batches/` | List batches (with search/filter) |
| PATCH| `/api/v1/batches/{id}/status` | Update batch status |
| POST | `/api/v1/simulations/run` | Monte Carlo simulation |
| POST | `/api/v1/simulations/environmental` | Environmental simulation |
| GET  | `/api/v1/dashboard/summary` | Dashboard KPIs |
| POST | `/api/v1/reports/generate` | Generate PDF report |
| GET  | `/api/v1/admin/stats` | Admin statistics |
| GET  | `/api/v1/admin/users` | List all users |
| POST | `/api/v1/admin/ai/retrain` | Trigger model retraining |

---

## 🤖 AI Models

| Model | Purpose | Algorithm |
|-------|---------|-----------|
| LSTM | Stability timeline forecasting | Long Short-Term Memory |
| XGBoost | Degradation risk scoring | Gradient Boosting |
| Bayesian NN | Uncertainty quantification | Monte Carlo Dropout |
| GRU | Time-series prediction | Gated Recurrent Unit |
| Autoencoder | Anomaly detection | Variational Autoencoder |

### Prediction Output Example
```json
{
  "shelf_life_months": 18.2,
  "shelf_life_lower": 17.1,
  "shelf_life_upper": 19.3,
  "confidence": 0.947,
  "stability_score": 0.847,
  "degradation_risk": 0.23,
  "dissolution_profile": [0, 18.3, 42.1, 67.8, 82.4, 94.2, 97.1, 97.8],
  "feature_importance": {
    "Temperature": 0.34,
    "Humidity": 0.28,
    "Drug Load": 0.19,
    "Packaging": 0.12,
    "LogP": 0.07
  },
  "is_anomaly": false,
  "anomaly_score": 0.003
}
```

---

## 🗄️ Database Schema

**Tables**: `users`, `batches`, `predictions`, `simulation_logs`, `stability_reports`, `reports`, `ai_model_metadata`, `calibration_history`, `drug_reference`, `ich_stability_zones`

---

## 🎨 UI Features

- **Dark futuristic theme** with neon cyan/blue/purple palette
- **Glassmorphism panels** with blur effects
- **Particle background** animation (WebGL-style)
- **3D tablet/capsule** custom painter renderer
- **Stability gauge** with animated needle
- **Gaussian distribution previewer** for Monte Carlo
- **FL Chart** integration for stability timelines and histograms
- **Orbitron** font for headers (scientific/futuristic)
- **SpaceMono** font for data (monospace precision)

---

## 🔒 Security

- Firebase Authentication (email + Google OAuth)
- JWT tokens with refresh rotation
- Secure storage for tokens (flutter_secure_storage)
- Role-based access (Admin / Researcher / User)
- HTTPS in production
- CORS configuration
- SQL injection prevention (SQLAlchemy ORM)

---

## 📦 Build APK

```bash
cd frontend

# Debug APK
flutter build apk --debug

# Release APK (requires signing key)
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 ICH Stability Zones

| Zone | Temp | Humidity | Regions |
|------|------|----------|---------|
| I | 21°C | 45% RH | Europe, Canada, Japan |
| II | 25°C | 60% RH | USA, EU (long-term) |
| III | 30°C | 35% RH | Middle East |
| IVa | 30°C | 65% RH | South/SE Asia |
| IVb | 30°C | 75% RH | Brazil, tropics |
| VI (Stress) | 40°C | 75% RH | Accelerated testing |

---

## 📄 License

MIT License — Free for academic and commercial use.

---

## 🏗️ Architecture

```
Flutter App
    │
    ├── Riverpod (State Management)
    ├── GoRouter (Navigation)
    ├── Dio (HTTP Client)
    └── Firebase Auth
           │
           ▼
     FastAPI Backend
           │
    ┌──────┴───────┐
    │              │
PostgreSQL      Redis
(Primary DB)   (Cache)
           │
    ML Inference Layer
    (LSTM│XGB│Bayes│GRU│AE)
```

---

*Built with ❤️ for pharmaceutical research and AI-driven drug development.*
