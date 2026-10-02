import 'package:flutter/material.dart';

class ValidationItem extends StatelessWidget {
  const ValidationItem({
    super.key,
    required this.label,
    required this.valid,
    this.value,
  });

  final String label;
  final bool valid;
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
          valid ? Icons.check_circle : Icons.cancel,
          color: valid ? Colors.green : Colors.red,
          semanticLabel: valid ? 'Pass' : 'Fail',
        ),
      ],
    ),
  );
}
