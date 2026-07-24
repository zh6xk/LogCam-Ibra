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
        // Set content mode biar nggak melar (resize aspect fill butuh matrix math tambahan, 
        // tapi blit command cuma bisa copy 1:1, jadi kita terima default frame dlu)
        mtkView.contentMode = .scaleAspectFill
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // UI Size Updates kalau ada
    }
}
