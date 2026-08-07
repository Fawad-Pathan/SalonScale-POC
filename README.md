# SalonScale Inventory Scanner PoC

A Flutter proof of concept for scanning salon backbar inventory from a still image, reviewing AI-detected products, saving confirmed results, and asking inventory questions through a text assistant.

## Features

- Anonymous Firebase Authentication when Firebase is configured, with local demo fallback.
- Camera and gallery image selection with permission handling.
- Real OpenAI vision recognition for camera captures when configured.
- Mock image recognition that works without API keys or paid services.
- Configurable server AI provider behind `ProductRecognitionService`.
- Product Catalogue for scanner-ready products, reference images, SKU/barcode metadata, readiness status, and local add/edit/archive workflows.
- Live scanner detection markers and bottom product cards with saved reference images, current camera crop preview, quantity adjustment, and match correction.
- Strict JSON parsing and local catalogue matching after AI analysis.
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

For local real scanning, pass the OpenAI key with `--dart-define` when running the app:

```powershell
C:\Users\pfawa\flutter\bin\flutter.bat run -d emulator-5554 --dart-define=USE_MOCK_AI=false --dart-define=AI_PROVIDER=openai --dart-define=AI_API_KEY=sk-your-key --dart-define=AI_MODEL=gpt-4.1-mini
```

Or, after setting `.env`, use the local launcher:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_openai.ps1 -DeviceId emulator-5554
```

The scanner captures a camera frame, sends it to the OpenAI Responses API as an image input, asks for strict JSON, matches the output against `assets/data/products.json`, and then shows editable rows. Tap **Save** on the review screen to log the scan into local/Firebase-backed inventory.

You can also keep equivalent values in `.env.example` as a reference:

```text
AI_API_KEY=sk-your-key
AI_PROVIDER=openai
AI_MODEL=gpt-4.1-mini
AI_ENDPOINT=
USE_MOCK_AI=false
DEMO_SALON_ID=demo_salon
```

For production, prefer a server-controlled endpoint over direct client-side model access. Set `AI_PROVIDER=api`, `AI_ENDPOINT=https://your-server.example.com/analyze`, and `USE_MOCK_AI=false`. The custom AI endpoint should accept multipart form data with `image`, `prompt`, `catalogue`, and `responseFormat=json`, then return valid JSON using the schema described in the code and docs.

## Mock Mode

Leave `USE_MOCK_AI=true` or omit AI credentials. The scanner returns realistic sample detections and the assistant answers common inventory questions from saved local data.

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
- Continuous video recognition and live overlays are intentionally out of scope for the MVP.

## Future Improvements

- Add server-side request validation, rate limiting, audit logging, and prompt versioning.
- Add real product image crops or bounding boxes when the model returns regions.
- Add barcode support for low-confidence items.
- Add role-based salon users and multi-salon switching.
- Collect stylist feedback from live user testing and tune catalogue aliases.
