import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            layer.session = session
            DispatchQueue.main.async {
                layer.frame = uiView.bounds
                
                // Rotasi layer UI kamera supaya ngikut orientasi HP yang sebenarnya
                let orientation = UIDevice.current.orientation
                if let connection = layer.connection, connection.isVideoOrientationSupported {
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
                        break
                    }
                }
            }
        }
    }
}
