import AVFoundation
import UIKit

final class CameraController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    var videoDevice: AVCaptureDevice?
    
    let videoDataOutput = AVCaptureVideoDataOutput()
    let audioDataOutput = AVCaptureAudioDataOutput()
    
    var assetWriterManager = AssetWriterManager()
    
    @Published var isRunning = false
    @Published var isRecording = false
    private var isConfigured = false
    private var currentOrientation: AVCaptureVideoOrientation = .portrait

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc func orientationChanged() {
        let deviceOrientation = UIDevice.current.orientation
        var newOrientation: AVCaptureVideoOrientation?
        switch deviceOrientation {
        case .portrait: newOrientation = .portrait
        case .portraitUpsideDown: newOrientation = .portraitUpsideDown
        case .landscapeLeft: newOrientation = .landscapeRight
        case .landscapeRight: newOrientation = .landscapeLeft
        default: break
        }
        
        if let newOrientation = newOrientation {
            currentOrientation = newOrientation
            
            // Atur orientasi data video yang direkam ke file
            sessionQueue.async {
                if let connection = self.videoDataOutput.connection(with: .video), connection.isVideoOrientationSupported {
                    connection.videoOrientation = newOrientation
                }
            }
        }
    }
    
    func start() {
        if isConfigured { return }
        checkPermission()
    }
    
    private func checkPermission() {
        AVCaptureDevice.requestAccess(for: .video) { videoGranted in
            AVCaptureDevice.requestAccess(for: .audio) { audioGranted in
                if videoGranted {
                    self.configureSession()
                }
            }
        }
    }

    private func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                self.session.commitConfiguration()
                return
            }
            self.videoDevice = device
            if let input = try? AVCaptureDeviceInput(device: device), self.session.canAddInput(input) {
                self.session.addInput(input)
            }

            if let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               self.session.canAddInput(audioInput) {
                self.session.addInput(audioInput)
            }

            self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
            let targetFormat = kCVPixelFormatType_32BGRA
            if self.videoDataOutput.availableVideoPixelFormatTypes.contains(targetFormat) {
                self.videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(targetFormat)]
            }
            self.videoDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            if self.session.canAddOutput(self.videoDataOutput) {
                self.session.addOutput(self.videoDataOutput)
            }

            self.audioDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            if self.session.canAddOutput(self.audioDataOutput) {
                self.session.addOutput(self.audioDataOutput)
            }

            if #available(iOS 17.0, *) {
                if let logFormat = device.formats.first(where: { $0.supportedColorSpaces.contains(.appleLog) }) {
                    do {
                        try device.lockForConfiguration()
                        device.activeFormat = logFormat
                        device.activeColorSpace = .appleLog
                        device.unlockForConfiguration()
                    } catch {}
                }
            }

            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                self.orientationChanged()
            }
            
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.isConfigured = true
                self.isRunning = true
            }
        }
    }
    
    func toggleRecording() {
        if isRecording {
            assetWriterManager.stopRecording { url in
                DispatchQueue.main.async {
                    self.isRecording = false
                    if let url = url {
                        UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
                    }
                }
            }
        } else {
            let tempDir = FileManager.default.temporaryDirectory
            let url = tempDir.appendingPathComponent("log_\(UUID().uuidString).mov")
            do {
                let isLandscape = (currentOrientation == .landscapeLeft || currentOrientation == .landscapeRight)
                let w = isLandscape ? 1920 : 1080
                let h = isLandscape ? 1080 : 1920
                try assetWriterManager.setupAssetWriter(outputURL: url, width: w, height: h)
                DispatchQueue.main.async {
                    self.isRecording = true
                }
            } catch {
                print("Gagal setup recorder: \(error)")
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Terapkan Shader Metal untuk Video S-Log3 kalau device tidak support Apple Log Native
        let isVideo = output === videoDataOutput
        
        if isVideo {
            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                // Di sini kita cek apakah format saat ini Apple Log. 
                // Kalau bukan, kita "paksa" jadi S-Log3 pake Metal.
                if #available(iOS 17.0, *), videoDevice?.activeColorSpace == .appleLog {
                    // Biarkan, sudah native LOG
                } else {
                    // Terapkan S-Log3 via Metal Compute Shader
                    MetalContext.shared.applyLogShader(to: pixelBuffer)
                }
            }
        }
        
        if isRecording {
            assetWriterManager.write(sampleBuffer: sampleBuffer, isVideo: isVideo)
        }
    }
}
