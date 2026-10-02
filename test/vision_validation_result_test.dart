import 'package:flutter_test/flutter_test.dart';
import 'package:vision_analyze/features/vision_analysis/domain/entities/palm_validation_result.dart';
import 'package:vision_analyze/features/vision_analysis/domain/entities/vision_validation_issue.dart';

PalmValidationResult palm({
  bool detected = true,
  int count = 1,
  bool inside = true,
  bool coverage = true,
  bool sharp = true,
  bool light = true,
  List<VisionValidationIssue> issues = const [],
}) => PalmValidationResult(
  handDetected: detected,
  handCount: count,
  allRequiredLandmarksVisible: inside,
  handInsideFrame: inside,
  sufficientCoverage: coverage,
  imageSharpEnough: sharp,
  lightingAcceptable: light,
  handedness: 'Left',
  handCoverage: .4,
  blurScore: 120,
  brightnessScore: 140,
  issues: issues,
);

void main() {
  test(
    'single hand with good quality is valid',
    () => expect(palm().isValid, isTrue),
  );
  test(
    'no hand is invalid',
    () => expect(
      palm(
        detected: false,
        count: 0,
        issues: [VisionValidationIssue.noHand],
      ).isValid,
      isFalse,
    ),
  );
  test(
    'multiple hands is invalid',
    () => expect(
      palm(count: 2, issues: [VisionValidationIssue.multipleHands]).isValid,
      isFalse,
    ),
  );
  test(
    'small hand is invalid',
    () => expect(
      palm(
        coverage: false,
        issues: [VisionValidationIssue.handTooSmall],
      ).isValid,
      isFalse,
    ),
  );
  test(
    'blurry image is invalid',
    () => expect(
      palm(sharp: false, issues: [VisionValidationIssue.imageBlurry]).isValid,
      isFalse,
    ),
  );
  test(
    'native issue maps to user text',
    () => expect(
      VisionValidationIssue.fromNative('HAND_TOO_FAR').message,
      contains('closer'),
    ),
  );
}
