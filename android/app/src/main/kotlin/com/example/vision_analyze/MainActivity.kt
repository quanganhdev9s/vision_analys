package com.example.vision_analyze

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.example.vision_analyze.vision.NativeVisionAnalyzer
import com.example.vision_analyze.vision.generated.NativeVisionApi

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    NativeVisionApi.setUp(flutterEngine.dartExecutor.binaryMessenger, NativeVisionAnalyzer(this))
  }
}
