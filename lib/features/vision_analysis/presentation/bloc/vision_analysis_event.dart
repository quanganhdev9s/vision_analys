import '../../domain/entities/vision_analysis_type.dart';

sealed class VisionAnalysisEvent {
  const VisionAnalysisEvent();
}

class VisionImageSelected extends VisionAnalysisEvent {
  const VisionImageSelected(this.imagePath);
  final String imagePath;
}

class VisionImageCaptured extends VisionAnalysisEvent {
  const VisionImageCaptured(this.imagePath);
  final String imagePath;
}

class VisionAnalysisRequested extends VisionAnalysisEvent {
  const VisionAnalysisRequested();
}

class VisionAnalysisReset extends VisionAnalysisEvent {
  const VisionAnalysisReset();
}

class VisionAnalysisTypeChanged extends VisionAnalysisEvent {
  const VisionAnalysisTypeChanged(this.type);
  final VisionAnalysisType type;
}
