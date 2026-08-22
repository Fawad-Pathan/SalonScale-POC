# SalonScale Inventory Scanner PoC

A Flutter proof of concept for continuously scanning product inventory with the camera, using OpenAI vision to read real product labels, auto-saving detected counts, and asking inventory questions through a text assistant.

## Features

- Anonymous Firebase Authentication when Firebase is configured, with local demo fallback.
- Full-screen camera scanner with permission handling and automatic periodic capture.
- Real OpenAI vision recognition for camera frames when configured.
- Mock image recognition that runs without API keys and avoids fake inventory rows.
- Configurable server AI provider behind `ProductRecognitionService`.
- Product Catalogue for scanner-ready products, reference images, SKU/barcode metadata, readiness status, and local add/edit/archive workflows.
- Apple-inspired scanner UI with restrained full-screen overlay and translucent controls.
- Strict JSON parsing, optional catalogue matching, and generic-object filtering after AI analysis.
- Multi-product quantity grouping for repeated visible items.
- Editable scan result cards for names, quantities, and catalogue matches.
- Local mock persistence with `shared_preferences`; Firestore/Storage repository when Firebase initializes.
- Scan history, scan details, inventory summary, and mock assistant chat.
- Product search, brand/category/status filters, product detail pages, and reference-image galleries.
- Sanitized product catalogue in `assets/data/products.json`.

## Stack

- Flutter and Dart
- Riverpod state management
- Firebase Auth, Cloud Firestore, Firebase Storage
- OpenAI Responses API vision analysis or a configurable HTTP AI endpoint
- Mock assistant answers for offline testing
- Mock services for offline testing

## Architecture

The app follows a feature-based structure under `lib/features`. AI analysis, inventory persistence, assistant answers, and catalogue loading are behind interfaces so the PoC can run locally and later switch to Firebase or server-controlled production services.

```text
lib/
  app/
  core/
  features/
    auth/
    catalogue/
    scanning/
    history/
    inventory/
    assistant/
assets/data/products.json
docs/
test/
tool/
```

## Complete Windows Setup and Run Guide

This app is currently developed and tested on Windows with Android Studio, a Pixel 7 Pro Android emulator, Flutter, Firebase optional services, and OpenAI vision recognition.

### 1. Install the tools

Install these first:

