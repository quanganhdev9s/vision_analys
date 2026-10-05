package com.example.vision_analyze.vision

import android.content.Context
import android.graphics.Bitmap
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import com.google.mediapipe.framework.image.BitmapImageBuilder

data class HandDetection(
  val count: Int,
  val insideFrame: Boolean,
  val coverage: Double,
  val handedness: String?,
  val handSurface: String?,
)

class HandVisionAnalyzer(context: Context) {
  private val landmarker: HandLandmarker

  init {
    // MediaPipe's Android asset loader requires an asset path containing a directory.
    // The model is packaged at android/app/src/main/assets/mediapipe/hand_landmarker.task.
    val options = HandLandmarker.HandLandmarkerOptions.builder()
      .setBaseOptions(BaseOptions.builder().setModelAssetPath("mediapipe/hand_landmarker.task").build())
      .setRunningMode(RunningMode.IMAGE)
      .setNumHands(2)
      .build()
    landmarker = HandLandmarker.createFromOptions(context, options)
  }

  fun detect(bitmap: Bitmap, edgeMargin: Double): HandDetection {
    val result: HandLandmarkerResult = landmarker.detect(BitmapImageBuilder(bitmap).build())
    val hands = result.landmarks()
    if (hands.isEmpty()) return HandDetection(0, false, 0.0, null, null)
    val landmarks: List<NormalizedLandmark> = hands.first()
    val minX = landmarks.minOf { it.x().toDouble() }
    val maxX = landmarks.maxOf { it.x().toDouble() }
    val minY = landmarks.minOf { it.y().toDouble() }
    val maxY = landmarks.maxOf { it.y().toDouble() }
    val isInside = minX >= edgeMargin && maxX <= 1 - edgeMargin && minY >= edgeMargin && maxY <= 1 - edgeMargin
    val handedness = result.handedness().firstOrNull()?.firstOrNull()?.categoryName()
    val surface = inferHandSurface(landmarks, handedness)
    return HandDetection(hands.size, isInside, (maxX - minX) * (maxY - minY), handedness, surface)
  }

  /**
   * Infers which side of the hand faces the camera from the index/pinky MCP
   * ordering. MediaPipe does not expose a palm/back label directly. Returning
   * null for a nearly edge-on hand is safer than making a confident guess.
   */
  private fun inferHandSurface(landmarks: List<NormalizedLandmark>, handedness: String?): String? {
    if (landmarks.size <= PINKY_MCP || handedness.isNullOrBlank()) return null
    val wrist = landmarks[WRIST]
    val index = landmarks[INDEX_MCP]
    val pinky = landmarks[PINKY_MCP]
    // Convert MediaPipe's y-down image coordinates to y-up before computing
    // the signed angle. For a palm-facing camera, the normalized sign is > 0.
    val indexX = index.x() - wrist.x()
    val indexY = -(index.y() - wrist.y())
    val pinkyX = pinky.x() - wrist.x()
    val pinkyY = -(pinky.y() - wrist.y())
    val cross = indexX * pinkyY - indexY * pinkyX
    val scale = kotlin.math.hypot(indexX.toDouble(), indexY.toDouble()) *
      kotlin.math.hypot(pinkyX.toDouble(), pinkyY.toDouble())
    if (scale < MIN_VECTOR_SCALE) return null
    val normalizedCross = cross / scale
    if (kotlin.math.abs(normalizedCross) < MIN_SURFACE_SCORE) return null
    val handSign = if (handedness.equals("Left", ignoreCase = true)) 1.0 else -1.0
    return if (normalizedCross * handSign > 0) "Palm" else "Back"
  }

  private companion object {
    const val WRIST = 0
    const val INDEX_MCP = 5
    const val PINKY_MCP = 17
    const val MIN_VECTOR_SCALE = 0.01
    const val MIN_SURFACE_SCORE = 0.12
  }
}
