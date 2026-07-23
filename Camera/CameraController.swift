import AVFoundation
import UIKit

final class CameraController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    var videoDevice: AVCaptureDevice?
    let videoDataOutput = AVCaptureVideoDataOutput()
    var assetWriterManager = AssetWriterManager()
    
    @Published var isRunning = false
    @Published var isRecording = false
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
            self.session.sessionPreset = .high

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
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
                self.session.commitConfiguration()
                return
            }

            self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
            
            let targetFormat = kCVPixelFormatType_32BGRA
            if self.videoDataOutput.availableVideoPixelFormatTypes.contains(targetFormat) {
                self.videoDataOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(targetFormat)
                ]
            }

            self.videoDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)

            if self.session.canAddOutput(self.videoDataOutput) {
                self.session.addOutput(self.videoDataOutput)
                
                // Fix orientasi rekam portrait (Video Connection)
                if let connection = self.videoDataOutput.connection(with: .video) {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                    }
                }
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
                // Fix dimensi Portrait (Height lebih besar dari Width)
                try assetWriterManager.setupAssetWriter(outputURL: url, width: 1080, height: 1920)
                DispatchQueue.main.async {
                    self.isRecording = true
                }
            } catch {
                print("Gagal setup recorder: \(error)")
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if isRecording {
            assetWriterManager.write(sampleBuffer: sampleBuffer)
        }
    }
}
