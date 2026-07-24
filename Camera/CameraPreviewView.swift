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
        // Ubah dari scaleAspectFill ke scaleAspectFit agar tidak lari ke kiri/kanan
        mtkView.contentMode = .scaleAspectFill
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // UI Size Updates kalau ada
    }
}
