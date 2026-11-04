# Android Widget Marketplace & Overlay Platform

A Flutter mobile app with an Android widget marketplace, overlay system, cricket timer, text capture with AI routing, and native bridge for usage stats.

## Project Structure

- **Flutter App**: Main mobile application (Phases 1-5 implemented)
- **FastAPI Backend**: Cloud backend for widget marketplace (Phase 6)
- **Android Native**: Device bridge plugin for usage stats and services

## Quick Start Guide

### Option 1: Run Flutter App Only (Local Mode)
```bash
# 1. Install Flutter dependencies
flutter pub get

# 2. Run on Android emulator
flutter run
```

### Option 2: Run Full Stack with FastAPI Backend
```bash
# Step 1: Start FastAPI Backend
cd backend
pip install -r requirements.txt
python run.py
# Backend runs at http://localhost:8000

# Step 2: Run Flutter with API backend enabled
cd ..
flutter run --dart-define=USE_API_BACKEND=true
```

## Detailed Setup Instructions

### Prerequisites

#### For Flutter App:
- Flutter SDK 3.47.9+
- Android SDK (compileSdk 36)
- Android emulator or physical device
- Windows: PowerShell for commands

#### For FastAPI Backend:
- Python 3.9+
- PostgreSQL 13+
- pip (Python package manager)

### Step-by-Step Setup

#### 1. Flutter App Setup
```bash
# Navigate to project root
cd d:\ai-projects\mobile-app

# Install dependencies
flutter pub get

# Verify Flutter setup
flutter doctor

# Build the app (optional)
flutter build apk --debug
```

#### 2. FastAPI Backend Setup
```bash
# Navigate to backend directory
cd backend

# Create virtual environment (recommended)
python -m venv venv
venv\Scripts\activate  # On Windows

# Install Python dependencies
pip install -r requirements.txt

# Setup environment file
copy .env.example .env
# Edit .env with your database settings

# Create PostgreSQL database (run in PostgreSQL shell)
# CREATE DATABASE widget_marketplace;
# CREATE USER widget_user WITH PASSWORD 'your_password';
# GRANT ALL PRIVILEGES ON DATABASE widget_marketplace TO widget_user;

# Start the backend
python run.py
# API available at: http://localhost:8000
# API docs at: http://localhost:8000/docs
```

#### 3. Database Configuration
Edit `backend\.env`:
```env
DATABASE_URL=postgresql://widget_user:your_password@localhost:5432/widget_marketplace
```

#### 4. Running the Complete Application

**Mode 1: Local SQLite (Default)**
```bash
flutter run
# Uses local SQLite database for marketplace
```

**Mode 2: FastAPI Backend**
```bash
# Terminal 1: Start FastAPI backend
cd backend
python run.py

# Terminal 2: Run Flutter with API backend
cd ..
flutter run --dart-define=USE_API_BACKEND=true
```

**Mode 3: Production Build with API**
```bash
flutter build apk --dart-define=USE_API_BACKEND=true
```

### Android-Specific Setup

#### Emulator Requirements
- Android API 36+ (Android 14)
- Google Play Services (for some features)
- Enable "Unknown Sources" for APK installation

#### Device Setup for Overlay
The overlay requires special permissions:
1. Grant "Display over other apps" permission
2. Enable Usage Access for cricket timer stats
3. Grant notification permissions

### Testing the Features

#### 1. Overlay System
- Open app → Tap "Enable Overlay"
- Grant overlay permission
- See floating bubble appear
- Tap bubble to expand/collapse

#### 2. Widget Marketplace
- Navigate to "Marketplace" tab
- Browse available widgets
- Install widgets to "My Widgets"

#### 3. Cricket Timer
- Create a cricket timer widget
- Grant usage access permission
- Timer tracks app usage as cricket score

#### 4. Text Capture
- Select text in any app
- Tap "Share" → "Send to Notebook"
- Text gets categorized by AI

#### 5. FastAPI Integration Test
```bash
# Test API connectivity
curl http://localhost:8000/health
curl http://localhost:8000/listings/

# Check API documentation
# Open browser to: http://localhost:8000/docs
```

