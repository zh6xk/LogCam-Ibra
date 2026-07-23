import AVFoundation

final class CameraController: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    var videoDevice: AVCaptureDevice?
    let videoDataOutput = AVCaptureVideoDataOutput()
    
    @Published var isRunning = false

    override init() {
        super.init()
        configureSession()
    }

    func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .inputPriority

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                print("Kamera tidak ditemukan")
                self.session.commitConfiguration()
                return
            }
            self.videoDevice = device

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }
            } catch {
                print("Gagal buat input: \\(error)")
            }

            self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
            
            // Set 10-bit YUV kalau disupport buat raw data terbaik sebelum shader
            self.videoDataOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_422YpCbCr10BiPlanarFullRange)
            ]
            
            if self.session.canAddOutput(self.videoDataOutput) {
                self.session.addOutput(self.videoDataOutput)
            }

            // Apple Log native
            if #available(iOS 17.0, *) {
                if let logFormat = device.formats.first(where: { $0.supportedColorSpaces.contains(.appleLog) }) {
                    try? device.lockForConfiguration()
                    device.activeFormat = logFormat
                    device.activeColorSpace = .appleLog
                    device.unlockForConfiguration()
                }
            }

            self.session.commitConfiguration()
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.isRunning = true
            }
        }
    }
}
