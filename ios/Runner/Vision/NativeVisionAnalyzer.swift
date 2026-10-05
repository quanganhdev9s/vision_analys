import CryptoKit
import Foundation
import ImageIO
import UIKit
import Vision

final class NativeVisionAnalyzer: NativeVisionApi {
  func analyzePalm(imagePath: String, config: NativeVisionConfig) async throws -> NativeVisionResult {
    logImageInput(imagePath)
    let image = try load(imagePath)
    let pixels = normalizedCGImage(image)
    visionLog("palm decoded points=\(Int(image.size.width))x\(Int(image.size.height)) scale=\(image.scale) uiOrientation=\(image.imageOrientation.rawValue) rawPixels=\(image.cgImage?.width ?? 0)x\(image.cgImage?.height ?? 0) visionPixels=\(pixels.width)x\(pixels.height)")
    let quality = quality(of: image)
    let hands = try detectHands(in: pixels)
    visionLog("palm detectedHands=\(hands.count) blur=\(quality.blur) brightness=\(quality.brightness)")
    var coverage = 0.0
    var inside = false
    var handedness: String?
    var handSurface: String?
    if let hand = hands.first {
      let recognizedPoints = try hand.recognizedPoints(.all)
      let points = recognizedPoints.values.filter { $0.confidence > 0.5 }
      let confidenceRange = recognizedPoints.values.map(\.confidence)
      visionLog("palm landmarks total=\(recognizedPoints.count) confident=\(points.count) minConfidence=\(confidenceRange.min() ?? 0) maxConfidence=\(confidenceRange.max() ?? 0)")
      if !points.isEmpty {
        let xs = points.map { Double($0.location.x) }
        let ys = points.map { Double($0.location.y) }
        let minX = xs.min()!, maxX = xs.max()!, minY = ys.min()!, maxY = ys.max()!
        coverage = (maxX - minX) * (maxY - minY)
        inside = minX >= config.edgeMargin && maxX <= 1 - config.edgeMargin && minY >= config.edgeMargin && maxY <= 1 - config.edgeMargin
      }
      switch hand.chirality {
      case .left:
        handedness = "Left"
      case .right:
        handedness = "Right"
      case .unknown:
        handedness = nil
      @unknown default:
        handedness = nil
      }
      handSurface = inferHandSurface(from: recognizedPoints, chirality: hand.chirality)
      visionLog("palm chirality raw=\(hand.chirality.rawValue) mapped=\(handedness ?? "Unknown")")
      visionLog("palm surface=\(handSurface ?? "Unknown")")
    }
    var issues = quality.issues(config)
    if hands.isEmpty { issues.append("NO_HAND") }
    if hands.count > 1 { issues.append("MULTIPLE_HANDS") }
    if hands.count == 1 && coverage < config.minHandCoverage { issues.append("HAND_TOO_FAR") }
    if hands.count == 1 && !inside { issues.append("HAND_TOO_CLOSE_TO_EDGE") }
    visionLog("palm result coverage=\(coverage) inside=\(inside) handedness=\(handedness ?? "unknown") surface=\(handSurface ?? "unknown") issues=\(issues)")
    return result(detected: !hands.isEmpty, count: hands.count, inside: inside, coverage: coverage, sufficient: coverage >= config.minHandCoverage, quality: quality, config: config, issues: issues, handedness: handedness, handSurface: handSurface)
  }