- [Git for Windows](https://git-scm.com/downloads/win)
- [Flutter SDK](https://docs.flutter.dev/install)
- [Add Flutter to PATH](https://docs.flutter.dev/install/add-to-path), or install Flutter in `C:\Users\<your-user>\flutter`
- [Android Studio](https://developer.android.com/studio)
- [Android Studio install guide](https://developer.android.com/studio/install)
- [Flutter Android setup guide](https://docs.flutter.dev/platform-integration/android/setup)
- [Android Emulator guide](https://developer.android.com/studio/run/emulator)
- [Android Virtual Device guide](https://developer.android.com/studio/run/managing-avds)
- [OpenAI API key page](https://platform.openai.com/api-keys)
- [OpenAI API quickstart](https://developers.openai.com/api/docs/quickstart)
- Optional: [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- Optional: [Firebase CLI](https://firebase.google.com/docs/cli)

Flutter includes Dart, so a separate Dart install usually is not needed.

### 2. Match the current Windows setup

The development machine for this PoC is set up like this:

```text
Flutter executable: C:\Users\<your-user>\flutter\bin\flutter.bat
Android SDK:        %LOCALAPPDATA%\Android\Sdk
Emulator name:      Pixel_7_Pro
Device id:          emulator-5554
App package:        com.example.salonscale_poc
```

If your Flutter SDK is somewhere else, either add Flutter to PATH or pass the full path to the launcher script with `-Flutter`.

### 3. Clone the repository

```powershell
git clone https://github.com/Fawad-Pathan/SalonScale-POC.git
cd SalonScale-POC
```

If you already have the repo, update it:

```powershell
git pull origin main
```

### 4. Verify Flutter and Android

If Flutter is on PATH:

```powershell
flutter doctor
flutter doctor --android-licenses
flutter devices
```

If Flutter is installed like the current development machine:

```powershell
$flutter = "$env:USERPROFILE\flutter\bin\flutter.bat"
& $flutter doctor
& $flutter doctor --android-licenses
& $flutter devices
```

Fix anything important that `flutter doctor` reports before running the app.

### 5. Install project dependencies

```powershell
flutter pub get
```

Or, with the explicit Flutter path:

```powershell
& "$env:USERPROFILE\flutter\bin\flutter.bat" pub get
```

### 6. Create an Android emulator

In Android Studio:

1. Open `Device Manager`.
2. Create a virtual device.
3. Use a Pixel device profile, such as Pixel 7 Pro.
4. Use a Google Play Android system image.
5. Name it `Pixel_7_Pro` if you want the commands below to match exactly.

Start it from PowerShell:

```powershell
flutter emulators
flutter emulators --launch Pixel_7_Pro
flutter devices
```

Once it boots, `flutter devices` should show an Android device id like `emulator-5554`.

### 7. Configure OpenAI scanning

Create a local `.env` file:

```powershell
copy .env.example .env
notepad .env
```

Paste your own OpenAI key into `.env`:

```text
AI_API_KEY=sk-your-key-here
AI_PROVIDER=openai
AI_MODEL=gpt-4.1-mini
AI_ENDPOINT=
USE_MOCK_AI=false
DEMO_SALON_ID=demo_salon
```

Do not commit `.env`. It is ignored by Git on purpose.

### 8. Run the app with real OpenAI scanning

Recommended PowerShell command:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_openai.ps1 -DeviceId emulator-5554
```

If Flutter is not on PATH and not installed at `C:\Users\<your-user>\flutter`, pass the Flutter path:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_openai.ps1 -DeviceId emulator-5554 -Flutter "C:\path\to\flutter\bin\flutter.bat"
```

You can also run it directly with Dart defines:

```powershell
flutter run -d emulator-5554 --dart-define=USE_MOCK_AI=false --dart-define=AI_PROVIDER=openai --dart-define=AI_API_KEY=sk-your-key-here --dart-define=AI_MODEL=gpt-4.1-mini
```

Android Studio's green Run button can start the app, but it may not pass the local `.env` OpenAI values unless your run configuration includes the same Dart defines. If the scanner says `OpenAI key missing`, run it from PowerShell with `tool\run_openai.ps1`.

The scanner captures camera frames, sends them to the OpenAI Responses API as image input, requests strict JSON, filters out generic guesses, groups repeated visible products into quantities, and saves valid detections into inventory.

For production, do not ship a mobile app with a raw OpenAI API key. Use a server-controlled endpoint instead. Set `AI_PROVIDER=api`, `AI_ENDPOINT=https://your-server.example.com/analyze`, and `USE_MOCK_AI=false`.

### 9. Run without OpenAI

Mock mode launches the UI without an OpenAI key. It will not create fake product rows.

```powershell
copy .env.example .env
notepad .env
```

Set:

```text
USE_MOCK_AI=true
AI_API_KEY=
```

Then run:

```powershell
flutter run -d emulator-5554
```

### 10. Optional Firebase setup

The app can run locally without Firebase. To use Firebase-backed auth, Firestore, and Storage:

1. Create a Firebase project.
2. Enable Anonymous Authentication.
3. Create Cloud Firestore and Firebase Storage.
4. Install and log into the Firebase CLI.
5. Install FlutterFire CLI.
6. Configure the app.

Commands:

```powershell
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
flutter run -d emulator-5554
```

Keep Firebase credential files out of source control. This repo ignores `google-services.json` and `GoogleService-Info.plist`.

The repository already includes camera and internet permissions in `android/app/src/main/AndroidManifest.xml` and iOS permission text in `ios/Runner/Info.plist`. If you regenerate platform folders with `flutter create .`, copy those permission entries back in.

### 11. Clean build and common fixes

Use this when the app is stuck, the emulator disappears, or Android Studio gets confused:

```powershell
flutter clean
flutter pub get
flutter emulators --launch Pixel_7_Pro
flutter devices
powershell -ExecutionPolicy Bypass -File .\tool\run_openai.ps1 -DeviceId emulator-5554
```

If ADB breaks:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb kill-server
& $adb start-server
flutter devices
```

If the app is installed but you only want to relaunch it:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb -s emulator-5554 shell monkey -p com.example.salonscale_poc -c android.intent.category.LAUNCHER 1
```

### 12. Run checks before pushing

```powershell
dart format .
flutter analyze --no-pub lib test
flutter test
flutter build apk --debug
```

## Catalogue Upload

To seed Firestore with the sanitized catalogue:

```bash
npm install firebase-admin
gcloud auth application-default login
node tool/upload_catalogue.mjs demo_salon
```

No service account keys or credentials should be committed.

## Current Limitations

- Direct OpenAI calls are intended for local proof-of-concept testing only because a mobile app cannot keep an API key secret.
- The assistant chat stays in mock mode when `AI_PROVIDER=openai`; only product scanning uses OpenAI directly.
- Local mock persistence is single-device.
- Product image crops are placeholders.
- Voice input is a visual placeholder.
- Direct client-side OpenAI recognition captures periodic camera frames rather than streaming video.

## Future Improvements

- Add server-side request validation, rate limiting, audit logging, and prompt versioning.
- Add real product image crops or bounding boxes when the model returns regions.
- Add barcode support for low-confidence items.
- Add role-based salon users and multi-salon switching.
- Collect stylist feedback from live user testing and tune catalogue aliases.
