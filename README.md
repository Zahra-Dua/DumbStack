🛡️ SafeNest - Parental Control App
📋 Overview
SafeNest is a comprehensive parental control application built with Flutter that helps parents monitor and ensure their children's safety in the digital age. The app provides real-time tracking, content monitoring, SOS alerts, AI-powered insights, and intelligent harassment detection capabilities. With advanced machine learning integration and multi-layered protection, SafeNest offers complete digital safety for children.
✨ Key Features
🔐 Module 1: Authentication & User Management

Secure Authentication: Email/password and phone number authentication
Role-Based Access: Separate interfaces for Parents and Children
Profile Management: Complete user profile setup and management
Multi-User Support: Link multiple child devices to parent account
Firebase Integration: Secure backend with Firestore database
Session Management: Secure token-based authentication

🌐 Module 2: URL Tracking & Web Monitoring

Browser History Tracking: Monitor all visited websites
Real-Time URL Logging: Instant tracking of web activity
Category Classification: Automatic categorization of websites
Blocked Sites Management: Create and manage blacklists
Safe Browsing API Integration: Google Safe Browsing API for threat detection
Dangerous Content Alerts: Instant notifications for harmful websites
Web Activity Reports: Detailed browsing history and statistics
Time-Based Analysis: Track browsing patterns by time of day

⏰ Module 3: Screen Time Management

Installed Apps List: View all installed applications on child's device
App Usage Monitoring: Track time spent on each application
Usage Statistics: Simple charts showing daily/weekly app usage
App Details: View app name, icon, package name, and usage duration
Usage History: Track historical app usage patterns
Visual Reports: Basic bar charts and pie charts for usage data
Platform Support: Android devices only

📍 Module 4: Location Tracking

Real-Time GPS Tracking: Live location monitoring of children
Geofencing: Create safe zones with custom boundaries
Location History: View historical location data and movement patterns
Google Maps Integration: Visual representation of locations on interactive maps
Background Location Updates: Continuous tracking even when app is in background
Route Playback: Review daily routes and movements
Location Alerts: Notifications when entering/leaving geofenced areas
Multiple Device Tracking: Monitor multiple children simultaneously

📱 Module 5: Communication Monitoring

Call Monitoring: Track incoming and outgoing calls
Call Logs: Complete history with timestamps and durations
Contact Flagging: Flag suspicious or unknown contacts
SMS Message Monitoring: Read and analyze text messages
WhatsApp Integration: Monitor WhatsApp conversations (with consent)
Social Media Monitoring: Track social media interactions
Keyword Detection: Flag messages containing concerning keywords
Harassment Detection: AI-powered cyberbullying detection
Real-Time Alerts: Instant notifications for flagged communications
Contact Whitelist/Blacklist: Manage allowed and blocked contacts

📊 Module 6: Activity Logs & Reports

Dashboard Overview: Simple overview of all monitoring activities
Daily Activity Summary: Basic daily reports for parents
App Usage Reports: Statistics per application with usage time
Location Activity: List of places visited with timestamps
Communication Reports: Summary of calls and messages count
Web Activity: Simple browsing history list
Timeline View: Chronological list of activities
Report Generation: Generate and save reports
Report Sharing: Share reports via email or messaging
Report Download: Download reports as PDF
Simple Charts: Basic bar charts and pie charts for visualization
Date Filtering: View reports for specific dates
Platform Support: Android devices only

🤖 Module 7: AI Recommendations & Insights

GPT-4 Mini Integration: Advanced AI-powered analysis
Behavioral Pattern Recognition: Identify concerning behavior patterns
Personalized Recommendations: Tailored suggestions for each child
Risk Assessment: AI-based threat level evaluation
Content Analysis: Deep analysis of communications and activities
Parenting Tips: AI-generated guidance based on child's behavior
Predictive Alerts: Early warning system for potential issues
Sentiment Analysis: Understand emotional state from communications
Weekly Insights Report: AI-generated comprehensive analysis
Natural Language Processing: Advanced text analysis for harassment detection
Smart Notifications: Context-aware alerts prioritized by importance

🆘 Module 8: SOS & Emergency Alerts

One-Touch SOS Button: Quick emergency alert system
Emergency Contacts: Configure multiple emergency contacts
Automatic Notifications: Instant alerts to parents via push notifications
Location Sharing: Automatic current location sharing during emergencies
Firebase Cloud Functions: Reliable notification delivery system
Emergency Call Integration: Direct call to emergency services
Panic Mode: Discrete activation options
Audio Recording: Optional emergency audio capture
SMS Backup: Backup emergency SMS if internet unavailable
SOS History: Track all emergency alerts
False Alarm Management: Easy alert cancellation

