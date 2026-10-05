import 'package:flutter/material.dart';

import '../../domain/entities/face_validation_result.dart';
import '../../domain/entities/palm_validation_result.dart';
import '../../domain/entities/vision_validation_result.dart';
import 'validation_item.dart';

class VisionResultView extends StatelessWidget {
  const VisionResultView({super.key, required this.result});
  final VisionValidationResult result;

  @override
  Widget build(BuildContext context) {
    final items = switch (result) {
      PalmValidationResult palm => [
        ValidationItem(label: 'Hand detected', valid: palm.handDetected),
        ValidationItem(
          label: 'Single hand',
          valid: palm.handCount == 1,
          value: '${palm.handCount}',
        ),
        ValidationItem(label: 'Inside frame', valid: palm.handInsideFrame),
        ValidationItem(
          label: 'Coverage',
          valid: palm.sufficientCoverage,
          value: _percent(palm.handCoverage),
        ),
        ValidationItem(
          label: 'Sharpness',
          valid: palm.imageSharpEnough,
          value: _decimal(palm.blurScore),
        ),
        ValidationItem(
          label: 'Brightness',
          valid: palm.lightingAcceptable,
          value: _decimal(palm.brightnessScore),
        ),
        ValidationItem(
          label: 'Handedness',
          valid: null,
          value: palm.handedness ?? 'Unknown',
        ),
      ],
      FaceValidationResult face => [
        ValidationItem(label: 'Face detected', valid: face.faceDetected),
        ValidationItem(
          label: 'Single face',
          valid: face.faceCount == 1,
          value: '${face.faceCount}',
        ),
        ValidationItem(label: 'Inside frame', valid: face.faceInsideFrame),
        ValidationItem(label: 'Facing forward', valid: face.facingForward),
        ValidationItem(
          label: 'Coverage',
          valid: face.sufficientCoverage,
          value: _percent(face.faceCoverage),
        ),
        ValidationItem(
          label: 'Sharpness',
          valid: face.imageSharpEnough,
          value: _decimal(face.blurScore),
        ),
        ValidationItem(
          label: 'Brightness',
          valid: face.lightingAcceptable,
          value: _decimal(face.brightnessScore),
        ),
      ],
      _ => const <Widget>[],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        ...items,
        const Divider(height: 32),
        Text('RESULT', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          result.isValid ? 'READY FOR BACKEND' : 'INVALID IMAGE',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: result.isValid ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (result.issues.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Issues:'),
          ...result.issues.map(
            (issue) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• ${issue.message}'),
            ),
          ),
        ],
      ],
    );
  }

  String _percent(double? value) =>
      value == null ? '—' : '${(value * 100).toStringAsFixed(0)}%';
  String _decimal(double? value) =>
      value == null ? '—' : value.toStringAsFixed(1);
}
