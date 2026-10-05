import 'package:flutter/material.dart';

class ValidationItem extends StatelessWidget {
  const ValidationItem({
    super.key,
    required this.label,
    required this.valid,
    this.value,
  });

  final String label;

  /// Null means an informational value, not a validation pass or failure.
  final bool? valid;
  final String? value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        if (value != null) Text(value!),
        const SizedBox(width: 8),
        Icon(
          switch (valid) {
            true => Icons.check_circle,
            false => Icons.cancel,
            null => Icons.help_outline,
          },
          color: switch (valid) {
            true => Colors.green,
            false => Colors.red,
            null => Colors.grey,
          },
          semanticLabel: switch (valid) {
            true => 'Pass',
            false => 'Fail',
            null => 'Unknown',
          },
        ),
      ],
    ),
  );
}
