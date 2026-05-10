# BMoris - Bahasa Melayu Speech Assistant

BMoris is an AI-powered mobile application designed to help users learn and improve their Bahasa Melayu pronunciation, grammar, and speaking confidence.

## Features

### User Features
- User Registration & Login
- Pronunciation Practice with real-time feedback
- AI Chatbot for conversation practice
- Interactive Lessons with vocabulary
- Adaptive Quiz System
- Translation (Malay-English)
- Gamification (XP, Streaks, Badges)
- Leaderboard
- Offline Lessons
- Pronunciation History Tracking
- Send Feedback

### Admin Features
- Admin Dashboard with Analytics
- User Management
- Content Management (Lessons, Quizzes)
- Feedback Review
- Announcements

## Installation

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Android Studio or VS Code
- Firebase Account

### Setup Steps

1. Clone the repository
```bash
git clone <repository-url>
cd bmoris
```

2. Install dependencies
```bash
flutter pub get
```

3. Firebase Setup

   a. Go to Firebase Console (https://console.firebase.google.com)

   b. Create a new project or use existing "bmoris-55fdb"

   c. Enable Authentication:
      - Go to Authentication > Sign-in method
      - Enable Email/Password

   d. Enable Firestore:
      - Go to Firestore Database
      - Create database in production mode
      - Set up security rules (see below)

   e. Download google-services.json and place it in:
      - `android/app/google-services.json`

4. Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    match /lessons/{lessonId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    match /quizzes/{quizId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    match /pronunciation_attempts/{attemptId} {
      allow read, write: if request.auth != null;
    }
    match /quiz_attempts/{attemptId} {
      allow read, write: if request.auth != null;
    }
    match /feedback/{feedbackId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    match /announcements/{announcementId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

5. Run the app
```bash
flutter run
```

## Notifications Behavior

- The in-app Notifications page reads Firestore `announcements`
- Creating a new active announcement should:
  - create the inbox item in Firestore
  - appear on Home under `Latest Announcements`
  - appear on the Notifications page
- Editing an announcement updates the in-app announcement content

## Creating Admin Account

To create an admin account, register normally then update the user document in Firestore:

1. Register a new account through the app
2. Go to Firebase Console > Firestore
3. Find the user document in the `users` collection
4. Change the `role` field from `user` to `admin`

## Adding Sample Lessons

Add lessons to Firestore with this structure:

```json
{
  "title": "Greetings",
  "titleMalay": "Ucapan",
  "description": "Learn common Malay greetings",
  "difficulty": 1,
  "category": "Basics",
  "xpReward": 10,
  "isOfflineAvailable": true,
  "createdAt": "2025-01-01T00:00:00.000Z",
  "contents": [
    {
      "type": "text",
      "malay": "Selamat pagi",
      "english": "Good morning",
      "phonemes": ["se", "la", "mat", "pa", "gi"]
    }
  ]
}
```

## Project Structure

```
lib/
├── main.dart
├── models/
│   ├── user_model.dart
│   ├── lesson_model.dart
│   ├── quiz_model.dart
│   ├── pronunciation_model.dart
│   ├── feedback_model.dart
│   └── announcement_model.dart
├── providers/
│   ├── auth_provider.dart
│   ├── lesson_provider.dart
│   └── quiz_provider.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── speech_service.dart
│   ├── ai_service.dart
│   └── offline_service.dart
├── screen/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   ├── pronunciation_screen.dart
│   ├── chatbot_screen.dart
│   ├── lesson_screen.dart
│   ├── quiz_screen.dart
│   ├── leaderboard_screen.dart
│   ├── offline_lessons_screen.dart
│   ├── translation_screen.dart
│   ├── feedback_screen.dart
│   ├── pronunciation_history_screen.dart
│   └── admin/
│       ├── admin_login_screen.dart
│       └── admin_dashboard_screen.dart
└── widgets/
```

## Tech Stack

- Flutter/Dart (Frontend)
- Firebase Authentication (User Auth)
- Cloud Firestore (Database)
- Firebase Storage (File Storage)
- Speech-to-Text (Pronunciation)
- Flutter TTS (Text-to-Speech)

## Permissions Required

Android (android/app/src/main/AndroidManifest.xml):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

## Building for Production

```bash
flutter build apk --release
```

The APK will be in `build/app/outputs/flutter-apk/app-release.apk`

## Troubleshooting

1. If speech recognition doesn't work:
   - Ensure microphone permission is granted
   - Check device supports speech recognition

2. If Firebase errors occur:
   - Verify google-services.json is in correct location
   - Check Firebase project configuration

3. If build fails:
   - Run `flutter clean` then `flutter pub get`
