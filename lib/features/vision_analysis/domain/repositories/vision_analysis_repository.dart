import '../entities/vision_analysis_type.dart';
import '../entities/vision_validation_result.dart';

abstract class VisionAnalysisRepository {
  Future<VisionValidationResult> analyze({
    required VisionAnalysisType type,
    required String imagePath,
  });
}
