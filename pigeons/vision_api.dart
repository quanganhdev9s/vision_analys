import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut:
        'lib/features/vision_analysis/data/datasources/generated/vision_api.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/example/vision_analyze/vision/generated/VisionApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.example.vision_analyze.vision.generated',
    ),
    swiftOut: 'ios/Runner/Vision/Generated/VisionApi.g.swift',
  ),
)
// ignore: unused_element
class _VisionApiConfiguration {}

class NativeVisionResult {
  NativeVisionResult({
    required this.objectDetected,
    required this.objectCount,
    required this.insideFrame,
    required this.sufficientCoverage,
    required this.sharpEnough,
    required this.lightingAcceptable,
    required this.coverage,
    required this.blurScore,
    required this.brightnessScore,
    required this.issues,
    this.handedness,
    this.yaw,
    this.roll,
    this.pitch,
  });

  bool objectDetected;
  int objectCount;
  bool insideFrame;
  bool sufficientCoverage;
  bool sharpEnough;
  bool lightingAcceptable;
  double coverage;
  double blurScore;
  double brightnessScore;
  List<String> issues;
  String? handedness;
  double? yaw;
  double? roll;
  double? pitch;
}

class NativeVisionConfig {
  NativeVisionConfig({
    required this.minHandCoverage,
    required this.minFaceCoverage,
    required this.edgeMargin,
    required this.maxFaceYaw,
    required this.maxFaceRoll,
    required this.minBlurScore,
    required this.minBrightness,
    required this.maxBrightness,
  });

  double minHandCoverage;
  double minFaceCoverage;
  double edgeMargin;
  double maxFaceYaw;
  double maxFaceRoll;
  double minBlurScore;
  double minBrightness;
  double maxBrightness;
}

@HostApi()
abstract class NativeVisionApi {
  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  NativeVisionResult analyzePalm(String imagePath, NativeVisionConfig config);

  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  NativeVisionResult analyzeFace(String imagePath, NativeVisionConfig config);
}
