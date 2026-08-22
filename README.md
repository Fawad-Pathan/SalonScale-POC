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

## Setup

1. Install Flutter.
2. If native platform scaffolding is missing or incomplete, run:

```bash
flutter create --platforms=android,ios --project-name salonscale_poc .
```

3. From this project directory, run:

```bash
flutter pub get
cp .env.example .env
flutter run
```

Mock mode is enabled by default, so the app can launch without Firebase, OpenAI, or server credentials.

## Firebase Setup

1. Create a Firebase project.
2. Enable Anonymous Authentication.
3. Create Cloud Firestore and Firebase Storage.
4. Add Android and iOS apps in Firebase.
5. Place `google-services.json` and `GoogleService-Info.plist` in the platform folders, or pass Firebase options with `--dart-define`.
6. Keep all credential files out of source control.

The repository includes permission entries in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`. If you regenerate platform folders with `flutter create .`, copy those permission entries back in.

## AI Configuration

For local real scanning, create a `.env` file in the project root and paste your OpenAI key there:

```text
AI_API_KEY=sk-your-key
AI_PROVIDER=openai
AI_MODEL=gpt-4.1-mini
AI_ENDPOINT=
USE_MOCK_AI=false
DEMO_SALON_ID=demo_salon
```

Then use the local launcher:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_openai.ps1 -DeviceId emulator-5554
```

Android Studio's green Run button will start the app, but it will not pass the
local `.env` OpenAI key unless you manually add the same Dart defines to that
run configuration. If the scanner says `OpenAI key missing`, launch it with the
PowerShell command above.

You can also pass the same values with `--dart-define` when running the app:

```powershell
C:\Users\pfawa\flutter\bin\flutter.bat run -d emulator-5554 --dart-define=USE_MOCK_AI=false --dart-define=AI_PROVIDER=openai --dart-define=AI_API_KEY=sk-your-key --dart-define=AI_MODEL=gpt-4.1-mini
```

The scanner captures camera frames continuously, sends each frame to the OpenAI Responses API as a high-detail image input, asks for strict JSON, and auto-logs real detections into local/Firebase-backed inventory. The prompt prioritizes readable brand/product text and distinctive packaging, supports products outside the sample salon catalogue, and groups repeated visible items into a single product quantity.

For production, prefer a server-controlled endpoint over direct client-side model access. Set `AI_PROVIDER=api`, `AI_ENDPOINT=https://your-server.example.com/analyze`, and `USE_MOCK_AI=false`. The custom AI endpoint should accept multipart form data with `image`, `prompt`, `catalogue`, and `responseFormat=json`, then return valid JSON using the schema described in the code and docs.

## Mock Mode

Leave `USE_MOCK_AI=true` or omit AI credentials to run without OpenAI. Mock mode does not create pretend product detections; it keeps scanning empty so the inventory is not polluted. The assistant answers common inventory questions from saved local data.

## Running Tests

```bash
dart format .
flutter analyze
flutter test
```

The current workstation did not have Flutter or Dart installed, so these commands could not be executed here.

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
