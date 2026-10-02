import Foundation
import UIKit
import Vision

final class NativeVisionAnalyzer: NativeVisionApi {
  func analyzePalm(imagePath: String, config: NativeVisionConfig) async throws -> NativeVisionResult {
    let image = try load(imagePath)
    let quality = quality(of: image)
    let request = VNDetectHumanHandPoseRequest()
    request.maximumHandCount = 2
    try VNImageRequestHandler(cgImage: image.cgImage!, orientation: .up).perform([request])
    let hands = request.results ?? []
    var coverage = 0.0
    var inside = false
    var handedness: String?
    if let hand = hands.first {
      let points = try hand.recognizedPoints(.all).values.filter { $0.confidence > 0.5 }
      if !points.isEmpty {
        let xs = points.map { Double($0.location.x) }
        let ys = points.map { Double($0.location.y) }
        let minX = xs.min()!, maxX = xs.max()!, minY = ys.min()!, maxY = ys.max()!
        coverage = (maxX - minX) * (maxY - minY)
        inside = minX >= config.edgeMargin && maxX <= 1 - config.edgeMargin && minY >= config.edgeMargin && maxY <= 1 - config.edgeMargin
      }
      handedness = hand.chirality == .left ? "Left" : "Right"
    }
    var issues = quality.issues(config)
    if hands.isEmpty { issues.append("NO_HAND") }
    if hands.count > 1 { issues.append("MULTIPLE_HANDS") }
    if hands.count == 1 && coverage < config.minHandCoverage { issues.append("HAND_TOO_FAR") }
    if hands.count == 1 && !inside { issues.append("HAND_TOO_CLOSE_TO_EDGE") }
    return result(detected: !hands.isEmpty, count: hands.count, inside: inside, coverage: coverage, sufficient: coverage >= config.minHandCoverage, quality: quality, config: config, issues: issues, handedness: handedness)
  }

  func analyzeFace(imagePath: String, config: NativeVisionConfig) async throws -> NativeVisionResult {
    let image = try load(imagePath)
    let quality = quality(of: image)
    let request = VNDetectFaceRectanglesRequest()
    try VNImageRequestHandler(cgImage: image.cgImage!, orientation: .up).perform([request])
    let faces = request.results ?? []
    let box = faces.first?.boundingBox
    let coverage = box.map { Double($0.width * $0.height) } ?? 0
    let inside = box.map { $0.minX >= config.edgeMargin && $0.maxX <= 1 - config.edgeMargin && $0.minY >= config.edgeMargin && $0.maxY <= 1 - config.edgeMargin } ?? false
    var issues = quality.issues(config)
    if faces.isEmpty { issues.append("NO_FACE") }
    if faces.count > 1 { issues.append("MULTIPLE_FACES") }
    if faces.count == 1 && coverage < config.minFaceCoverage { issues.append("FACE_TOO_FAR") }
    if faces.count == 1 && !inside { issues.append("FACE_TOO_CLOSE_TO_EDGE") }
    // Vision's rectangle request does not provide reliable Euler angles. Do not infer them.
    return result(detected: !faces.isEmpty, count: faces.count, inside: inside, coverage: coverage, sufficient: coverage >= config.minFaceCoverage, quality: quality, config: config, issues: issues)
  }

  private func load(_ path: String) throws -> UIImage {
    guard let image = UIImage(contentsOfFile: path), image.cgImage != nil else {
      throw PigeonError(code: "UNSUPPORTED_IMAGE", message: "Unable to decode image.", details: nil)
    }
    return image
  }
  private func result(detected: Bool, count: Int, inside: Bool, coverage: Double, sufficient: Bool, quality: ImageQuality, config: NativeVisionConfig, issues: [String], handedness: String? = nil) -> NativeVisionResult {
    NativeVisionResult(objectDetected: detected, objectCount: Int64(count), insideFrame: inside, sufficientCoverage: sufficient, sharpEnough: quality.blur >= config.minBlurScore, lightingAcceptable: quality.brightness >= config.minBrightness && quality.brightness <= config.maxBrightness, coverage: coverage, blurScore: quality.blur, brightnessScore: quality.brightness, issues: issues, handedness: handedness, yaw: nil, roll: nil, pitch: nil)
  }
}

private struct ImageQuality {
  let blur: Double
  let brightness: Double
  func issues(_ config: NativeVisionConfig) -> [String] {
    var result: [String] = []
    if blur < config.minBlurScore { result.append("IMAGE_BLURRY") }
    if brightness < config.minBrightness { result.append("IMAGE_TOO_DARK") }
    if brightness > config.maxBrightness { result.append("IMAGE_TOO_BRIGHT") }
    return result
  }
}

private func quality(of image: UIImage) -> ImageQuality {
  guard let cgImage = image.cgImage else { return ImageQuality(blur: 0, brightness: 0) }
  let width = min(cgImage.width, 768), height = max(2, Int(Double(cgImage.height) * Double(width) / Double(cgImage.width)))
  var pixels = [UInt8](repeating: 0, count: width * height * 4)
  guard let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return ImageQuality(blur: 0, brightness: 0) }
  context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
  var gray = [Double](repeating: 0, count: width * height); var brightness = 0.0
  for i in 0..<(width * height) { let p = i * 4; gray[i] = 0.2126 * Double(pixels[p]) + 0.7152 * Double(pixels[p + 1]) + 0.0722 * Double(pixels[p + 2]); brightness += gray[i] }
  var sum = 0.0, square = 0.0, count = 0.0
  for y in 1..<(height - 1) { for x in 1..<(width - 1) { let i = y * width + x; let lap = 4 * gray[i] - gray[i - width] - gray[i + width] - gray[i - 1] - gray[i + 1]; sum += lap; square += lap * lap; count += 1 } }
  return ImageQuality(blur: count == 0 ? 0 : square / count - (sum / count) * (sum / count), brightness: brightness / Double(width * height))
}
