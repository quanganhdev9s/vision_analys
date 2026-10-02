import 'vision_validation_issue.dart';
import 'vision_validation_result.dart';

class FaceValidationResult extends VisionValidationResult {
  FaceValidationResult({
    required this.faceDetected,
    required this.faceCount,
    required this.faceInsideFrame,
    required this.facingForward,
    required this.sufficientCoverage,
    required this.imageSharpEnough,
    required this.lightingAcceptable,
    required this.yaw,
    required this.roll,
    required this.pitch,
    required this.faceCoverage,
    required this.blurScore,
    required this.brightnessScore,
    required this.issues,
  });

  final bool faceDetected;
  final int faceCount;
  final bool faceInsideFrame;
  final bool facingForward;
  final bool sufficientCoverage;
  final bool imageSharpEnough;
  final bool lightingAcceptable;
  final double? yaw;
  final double? roll;
  final double? pitch;
  final double? faceCoverage;
  @override
  final double? blurScore;
  @override
  final double? brightnessScore;
  @override
  final List<VisionValidationIssue> issues;

  @override
  double? get coverage => faceCoverage;

  @override
  bool get isValid =>
      faceDetected &&
      faceCount == 1 &&
      faceInsideFrame &&
      facingForward &&
      sufficientCoverage &&
      imageSharpEnough &&
      lightingAcceptable &&
      issues.isEmpty;
}
