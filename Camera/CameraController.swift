import AVFoundation

final class CameraController: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    var videoDevice: AVCaptureDevice?
    let videoDataOutput = AVCaptureVideoDataOutput()
    
    @Published var isRunning = false
    private var isConfigured = false

    override init() {
        super.init()
    }
    
    func start() {
        if isConfigured { return }
        checkPermission()
    }
    
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.configureSession()
                }
            }
        default:
            print("Izin kamera ditolak")
        }
    }

    private func configureSession() {
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
                print("Gagal buat input: \(error)")
            }

            self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
            
            if self.session.canAddOutput(self.videoDataOutput) {
                self.session.addOutput(self.videoDataOutput)
            }
            
            let targetFormat = kCVPixelFormatType_422YpCbCr10BiPlanarFullRange
            if self.videoDataOutput.availableVideoPixelFormatTypes.contains(targetFormat) {
                self.videoDataOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(targetFormat)
                ]
            }

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
                self.isConfigured = true
                self.isRunning = true
            }
        }
    }
}
