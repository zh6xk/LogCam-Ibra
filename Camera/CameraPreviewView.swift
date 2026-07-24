import SwiftUI
import MetalKit

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var camera: CameraController
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: UIScreen.main.bounds)
        let renderer = LogPreviewRenderer(metalView: mtkView)
        context.coordinator.renderer = renderer
        
        // Simpan referensi ke coordinator untuk update frame
        camera.onFrameUpdate = { pixelBuffer in
            renderer.currentPixelBuffer = pixelBuffer
            // Pastikan draw dipanggil di main thread untuk sync layar
            DispatchQueue.main.async {
                mtkView.setNeedsDisplay()
            }
        }
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Handle rotasi untuk MTKView
        DispatchQueue.main.async {
            uiView.frame = UIScreen.main.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var renderer: LogPreviewRenderer?
    }
}
