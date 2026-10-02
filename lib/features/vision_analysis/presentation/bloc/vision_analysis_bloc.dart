import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vision_analysis_failure.dart';
import '../../domain/entities/vision_analysis_type.dart';
import '../../domain/repositories/vision_analysis_repository.dart';
import 'vision_analysis_event.dart';
import 'vision_analysis_state.dart';

class VisionAnalysisBloc
    extends Bloc<VisionAnalysisEvent, VisionAnalysisState> {
  VisionAnalysisBloc(this._repository) : super(const VisionAnalysisInitial()) {
    on<VisionImageSelected>(_onImageSelected);
    on<VisionImageCaptured>(_onImageCaptured);
    on<VisionAnalysisRequested>(_onAnalyze);
    on<VisionAnalysisReset>(_onReset);
    on<VisionAnalysisTypeChanged>(_onTypeChanged);
  }

  final VisionAnalysisRepository _repository;

  Future<void> _onImageSelected(
    VisionImageSelected event,
    Emitter<VisionAnalysisState> emit,
  ) => _analyze(event.imagePath, emit);

  Future<void> _onImageCaptured(
    VisionImageCaptured event,
    Emitter<VisionAnalysisState> emit,
  ) => _analyze(event.imagePath, emit);

  Future<void> _onAnalyze(
    VisionAnalysisRequested event,
    Emitter<VisionAnalysisState> emit,
  ) async {
    final imagePath = state.imagePath;
    if (imagePath != null) await _analyze(imagePath, emit);
  }

  void _onReset(VisionAnalysisReset event, Emitter<VisionAnalysisState> emit) {
    emit(VisionAnalysisInitial(type: state.type));
  }

  Future<void> _onTypeChanged(
    VisionAnalysisTypeChanged event,
    Emitter<VisionAnalysisState> emit,
  ) async {
    final imagePath = state.imagePath;
    if (imagePath == null) {
      emit(VisionAnalysisInitial(type: event.type));
      return;
    }
    await _analyze(imagePath, emit, type: event.type);
  }

  Future<void> _analyze(
    String imagePath,
    Emitter<VisionAnalysisState> emit, {
    VisionAnalysisType? type,
  }) async {
    final analysisType = type ?? state.type;
    emit(VisionAnalysisLoading(type: analysisType, imagePath: imagePath));
    try {
      final result = await _repository.analyze(
        type: analysisType,
        imagePath: imagePath,
      );
      debugPrint(
        '[VisionAnalysis] type=$analysisType result=${result.isValid}',
      );
      emit(
        VisionAnalysisSuccess(
          type: analysisType,
          imagePath: imagePath,
          result: result,
        ),
      );
    } on VisionAnalysisException catch (error) {
      emit(
        VisionAnalysisFailure(
          type: analysisType,
          imagePath: imagePath,
          message: error.message,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('[VisionAnalysis] unexpected error=$error');
      debugPrintStack(stackTrace: stackTrace);
      emit(
        VisionAnalysisFailure(
          type: analysisType,
          imagePath: imagePath,
          message: 'Image analysis failed. Please try another image.',
        ),
      );
    }
  }
}
