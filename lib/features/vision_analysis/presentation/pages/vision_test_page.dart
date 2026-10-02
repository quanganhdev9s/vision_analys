import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/datasources/vision_native_data_source.dart';
import '../../data/repositories/vision_analysis_repository_impl.dart';
import '../../domain/entities/vision_analysis_type.dart';
import '../bloc/vision_analysis_bloc.dart';
import '../bloc/vision_analysis_event.dart';
import '../bloc/vision_analysis_state.dart';
import '../widgets/vision_result_view.dart';

class VisionTestPage extends StatelessWidget {
  const VisionTestPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => VisionAnalysisBloc(
      VisionAnalysisRepositoryImpl(dataSource: VisionNativeDataSource()),
    ),
    child: const _VisionTestView(),
  );
}

class _VisionTestView extends StatefulWidget {
  const _VisionTestView();

  @override
  State<_VisionTestView> createState() => _VisionTestViewState();
}

class _VisionTestViewState extends State<_VisionTestView> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 100,
      );
      if (!mounted || file == null) return;
      context.read<VisionAnalysisBloc>().add(
        source == ImageSource.camera
            ? VisionImageCaptured(file.path)
            : VisionImageSelected(file.path),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to access the selected image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vision Analysis Test')),
    body: SafeArea(
      child: BlocBuilder<VisionAnalysisBloc, VisionAnalysisState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'VISION ANALYSIS TEST',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<VisionAnalysisType>(
              segments: const [
                ButtonSegment(
                  value: VisionAnalysisType.palm,
                  label: Text('Palm'),
                  icon: Icon(Icons.pan_tool_outlined),
                ),
                ButtonSegment(
                  value: VisionAnalysisType.face,
                  label: Text('Face'),
                  icon: Icon(Icons.face_outlined),
                ),
              ],
              selected: {state.type},
              onSelectionChanged: (types) => context
                  .read<VisionAnalysisBloc>()
                  .add(VisionAnalysisTypeChanged(types.first)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state is VisionAnalysisLoading
                        ? null
                        : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state is VisionAnalysisLoading
                        ? null
                        : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Pick Image'),
                  ),
                ),
              ],
            ),
            if (state.imagePath != null) ...[
              const SizedBox(height: 20),
              const Text('Image Preview'),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(state.imagePath!),
                  height: 260,
                  fit: BoxFit.contain,
                ),
              ),
            ],
            if (state is VisionAnalysisLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              const Center(child: Text('Analyzing image…')),
            ],
            if (state is VisionAnalysisSuccess)
              VisionResultView(result: state.result),
            if (state is VisionAnalysisFailure) ...[
              const SizedBox(height: 24),
              Text(state.message, style: const TextStyle(color: Colors.red)),
              TextButton(
                onPressed: () => context.read<VisionAnalysisBloc>().add(
                  const VisionAnalysisRequested(),
                ),
                child: const Text('Try again'),
              ),
            ],
            if (state.imagePath != null && state is! VisionAnalysisLoading)
              TextButton(
                onPressed: () => context.read<VisionAnalysisBloc>().add(
                  const VisionAnalysisReset(),
                ),
                child: const Text('Reset'),
              ),
          ],
        ),
      ),
    ),
  );
}
