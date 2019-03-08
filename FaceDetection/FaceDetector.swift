import UIKit
import AVFoundation

class FaceDetector {

  static func createFaceDetector(options: [String : Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh]) -> CIDetector {
    return CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)!
  }
}
