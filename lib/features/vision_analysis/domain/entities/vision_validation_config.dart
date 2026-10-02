class VisionValidationConfig {
  const VisionValidationConfig({
    this.minHandCoverage = 0.12,
    this.minFaceCoverage = 0.10,
    this.edgeMargin = 0.04,
    this.maxFaceYaw = 20,
    this.maxFaceRoll = 15,
    this.minBlurScore = 65,
    this.minBrightness = 55,
    this.maxBrightness = 215,
  });

  // TODO: Tune using a real-world dataset before production.
  final double minHandCoverage;
  final double minFaceCoverage;
  final double edgeMargin;
  final double maxFaceYaw;
  final double maxFaceRoll;
  final double minBlurScore;
  final double minBrightness;
  final double maxBrightness;
}
