import 'package:flutter/material.dart';

import 'features/vision_analysis/presentation/pages/vision_test_page.dart';

void main() => runApp(const VisionAnalyzeApp());

class VisionAnalyzeApp extends StatelessWidget {
  const VisionAnalyzeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Vision Analysis Test',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    ),
    home: const VisionTestPage(),
  );
}
