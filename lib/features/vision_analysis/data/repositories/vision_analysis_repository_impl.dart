import '../../domain/entities/face_validation_result.dart';
import '../../domain/entities/hand_surface.dart';
import '../../domain/entities/palm_validation_result.dart';
import '../../domain/entities/vision_analysis_type.dart';
import '../../domain/entities/vision_validation_config.dart';
import '../../domain/entities/vision_validation_issue.dart';
import '../../domain/entities/vision_validation_result.dart';
import '../../domain/repositories/vision_analysis_repository.dart';
import '../datasources/generated/vision_api.g.dart';
import '../datasources/vision_native_data_source.dart';

class VisionAnalysisRepositoryImpl implements VisionAnalysisRepository {
  VisionAnalysisRepositoryImpl({
    required this._dataSource,
    this.config = const VisionValidationConfig(),
  });

  final VisionNativeDataSource _dataSource;
  final VisionValidationConfig config;

  @override
  Future<VisionValidationResult> analyze({
    required VisionAnalysisType type,
    required String imagePath,
  }) async {
    final result = switch (type) {
      VisionAnalysisType.palm => await _dataSource.analyzePalm(
        imagePath,
        config,
      ),
      VisionAnalysisType.face => await _dataSource.analyzeFace(
        imagePath,
        config,
      ),
    };
    return _map(type, result);
  }

  VisionValidationResult _map(
    VisionAnalysisType type,
    NativeVisionResult native,
  ) {
    final issues = native.issues.map(VisionValidationIssue.fromNative).toList();
    return switch (type) {
      VisionAnalysisType.palm => PalmValidationResult(
        handDetected: native.objectDetected,
        handCount: native.objectCount,
        allRequiredLandmarksVisible: native.insideFrame,
        handInsideFrame: native.insideFrame,
        sufficientCoverage: native.sufficientCoverage,
        imageSharpEnough: native.sharpEnough,
        lightingAcceptable: native.lightingAcceptable,
        handedness: native.handedness,
        handSurface: HandSurface.fromNative(native.handSurface),
        handCoverage: native.coverage,
        blurScore: native.blurScore,
        brightnessScore: native.brightnessScore,
        issues: issues,
      ),
      VisionAnalysisType.face => FaceValidationResult(
        faceDetected: native.objectDetected,
        faceCount: native.objectCount,
        faceInsideFrame: native.insideFrame,
        facingForward:
            (native.yaw?.abs() ?? 0) <= config.maxFaceYaw &&
            (native.roll?.abs() ?? 0) <= config.maxFaceRoll,
        sufficientCoverage: native.sufficientCoverage,
        imageSharpEnough: native.sharpEnough,
        lightingAcceptable: native.lightingAcceptable,
        yaw: native.yaw,
        roll: native.roll,
        pitch: native.pitch,
        faceCoverage: native.coverage,
        blurScore: native.blurScore,
        brightnessScore: native.brightnessScore,
        issues: issues,
      ),
    };
  }
}
