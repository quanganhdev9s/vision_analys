# Vision Analysis Test

This module performs image suitability validation only. It does not perform palmistry, face reading, personality inference, health inference, or AI interpretation.

## Architecture

`VisionTestPage` sends a picked/captured static image to `VisionAnalysisBloc`. The bloc calls the domain repository, which uses the type-safe Pigeon `NativeVisionApi`. Native code returns primitive DTOs; the repository maps them to `PalmValidationResult` or `FaceValidationResult` for the UI.

## Dependencies

- Flutter: `flutter_bloc`, `image_picker`, `pigeon`
- Android: Google ML Kit Face Detection, MediaPipe Tasks Vision
- iOS: Apple Vision framework (face rectangles and human hand pose); this avoids a bundled third-party model for the iOS test build.

## Setup and run

Run `flutter pub get`, then `flutter run` with an Android device or an iOS device/simulator. Camera access needs a physical device; gallery works where the platform supports it.

Android palm detection packages the official MediaPipe model at `android/app/src/main/assets/mediapipe/hand_landmarker.task`. The model is deliberately not faked or replaced with heuristic output. Face analysis remains usable.

If `pigeons/vision_api.dart` changes, regenerate bindings with `dart run pigeon --input pigeons/vision_api.dart`.

## Current test thresholds

Thresholds live only in `VisionValidationConfig`: hand coverage 12%, face coverage 10%, edge margin 4%, max yaw 20°, max roll 15°, Laplacian variance minimum 65, brightness range 55–215. **TODO: tune using a real-world dataset before production.**

## Limitations and production TODOs

- iOS Vision rectangle detection does not expose reliable Euler yaw/roll/pitch, so no pose heuristic is fabricated there.
- Android face bounds should be validated across a representative set of EXIF-rotated images before production.
- Add and version the MediaPipe task model, warm up the hand landmarker, and add native integration tests.
- This is static-image analysis only; no camera stream, backend upload, or AI inference is included.
