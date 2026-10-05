package com.example.vision_analyze.vision

import android.content.Context
import android.graphics.BitmapFactory
import android.util.Log
import com.example.vision_analyze.vision.generated.NativeVisionApi
import com.example.vision_analyze.vision.generated.NativeVisionConfig
import com.example.vision_analyze.vision.generated.NativeVisionResult
import com.example.vision_analyze.vision.generated.FlutterError
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import java.io.File

class NativeVisionAnalyzer(private val context: Context) : NativeVisionApi {
  override suspend fun analyzePalm(imagePath: String, config: NativeVisionConfig): NativeVisionResult {
    val bitmap = bitmap(imagePath)
    val quality = ImageQualityAnalyzer.analyze(bitmap)
    val hand = try {
      HandVisionAnalyzer(context).detect(bitmap, config.edgeMargin)
    } catch (error: Exception) {
      throw FlutterError("MODEL_NOT_AVAILABLE", "MediaPipe hand_landmarker.task is required.", error.message)
    }
    Log.d(TAG, "Palm detection completed: count=${hand.count}, handedness=${hand.handedness ?: "unknown"}, surface=${hand.handSurface ?: "unknown"}, image=${bitmap.width}x${bitmap.height}")
    val issues = qualityIssues(quality, config).toMutableList()
    if (hand.count == 0) issues += "NO_HAND"
    if (hand.count > 1) issues += "MULTIPLE_HANDS"
    if (hand.count == 1 && hand.coverage < config.minHandCoverage) issues += "HAND_TOO_FAR"
    if (hand.count == 1 && !hand.insideFrame) issues += "HAND_TOO_CLOSE_TO_EDGE"
    return result(hand.count > 0, hand.count, hand.insideFrame, hand.coverage, hand.coverage >= config.minHandCoverage, quality, config, issues, hand.handedness, handSurface = hand.handSurface)
  }

  override suspend fun analyzeFace(imagePath: String, config: NativeVisionConfig): NativeVisionResult {
    val bitmap = bitmap(imagePath)
    val quality = ImageQualityAnalyzer.analyze(bitmap)
    val options = FaceDetectorOptions.Builder()
      .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE)
      .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_NONE)
      .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_NONE)
      .build()
    val detector = FaceDetection.getClient(options)
    val faces = try {
      Tasks.await(detector.process(InputImage.fromFilePath(context, android.net.Uri.fromFile(File(imagePath)))))
    } catch (error: Exception) {
      Log.e(TAG, "Face detection failed for ${bitmap.width}x${bitmap.height} image", error)
      throw FlutterError("FACE_PROCESSING_FAILED", "Android face detection failed.", error.message)
    } finally {
      detector.close()
    }
    Log.d(TAG, "Face detection completed: count=${faces.size}, image=${bitmap.width}x${bitmap.height}")
    val issues = qualityIssues(quality, config).toMutableList()
    if (faces.isEmpty()) issues += "NO_FACE"
    if (faces.size > 1) issues += "MULTIPLE_FACES"
    val face = faces.firstOrNull()
    val coverage = face?.let { it.boundingBox.width().toDouble() * it.boundingBox.height() / (bitmap.width * bitmap.height) } ?: 0.0
    val inside = face?.let { it.boundingBox.left >= bitmap.width * config.edgeMargin && it.boundingBox.right <= bitmap.width * (1 - config.edgeMargin) && it.boundingBox.top >= bitmap.height * config.edgeMargin && it.boundingBox.bottom <= bitmap.height * (1 - config.edgeMargin) } ?: false
    val yaw = face?.headEulerAngleY?.toDouble()
    val roll = face?.headEulerAngleZ?.toDouble()
    if (face != null && coverage < config.minFaceCoverage) issues += "FACE_TOO_FAR"
    if (face != null && !inside) issues += "FACE_TOO_CLOSE_TO_EDGE"
    if (face != null && ((yaw?.let { kotlin.math.abs(it) } ?: 0.0) > config.maxFaceYaw || (roll?.let { kotlin.math.abs(it) } ?: 0.0) > config.maxFaceRoll)) issues += "FACE_NOT_FORWARD"
    return result(face != null, faces.size, inside, coverage, coverage >= config.minFaceCoverage, quality, config, issues, null, yaw, roll, null)
  }

  private fun bitmap(path: String) = BitmapFactory.decodeFile(path) ?: throw FlutterError("UNSUPPORTED_IMAGE", "Unable to decode image.", null)
  private fun qualityIssues(quality: ImageQuality, config: NativeVisionConfig) = buildList {
    if (quality.blurScore < config.minBlurScore) add("IMAGE_BLURRY")
    if (quality.brightnessScore < config.minBrightness) add("IMAGE_TOO_DARK")
    if (quality.brightnessScore > config.maxBrightness) add("IMAGE_TOO_BRIGHT")
  }
  private fun result(detected: Boolean, count: Int, inside: Boolean, coverage: Double, coverageEnough: Boolean, quality: ImageQuality, config: NativeVisionConfig, issues: List<String>, handedness: String?, yaw: Double? = null, roll: Double? = null, pitch: Double? = null, handSurface: String? = null) = NativeVisionResult(detected, count.toLong(), inside, coverageEnough, quality.blurScore >= config.minBlurScore, quality.brightnessScore in config.minBrightness..config.maxBrightness, coverage, quality.blurScore, quality.brightnessScore, issues, handedness, handSurface, yaw, roll, pitch)

  private companion object {
    const val TAG = "VisionAnalysis"
  }
}
