# Firebase Configuration Instructions

This Flutter application uses Firebase for authentication and data storage. Follow these steps to configure Firebase for your project.

## Prerequisites

1. Flutter SDK installed
2. Firebase CLI installed (`npm install -g firebase-tools`)
3. A Firebase project created at [Firebase Console](https://console.firebase.google.com)

## Step 1: Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

## Step 2: Configure Firebase for your platforms

Run the following command in your project root:

```bash
flutterfire configure
```

This will:
- Connect your Flutter app to your Firebase project
- Generate the necessary configuration files
- Update `firebase_options.dart` with your project settings

## Step 3: Platform-specific setup

### Android
1. The `google-services.json` file will be automatically added to `android/app/`
2. Make sure your `android/app/build.gradle` has:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```
3. And your `android/build.gradle` has:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.3.15'
   }
   ```

### iOS
1. The `GoogleService-Info.plist` will be automatically added to your iOS project
2. Open `ios/Runner.xcworkspace` in Xcode
3. Drag the `GoogleService-Info.plist` into the Runner folder
4. Make sure to select "Copy items if needed"

### Web
1. Add the Firebase SDK scripts to `web/index.html` before the main.dart.js script:
   ```html
   <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
   <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
   <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-firestore-compat.js"></script>
   <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-storage-compat.js"></script>
   ```

## Step 4: Enable Authentication Methods

1. Go to your [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to Authentication > Sign-in method
4. Enable "Email/Password" authentication

## Step 5: Create Firestore Database

1. In Firebase Console, go to Firestore Database
2. Click "Create database"
3. Choose "Start in test mode" for development
4. Select your preferred location

## Step 6: Set up Firestore Security Rules

For production, update your Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own documents
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read all persons
    match /persons/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.role == 'admin';
    }
    
    // Other collections...
  }
}
```

## Step 7: Run the app

```bash
flutter pub get
flutter run
```

## Features Implemented

1. **User Registration**: Create new accounts with email, password, name, and optional phone number
2. **User Login**: Sign in with email and password
3. **Password Reset**: Send password reset emails
4. **Biometric Authentication**: Use device biometrics for quick login (after first login)
5. **Remember Me**: Save user credentials for easier login
6. **Firebase Integration**: Complete authentication flow with Firestore user profiles

## Troubleshooting

### Common Issues:

1. **"No Firebase App has been created"**
   - Make sure you've run `flutterfire configure`
   - Check that `firebase_options.dart` is properly imported in `main.dart`

2. **Authentication not working**
   - Verify Email/Password auth is enabled in Firebase Console
   - Check your internet connection
   - Ensure Firebase project is active

3. **Firestore permission denied**
   - Update your security rules
   - Make sure user is authenticated before accessing data

## Next Steps

1. Implement role-based access control
2. Add user profile management
3. Implement the accident management features
4. Add push notifications for emergency alerts
5. Implement offline data persistence

For more information, visit the [FlutterFire documentation](https://firebase.flutter.dev/).
