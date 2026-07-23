import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        // Set frame dengan ukuran asli layar awal
        layer.frame = UIScreen.main.bounds
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            layer.session = session
            // Harus panggil bounds uiView di thread utama supaya nilainya bener saat rotasi
            DispatchQueue.main.async {
                layer.frame = uiView.bounds
                
                if let connection = layer.connection, connection.isVideoOrientationSupported {
                    let orientation = UIDevice.current.orientation
                    switch orientation {
                    case .portrait:
                        connection.videoOrientation = .portrait
                    case .landscapeRight:
                        connection.videoOrientation = .landscapeLeft
                    case .landscapeLeft:
                        connection.videoOrientation = .landscapeRight
                    case .portraitUpsideDown:
                        connection.videoOrientation = .portraitUpsideDown
                    default:
                        connection.videoOrientation = .portrait
                    }
                }
            }
        }
    }
}
