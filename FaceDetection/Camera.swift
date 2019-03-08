import UIKit.UIDevice
import AVFoundation.AVCaptureDevice

class Camera {
  static func getFrontCamera() -> AVCaptureDevice? {
    for device in AVCaptureDevice.devices(for: .video) {
      if device.position == .front {
        return device
      }
    }

    return nil
  }

  static func exifOrientation(orientation: UIDeviceOrientation) -> Int {
    switch orientation {
    case .portraitUpsideDown: return 8
    case .landscapeLeft: return 3
    case .landscapeRight: return 1
    default: return 6
    }
  }

  static func findFaceFeatures(
    faceDetector: CIDetector = FaceDetector.createFaceDetector(),
    sampleBuffer: CMSampleBuffer
    ) -> [CIFaceFeature]
  {
    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)

    let attachments = CMCopyDictionaryOfAttachments(
      allocator: kCFAllocatorDefault,
      target: sampleBuffer,
      attachmentMode: kCMAttachmentMode_ShouldPropagate)

    let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as? [CIImageOption: Any])

    let options: [String: Any] = [
      CIDetectorImageOrientation: Camera.exifOrientation(orientation: UIDevice.current.orientation),
      CIDetectorSmile: true,
      CIDetectorEyeBlink: true
    ]

    return faceDetector.features(in: ciImage, options: options).compactMap { $0 as? CIFaceFeature }
  }
}