🏗️ Technical Architecture
Frontend

Framework: Flutter (Dart)
State Management: Provider pattern
UI Components: Material Design with custom themes
Platform Support: Android (Primary), with web interface for parent dashboard

Backend

Database: Firebase Firestore
Authentication: Firebase Auth
Cloud Functions: Node.js serverless functions
Notifications: Firebase Cloud Messaging (FCM)
Storage: Firebase Storage for media files

AI & Machine Learning

GPT-4 Mini API: OpenAI integration for intelligent insights
Natural Language Processing: Text analysis and sentiment detection
Pattern Recognition: Behavioral analysis algorithms
Python Backend: Flask server for ML models

External APIs

Google Safe Browsing API: Malicious website detection
OpenAI GPT-4 Mini API: Advanced AI recommendations
Google Maps API: Location services
Firebase Cloud Messaging: Push notifications

Native Integration

Android: Kotlin-based services for background operations
Location Services: Geolocator with native Android optimization
Permissions: Runtime permission handling with flutter_permission_handler
Background Services: Foreground services for continuous monitoring

📦 Project Structure
SafeNest-ParentalControlApp/
├── android/                    # Android native code
│   ├── app/src/main/kotlin/   # Kotlin services
│   └── app/src/main/AndroidManifest.xml
├── ios/                        # iOS native code
├── lib/                        # Flutter app source code
│   ├── models/                 # Data models
│   ├── screens/                # UI screens
│   │   ├── auth/              # Authentication screens
│   │   ├── parent/            # Parent dashboard
│   │   ├── child/             # Child interface
│   │   ├── location/          # Location tracking
│   │   ├── communications/    # Call & message monitoring
│   │   ├── screentime/        # Screen time management
│   │   └── sos/               # Emergency features
│   ├── services/               # Business logic & API services
│   │   ├── auth_service.dart
│   │   ├── location_service.dart
│   │   ├── communication_service.dart
│   │   ├── ai_service.dart
│   │   └── sos_service.dart
│   └── widgets/                # Reusable UI components
├── backend/                    # Python Flask backend
│   ├── app.py                 # Main Flask application
│   ├── harassment_detection.py # ML model for harassment
│   ├── requirements.txt       # Python dependencies
│   └── models/                # ML models
├── cloud_functions/            # Firebase Cloud Functions
│   ├── index.js               # Main functions
│   ├── package.json
│   └── notifications/         # Notification handlers
├── functions/                  # Additional cloud functions
├── assets/                     # Images, fonts, and static files
├── test/                       # Unit and widget tests
└── web/                        # Web-specific files
🚀 Getting Started
Prerequisites

Flutter SDK (latest stable version)

bash   flutter --version

Python Environment (for ML backend)

Python 3.8 or higher
Anaconda (recommended) or pip


Firebase Project

Create a project at Firebase Console
Enable Authentication, Firestore, Cloud Messaging, and Storage


API Keys Required

OpenAI API Key (for GPT-4 Mini)
Google Safe Browsing API Key
Firebase FCM Server Key
Google Maps API Key


Development Tools

Android Studio / VS Code
Git
Postman (for API testing)



Installation
1. Clone the Repository
bashgit clone https://github.com/Zahra-Dua/SafeNest-ParentalControlApp.git
cd SafeNest-ParentalControlApp
2. Flutter Setup
bash# Install Flutter dependencies
flutter pub get

# Check for any issues
flutter doctor
3. Python Backend Setup
Option A: Using Anaconda (Recommended)
bash# Create conda environment
conda create -n safenest python=3.9
conda activate safenest

# Navigate to backend directory
cd backend

# Install dependencies
pip install -r requirements.txt

# Required packages
pip install flask flask-cors tensorflow scikit-learn pandas numpy
Option B: Using pip
bash# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Install dependencies
- Python Backend
pip install -r requirements.txt
- Firebase Configuration
Follow the setup guide in SECRETS_SETUP.md:
bash# Add Firebase config files
android/app/google-services.json      # Android only
- API Keys Configuration
Create .env file in project root:
env# OpenAI Configuration
OPENAI_API_KEY=your_gpt4_mini_api_key_here
OPENAI_MODEL=gpt-4-mini

- Google Safe Browsing API
SAFE_BROWSING_API_KEY=your_safe_browsing_api_key_here

- Firebase
FCM_SERVER_KEY=your_fcm_server_key_here

- Google Maps
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here



