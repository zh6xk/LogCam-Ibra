import SwiftUI
import MetalKit

// Ganti jadi UIViewControllerRepresentable biar view dapet frame Lifecycle yang utuh dari awal
struct CameraPreviewView: UIViewControllerRepresentable {
    @ObservedObject var renderer: LogPreviewRenderer
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .black
        
        let mtkView = MTKView(frame: UIScreen.main.bounds, device: renderer.device)
        mtkView.backgroundColor = .black
        mtkView.delegate = renderer
        mtkView.framebufferOnly = false
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.contentMode = .scaleAspectFill
        
        // Pake autolayout beneran biar nutup 4 sisi 
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(mtkView)
        
        NSLayoutConstraint.activate([
            mtkView.topAnchor.constraint(equalTo: vc.view.topAnchor),
            mtkView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
            mtkView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            mtkView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor)
        ])
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
