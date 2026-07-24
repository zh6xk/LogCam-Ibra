import SwiftUI
import MetalKit

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var renderer: LogPreviewRenderer
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: UIScreen.main.bounds, device: renderer.device)
        mtkView.backgroundColor = .black
        mtkView.delegate = renderer
        mtkView.framebufferOnly = false
        mtkView.colorPixelFormat = .bgra8Unorm
        // Set ke aspectFit agar data kamera asli kelihatan utuh
        // SwiftUI yang akan mengatur stretch-nya lewat Frame
        mtkView.contentMode = .scaleAspectFill
        mtkView.translatesAutoresizingMaskIntoConstraints = true // Matikan custom constraint
        mtkView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
    }
}
