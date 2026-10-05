import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/vision_analysis_failure.dart';
import '../../domain/entities/vision_validation_config.dart';
import 'generated/vision_api.g.dart';

class VisionNativeDataSource {
  VisionNativeDataSource({NativeVisionApi? api})
    : _api = api ?? NativeVisionApi();

  final NativeVisionApi _api;

  Future<NativeVisionResult> analyzePalm(
    String imagePath,
    VisionValidationConfig config,
  ) => _run('Palm', () => _api.analyzePalm(imagePath, _toNativeConfig(config)));

  Future<NativeVisionResult> analyzeFace(
    String imagePath,
    VisionValidationConfig config,
  ) => _run('Face', () => _api.analyzeFace(imagePath, _toNativeConfig(config)));

  Future<NativeVisionResult> _run(
    String type,
    Future<NativeVisionResult> Function() action,
  ) async {
    try {
      final result = await action();
      if (kDebugMode) {
        debugPrint(
          '[VisionAnalysis][Flutter][r4] type=$type '
          'detected=${result.objectDetected} count=${result.objectCount} '
          'inside=${result.insideFrame} coverage=${result.coverage} '
          'blur=${result.blurScore} brightness=${result.brightnessScore} '
          'issues=${result.issues}',
        );
      }
      return result;
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        '[VisionAnalysis] type=$type native error=${error.code}: ${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      final failure = error.code == 'MODEL_NOT_AVAILABLE'
          ? VisionAnalysisFailureType.modelInitializationFailed
          : VisionAnalysisFailureType.nativeProcessingFailed;
      throw VisionAnalysisException(failure, _friendlyMessage(error.code));
    }
  }

  NativeVisionConfig _toNativeConfig(VisionValidationConfig config) =>
      NativeVisionConfig(
        minHandCoverage: config.minHandCoverage,
        minFaceCoverage: config.minFaceCoverage,
        edgeMargin: config.edgeMargin,
        maxFaceYaw: config.maxFaceYaw,
        maxFaceRoll: config.maxFaceRoll,
        minBlurScore: config.minBlurScore,
        minBrightness: config.minBrightness,
        maxBrightness: config.maxBrightness,
      );

  String _friendlyMessage(String code) => switch (code) {
    'MODEL_NOT_AVAILABLE' =>
      'The hand detection model is not installed on this build.',
    'UNSUPPORTED_IMAGE' => 'This image format cannot be analyzed.',
    'VISION_INFERENCE_CONTEXT' =>
      'Face detection is unavailable in this iOS environment. Try on a physical iPhone.',
    _ => 'Native vision processing failed. Please try another image.',
  };
}
