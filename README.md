# PrescribrApp

<div align="center">
  <img src="https://github.com/user-attachments/assets/de8caf04-60e9-4547-8c18-4c2bfc918968" alt="PrescribrApp Logo" width="150">
</div>

PrescribrApp is a comprehensive medication management application that helps users track their medications, set reminders, and receive guidance through an AI assistant. The app supports Android, iOS, and web platforms, providing a seamless cross-platform experience.

## Features

- **User Authentication**: Secure login/signup using Firebase Authentication
- **Medication Tracking**: Add, edit, and manage your medications
- **Smart Reminders**: Set customizable reminders with different frequencies
- **Zira AI Assistant**: Voice-enabled AI helper that can answer medical questions
- **Multi-platform**: Works on Android, iOS, and web browsers
- **Cross-device Sync**: Your data syncs across all your devices
- **Voice Interaction**: Full speech recognition and text-to-speech capabilities

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Authentication, Firestore, Cloud Functions)
- **AI Integration**: Anthropic Claude API
- **Voice**: flutter_tts and speech_to_text packages
- **State Management**: Provider pattern

## Installation

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart (2.17.0 or higher)
- Android Studio / VS Code
- Firebase CLI (for deployment)

### Setup Instructions

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/prescribrapp.git
   cd prescribrapp
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Configure Firebase
   - Create a new Firebase project
   - Add Android & iOS apps to your Firebase project
   - Download and place the google-services.json (Android) and GoogleService-Info.plist (iOS) files
   - Update firebase_options.dart if needed

4. Set up API Keys
   - Create a copy of lib/utils/api_keys.dart.example as lib/utils/api_keys.dart
   - Add your Anthropic API key to the file

5. Run the app
   ```bash
   flutter run
   ```

## Platform-Specific Notes

### Android
- Ensure Google Play Services is installed for proper speech recognition
- Grant microphone permissions for voice features

### iOS
- Additional setup for speech recognition required in Info.plist
- TTS functionality uses the native AVSpeechSynthesizer

### Web
- Limited speech recognition capabilities due to browser restrictions
- Requires HTTPS for microphone access

## Known Issues & Solutions

- **Firebase Authentication Navigation**: Fixed issues with navigation after login on Android
- **TTS on Android**: Implemented robust error handling and retry logic
- **Long Path Errors (Windows)**: May occur when building Windows app if project path is too long

## Screenshots

<div align="center">

### Login & Account Setup
<img src="https://github.com/user-attachments/assets/e2c6bd3e-e815-4cb7-aea8-dccd9ddb5b24" alt="Login Screen" width="250">

### Home Screen
<img src="https://github.com/user-attachments/assets/607bc242-ccce-4f3e-b76f-a683f72f0de4" alt="Home Screen" width="250">

### Add Medication
<img src="https://github.com/user-attachments/assets/b442c4a0-4806-4008-8706-4dbfa8ffa8d0" alt="Add Medication" width="250">


### My Medications
<img src="https://github.com/user-attachments/assets/c90a6292-06d3-4c41-acc6-1f1d12d1d89d" alt="My Medications" width="250">

### Medication Details
<img src="https://github.com/user-attachments/assets/3262f2a0-1ffb-4177-95ef-342b3b0ea40b" alt="Add Medication" width="250">

### Zira AI Assistant
<img src="https://github.com/user-attachments/assets/e3c7f7ce-7db3-45ba-99b4-1947fa4b893b" alt="Zira AI Assistant" width="250">
</div>

## Authors
- Shong Chan

## License
This project is licensed under the MIT License - see the LICENSE file for details.
