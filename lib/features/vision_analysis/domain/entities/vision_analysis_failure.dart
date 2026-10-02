enum VisionAnalysisFailureType {
  unsupportedImage,
  nativeProcessingFailed,
  invalidImage,
  modelInitializationFailed,
  permissionDenied,
}

class VisionAnalysisException implements Exception {
  const VisionAnalysisException(this.type, this.message);

  final VisionAnalysisFailureType type;
  final String message;
}
