package com.example.vision_analyze.vision

import android.content.Context
import android.graphics.Bitmap
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import com.google.mediapipe.framework.image.BitmapImageBuilder

data class HandDetection(val count: Int, val insideFrame: Boolean, val coverage: Double, val handedness: String?)

class HandVisionAnalyzer(context: Context) {
  private val landmarker: HandLandmarker

  init {
    // The model is intentionally not bundled: obtain a compatible model from MediaPipe
    // and add it as android/app/src/main/assets/hand_landmarker.task.
    val options = HandLandmarker.HandLandmarkerOptions.builder()
      .setBaseOptions(BaseOptions.builder().setModelAssetPath("hand_landmarker.task").build())
      .setRunningMode(RunningMode.IMAGE)
      .setNumHands(2)
      .build()
    landmarker = HandLandmarker.createFromOptions(context, options)
  }

  fun detect(bitmap: Bitmap, edgeMargin: Double): HandDetection {
    val result: HandLandmarkerResult = landmarker.detect(BitmapImageBuilder(bitmap).build())
    val hands = result.landmarks()
    if (hands.isEmpty()) return HandDetection(0, false, 0.0, null)
    val landmarks: List<NormalizedLandmark> = hands.first()
    val minX = landmarks.minOf { it.x().toDouble() }
    val maxX = landmarks.maxOf { it.x().toDouble() }
    val minY = landmarks.minOf { it.y().toDouble() }
    val maxY = landmarks.maxOf { it.y().toDouble() }
    val isInside = minX >= edgeMargin && maxX <= 1 - edgeMargin && minY >= edgeMargin && maxY <= 1 - edgeMargin
    val handedness = result.handedness().firstOrNull()?.firstOrNull()?.categoryName()
    return HandDetection(hands.size, isInside, (maxX - minX) * (maxY - minY), handedness)
  }
}
