import UIKit
import AVFoundation

class ViewController: UIViewController {

  let stillImageOutput = AVCaptureStillImageOutput()

  var session: AVCaptureSession?
  var stillOutput = AVCaptureStillImageOutput()
  var borderLayer: CAShapeLayer?

  let greenRect: GreenView = GreenView()

  lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
    var previewLay = AVCaptureVideoPreviewLayer(session: self.session!)
    previewLay.videoGravity = .resizeAspect
    return previewLay
  }()

  let frontCamera = Camera.getFrontCamera()
  let faceDetector = FaceDetector.createFaceDetector()

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    previewLayer?.frame = view.frame
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    sessionPrepare()
    session?.startRunning()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard let previewLayer = previewLayer else { return }

    view.layer.addSublayer(previewLayer)
    view.addSubview(greenRect)
    view.bringSubviewToFront(greenRect)
  }
}

extension ViewController {

  func sessionPrepare() {
    session = AVCaptureSession()

    guard let session = session, let captureDevice = frontCamera else { return }

    session.sessionPreset = .photo

    let deviceInput: AVCaptureDeviceInput
    do {
      deviceInput = try AVCaptureDeviceInput(device: captureDevice)
    } catch {
      print("error with creating AVCaptureDeviceInput")
      return
    }

    session.beginConfiguration()
    stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]

    if session.canAddOutput(stillImageOutput) {
      session.addOutput(stillImageOutput)
    }

    if session.canAddInput(deviceInput) {
      session.addInput(deviceInput)
    }

    let output = AVCaptureVideoDataOutput()
    output.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]

    output.alwaysDiscardsLateVideoFrames = true

    if session.canAddOutput(output) {
      session.addOutput(output)
    }

    session.commitConfiguration()

    let queue = DispatchQueue(label: "output.queue")
    output.setSampleBufferDelegate(self, queue: queue)
  }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

  func captureOutput(_ output: AVCaptureOutput,
                     didOutput sampleBuffer: CMSampleBuffer,
                     from connection: AVCaptureConnection) {
    let features = Camera.findFaceFeatures(faceDetector: faceDetector, sampleBuffer: sampleBuffer)

    let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
    let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(formatDescription!, originIsAtTopLeft: false)

    for feature in features {
      let faceRect = calculateFaceRect(
        facePosition: feature.mouthPosition,
        faceBounds: feature.bounds,
        clearAperture: cleanAperture)
      greenRect.show(at: faceRect)
    }

    if features.count == 0 {
      greenRect.hide()
    }
  }

  func videoBox(frameSize: CGSize, apertureSize: CGSize) -> CGRect {
    let apertureRatio = apertureSize.height / apertureSize.width
    let viewRatio = frameSize.width / frameSize.height

    var size = CGSize.zero

    if viewRatio > apertureRatio {
      size.width = frameSize.width
      size.height = apertureSize.width * (frameSize.width / apertureSize.height)
    } else {
      size.width = apertureSize.height * (frameSize.height / apertureSize.width)
      size.height = frameSize.height
    }

    var videoBox = CGRect(origin: .zero, size: size)

    if size.width < frameSize.width {
      videoBox.origin.x = (frameSize.width - size.width) / 2.0
    } else {
      videoBox.origin.x = (size.width - frameSize.width) / 2.0
    }

    if size.height < frameSize.height {
      videoBox.origin.y = (frameSize.height - size.height) / 2.0
    } else {
      videoBox.origin.y = (size.height - frameSize.height) / 2.0
    }

    return videoBox
  }

  func calculateFaceRect(facePosition: CGPoint, faceBounds: CGRect, clearAperture: CGRect) -> CGRect {
    let parentFrameSize = previewLayer!.frame.size
    let previewBox = videoBox(frameSize: parentFrameSize, apertureSize: clearAperture.size)

    var faceRect = faceBounds

    swap(&faceRect.size.width, &faceRect.size.height)
    swap(&faceRect.origin.x, &faceRect.origin.y)

    let widthScaleBy = previewBox.size.width / clearAperture.size.height
    let heightScaleBy = previewBox.size.height / clearAperture.size.width

    faceRect.size.width *= widthScaleBy
    faceRect.size.height *= heightScaleBy
    faceRect.origin.x *= widthScaleBy
    faceRect.origin.y *= heightScaleBy

    faceRect = faceRect.offsetBy(dx: 0.0, dy: previewBox.origin.y)
    let x: CGFloat = parentFrameSize.width - faceRect.origin.x - faceRect.size.width + previewBox.origin.x
    let frame = CGRect(x: x, y: faceRect.origin.y, width: faceRect.width, height: faceRect.height)

    return frame
  }
}
