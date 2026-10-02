import 'vision_validation_issue.dart';

abstract class VisionValidationResult {
  bool get isValid;
  List<VisionValidationIssue> get issues;
  double? get coverage;
  double? get blurScore;
  double? get brightnessScore;
}
