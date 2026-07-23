import AVFoundation

final class CameraController: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    @Published var isRunning = false

    override init() {
        super.init()
    }
    
    func start() {
        checkPermission()
    }
    
    private func checkPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                self.configureSession()
            }
        }
    }

    private func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .vga640x480

            guard let device = AVCaptureDevice.default(for: .video) else { return }

            if let input = try? AVCaptureDeviceInput(device: device) {
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }
            }

            let output = AVCaptureVideoDataOutput()
            if self.session.canAddOutput(output) {
                self.session.addOutput(output)
            }

            self.session.commitConfiguration()
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.isRunning = true
            }
        }
    }
}
