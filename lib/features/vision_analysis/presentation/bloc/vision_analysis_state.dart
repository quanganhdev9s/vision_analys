import '../../domain/entities/vision_analysis_type.dart';
import '../../domain/entities/vision_validation_result.dart';

sealed class VisionAnalysisState {
  const VisionAnalysisState({required this.type, this.imagePath});
  final VisionAnalysisType type;
  final String? imagePath;
}

class VisionAnalysisInitial extends VisionAnalysisState {
  const VisionAnalysisInitial({super.type = VisionAnalysisType.palm});
}

class VisionAnalysisLoading extends VisionAnalysisState {
  const VisionAnalysisLoading({required super.type, required super.imagePath});
}

class VisionAnalysisSuccess extends VisionAnalysisState {
  const VisionAnalysisSuccess({
    required super.type,
    required super.imagePath,
    required this.result,
  });
  final VisionValidationResult result;
}

class VisionAnalysisFailure extends VisionAnalysisState {
  const VisionAnalysisFailure({
    required super.type,
    required super.imagePath,
    required this.message,
  });
  final String message;
}