  func analyzeFace(imagePath: String, config: NativeVisionConfig) async throws -> NativeVisionResult {
    logImageInput(imagePath)
    let image = try load(imagePath)
    let quality = quality(of: image)
    let request = VNDetectFaceRectanglesRequest()
    request.usesCPUOnly = true
    visionLog("face decoded points=\(Int(image.size.width))x\(Int(image.size.height)) revision=\(request.revision) cpuOnly=true")
    do {
      try VNImageRequestHandler(cgImage: normalizedCGImage(image), orientation: .up).perform([request])
    } catch {
      visionLog("face request error=\(error)")
      throw PigeonError(
        code: "VISION_INFERENCE_CONTEXT",
        message: "Apple Vision could not create a face inference context.",
        details: error.localizedDescription
      )
    }
    let faces = request.results ?? []
    visionLog("face detectedFaces=\(faces.count) blur=\(quality.blur) brightness=\(quality.brightness)")
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

  /// The image pixels are normalized before this call, so Vision uses `.up`.
  private func detectHands(in cgImage: CGImage) throws -> [VNHumanHandPoseObservation] {
    let request = VNDetectHumanHandPoseRequest()
    request.maximumHandCount = 2
    do {
      try VNImageRequestHandler(cgImage: cgImage, orientation: .up).perform([request])
    } catch {
      visionLog("palm request revision=\(request.revision) error=\(error)")
      throw error
    }
    let results = request.results ?? []
    visionLog("palm request revision=\(request.revision) hands=\(results.count)")
    return results
  }
  private func result(detected: Bool, count: Int, inside: Bool, coverage: Double, sufficient: Bool, quality: ImageQuality, config: NativeVisionConfig, issues: [String], handedness: String? = nil, handSurface: String? = nil) -> NativeVisionResult {
    NativeVisionResult(objectDetected: detected, objectCount: Int64(count), insideFrame: inside, sufficientCoverage: sufficient, sharpEnough: quality.blur >= config.minBlurScore, lightingAcceptable: quality.brightness >= config.minBrightness && quality.brightness <= config.maxBrightness, coverage: coverage, blurScore: quality.blur, brightnessScore: quality.brightness, issues: issues, handedness: handedness, handSurface: handSurface, yaw: nil, roll: nil, pitch: nil)
  }

  /// Vision exposes landmarks and chirality, but not a palm/back label. The
  /// signed ordering of the index and little-finger MCP joints provides a
  /// conservative 2D estimate; edge-on or low-confidence hands return nil.
  private func inferHandSurface(from points: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint], chirality: VNChirality) -> String? {
    guard let wrist = points[.wrist], let index = points[.indexMCP], let little = points[.littleMCP], wrist.confidence > 0.5, index.confidence > 0.5, little.confidence > 0.5 else { return nil }
    let indexX = index.location.x - wrist.location.x
    let indexY = index.location.y - wrist.location.y
    let littleX = little.location.x - wrist.location.x
    let littleY = little.location.y - wrist.location.y
    let cross = indexX * littleY - indexY * littleX
    let scale = hypot(indexX, indexY) * hypot(littleX, littleY)
    guard scale >= 0.01 else { return nil }
    let normalizedCross = cross / scale
    guard abs(normalizedCross) >= 0.12 else { return nil }
    let handSign = chirality == .left ? 1.0 : -1.0
    return normalizedCross * handSign > 0 ? "Palm" : "Back"
  }
}

private func logImageInput(_ path: String) {
  #if DEBUG
  let url = URL(fileURLWithPath: path)
  let attributes = try? FileManager.default.attributesOfItem(atPath: path)
  let byteCount = attributes?[.size] as? NSNumber
  let data = try? Data(contentsOf: url, options: .mappedIfSafe)
  let digest = data.map { SHA256.hash(data: $0).map { String(format: "%02x", $0) }.joined().prefix(12) }
  let source = CGImageSourceCreateWithURL(url as CFURL, nil)
  let properties = source.flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) as? [CFString: Any] }
  let exifOrientation = properties?[kCGImagePropertyOrientation] ?? "missing"
  visionLog("palm input name=\(url.lastPathComponent) bytes=\(byteCount?.intValue ?? -1) sha256Prefix=\(digest.map(String.init) ?? "unavailable") exifOrientation=\(exifOrientation) sourcePixels=\(properties?[kCGImagePropertyPixelWidth] ?? "unknown")x\(properties?[kCGImagePropertyPixelHeight] ?? "unknown")")
  #endif
}

private func visionLog(_ message: String) {
  #if DEBUG
  NSLog("%@", "[VisionAnalysis][iOS][r4] \(message)")
  #endif
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

/// Vision receives pixels in their displayed orientation. `UIImage.cgImage` alone
/// drops EXIF/UI image orientation, which can make a portrait hand appear rotated.
private func normalizedCGImage(_ image: UIImage) -> CGImage {
  if image.imageOrientation == .up, let cgImage = image.cgImage { return cgImage }
  let renderer = UIGraphicsImageRenderer(size: image.size)
  return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: image.size)) }.cgImage!
}