## Troubleshooting

### Common Issues

#### Flutter Build Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Fix Kotlin cache issue (if occurs)
# Add to android/gradle.properties:
# kotlin.incremental=false
```

#### FastAPI Connection Issues
1. **Check if backend is running**: `curl http://localhost:8000/health`
2. **Verify database connection**: Check PostgreSQL service
3. **Check CORS settings**: Ensure Flutter app URL is allowed
4. **Check environment variables**: Verify `.env` file settings

#### Overlay Permission Issues
1. Go to Android Settings → Apps → Widget Market → Permissions
2. Enable "Display over other apps"
3. For cricket timer: Enable "Usage access"

#### Emulator Problems
```bash
# List available emulators
flutter emulators

# Launch specific emulator
flutter emulators --launch Pixel_9_API_36

# Create new emulator if needed
flutter emulators --create --name Pixel_9 --api 36
```

### Debugging

#### Flutter Logs
```bash
# Verbose logging
flutter run --verbose

# Check for errors
flutter analyze

# Run tests
flutter test
```

#### FastAPI Logs
- Check console output when running `python run.py`
- API errors appear in terminal
- Database errors show connection issues

#### Network Debugging
```bash
# Test API endpoint
curl -v http://localhost:8000/health

# Check Flutter network requests
# Enable logging in api_client.dart
```

## Configuration Options

### Flutter Environment Variables
- `USE_API_BACKEND`: true/false (default: false)
- `API_BASE_URL`: Backend URL (default: http://localhost:8000)
- `API_AUTH_TOKEN`: For future authentication

### FastAPI Environment Variables
- `DATABASE_URL`: PostgreSQL connection string
- `SECRET_KEY`: JWT secret for authentication
- `ALLOWED_ORIGINS`: CORS allowed domains

### Build Variants
```bash
# Debug build with API
flutter run --dart-define=USE_API_BACKEND=true --debug

# Release build with API
flutter build apk --dart-define=USE_API_BACKEND=true --release

# Profile build for performance
flutter run --dart-define=USE_API_BACKEND=true --profile
```

## Deployment

### Backend Deployment Options
1. **Render.com**: Easy PostgreSQL + FastAPI deployment
2. **Railway.app**: Full-stack platform
3. **AWS Elastic Beanstalk**: Managed AWS deployment
4. **Docker**: Containerized deployment

### Flutter App Deployment
1. **Google Play Store**: Release APK build
2. **Direct APK**: Share debug APK for testing
3. **App Bundle**: Generate app bundle for Play Store

### Database Migration
```bash
# For production database migrations
cd backend
alembic upgrade head
```

## Project Status

### ✅ Completed Features
- Phase 1-5: Core app with local marketplace
- Phase 6: FastAPI backend integration
- Overlay system with bubble/panel UI
- Cricket timer with usage stats
- Text capture with AI routing
- Widget marketplace with templates
- Micro-goals and reminders
- Notebook system for captured text

### 🔄 Current Status
- Overlay: Fixed initialization issue
- Backend: FastAPI scaffolded and ready
- Integration: Flutter ↔ FastAPI connected
- Testing: Ready for API integration tests

## Support

### Documentation
- `backend/README.md`: FastAPI setup and API docs
- `test_api_integration.md`: Integration testing guide
- Code comments: Detailed implementation notes

### Development Tools
- VS Code with Flutter/Dart extensions
- PostgreSQL client (pgAdmin, DBeaver)
- Postman/Insomnia for API testing
- Android Studio for emulator management

### Monitoring
- FastAPI: Built-in `/docs` and `/redoc` endpoints
- Flutter: `flutter run --verbose` for logs
- Database: PostgreSQL logs for queries

## Next Steps

1. **Test API Integration**: Run both backend and app together
2. **Add Authentication**: Implement JWT for user accounts  
3. **Upload Images**: Add widget preview images
4. **Analytics Dashboard**: User and usage statistics
5. **Search Functionality**: Full-text search in API
6. **Real-time Updates**: WebSocket for live changes

---
*Last Updated: Phase 6 completed - FastAPI backend integrated*
