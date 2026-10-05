import 'vision_validation_issue.dart';
import 'vision_validation_result.dart';
import 'hand_surface.dart';

class PalmValidationResult extends VisionValidationResult {
  PalmValidationResult({
    required this.handDetected,
    required this.handCount,
    required this.allRequiredLandmarksVisible,
    required this.handInsideFrame,
    required this.sufficientCoverage,
    required this.imageSharpEnough,
    required this.lightingAcceptable,
    required this.handedness,
    this.handSurface = HandSurface.unknown,
    required this.handCoverage,
    required this.blurScore,
    required this.brightnessScore,
    required this.issues,
  });

  final bool handDetected;
  final int handCount;
  final bool allRequiredLandmarksVisible;
  final bool handInsideFrame;
  final bool sufficientCoverage;
  final bool imageSharpEnough;
  final bool lightingAcceptable;
  final String? handedness;
  final HandSurface handSurface;
  final double? handCoverage;
  @override
  final double? blurScore;
  @override
  final double? brightnessScore;
  @override
  final List<VisionValidationIssue> issues;

  @override
  double? get coverage => handCoverage;

  @override
  bool get isValid =>
      handDetected &&
      handCount == 1 &&
      allRequiredLandmarksVisible &&
      handInsideFrame &&
      sufficientCoverage &&
      imageSharpEnough &&
      lightingAcceptable &&
      issues.isEmpty;
}
