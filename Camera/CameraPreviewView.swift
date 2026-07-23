import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        // Pake layer murni supaya SwiftUI gak coba pinter-pinteran motong layout
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = UIScreen.main.bounds
        view.layer.addSublayer(layer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            layer.session = session
            DispatchQueue.main.async {
                // UI bounds tetep full
                layer.frame = uiView.bounds
                
                // Rotasi video didalam layar
                if let connection = layer.connection, connection.isVideoOrientationSupported {
                    let orientation = UIDevice.current.orientation
                    switch orientation {
                    case .portrait: connection.videoOrientation = .portrait
                    case .landscapeRight: connection.videoOrientation = .landscapeLeft
                    case .landscapeLeft: connection.videoOrientation = .landscapeRight
                    case .portraitUpsideDown: connection.videoOrientation = .portraitUpsideDown
                    default: connection.videoOrientation = .portrait
                    }
                }
            }
        }
    }
}
