import SwiftUI
import MetalKit

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var renderer: LogPreviewRenderer
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero, device: renderer.device)
        mtkView.backgroundColor = .black
        mtkView.delegate = renderer
        mtkView.framebufferOnly = false
        mtkView.colorPixelFormat = .bgra8Unorm
        // Kembali ke aspectFill agar viewport tidak miring/terpotong aneh, 
        // tapi di ContentView kita pastikan bounding boxnya sesuai layar
        mtkView.contentMode = .scaleAspectFill
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        
        // Paksa layer MTKView untuk fill superview saat render
        mtkView.layer.contentsGravity = .resizeAspectFill
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
    }
}
