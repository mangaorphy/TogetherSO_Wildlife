# EcoSight - Wildlife Protection App

Flutter mobile application for testing the TogetherSO anti-poaching wildlife detection model.

## Features

### 🏠 Home Screen
- AI-powered conservation overview
- Real-time online/offline status
- Quick access to monitoring and map
- Feature highlights (4 threat types, GPS tracking, offline mode)
- Technology overview

### 📊 Live Monitoring
Three tabs for comprehensive threat monitoring:

#### 1. **Alerts Tab**
- Real-time threat detections
- Statistics dashboard (Total, Critical, Pending, Resolved)
- Detailed alert cards with priority levels, confidence scores, GPS coordinates
- Mark alerts as resolved

#### 2. **Activity Tab**
- Chronological activity feed grouped by date
- Visual priority indicators

#### 3. **Map Tab**
- Visual map view of detections
- Color-coded threat levels

### 🎯 Threat Detection Types
- **Gun Shot** (CRITICAL priority)
- **Human Voices** (HIGH priority)
- **Engine Idling** (MEDIUM priority)
- **Dog Bark** (LOW priority)

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Testing

1. Go to **Live Monitoring** screen
2. Tap **"Simulate Alert"** button
3. Choose a threat type to test
4. View detections in all three tabs

## Project Structure

```
lib/
├── main.dart                   # App entry point
├── models/threat_detection.dart
├── providers/
│   ├── detection_provider.dart
│   └── location_provider.dart
├── screens/
│   ├── home_screen.dart
│   └── monitoring_screen.dart
└── widgets/
    ├── alerts_tab.dart
    ├── activity_tab.dart
    └── map_tab.dart
```

## Next Steps

- Integrate TFLite model for audio processing
- Add backend API for real-time alerts
- Connect to Raspberry Pi detection system
- Implement offline sync with local database

© 2024 EcoSight - Protecting Wildlife Through Technology
