package com.example.vision_analyze.vision

import android.graphics.Bitmap
import kotlin.math.max

data class ImageQuality(val blurScore: Double, val brightnessScore: Double)

object ImageQualityAnalyzer {
  fun analyze(source: Bitmap): ImageQuality {
    val scale = minOf(1.0, 768.0 / max(source.width, source.height).toDouble())
    val width = max(2, (source.width * scale).toInt())
    val height = max(2, (source.height * scale).toInt())
    val bitmap = Bitmap.createScaledBitmap(source, width, height, true)
    val gray = IntArray(width * height)
    var brightness = 0.0
    for (y in 0 until height) for (x in 0 until width) {
      val pixel = bitmap.getPixel(x, y)
      val value = (0.2126 * ((pixel shr 16) and 0xff) + 0.7152 * ((pixel shr 8) and 0xff) + 0.0722 * (pixel and 0xff)).toInt()
      gray[y * width + x] = value
      brightness += value
    }
    var laplacianSum = 0.0
    var laplacianSquareSum = 0.0
    var count = 0
    for (y in 1 until height - 1) for (x in 1 until width - 1) {
      val value = 4 * gray[y * width + x] - gray[(y - 1) * width + x] - gray[(y + 1) * width + x] - gray[y * width + x - 1] - gray[y * width + x + 1]
      laplacianSum += value
      laplacianSquareSum += value * value
      count++
    }
    val variance = if (count == 0) 0.0 else laplacianSquareSum / count - (laplacianSum / count) * (laplacianSum / count)
    return ImageQuality(blurScore = variance, brightnessScore = brightness / (width * height))
  }
}
