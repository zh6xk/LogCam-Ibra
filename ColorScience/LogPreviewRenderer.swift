import MetalKit
import AVFoundation

class LogPreviewRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var textureCache: CVMetalTextureCache!
    var currentPixelBuffer: CVPixelBuffer?
    
    init(metalView: MTKView) {
        super.init()
        self.device = MetalContext.shared.device
        self.commandQueue = MetalContext.shared.commandQueue
        
        metalView.device = self.device
        metalView.framebufferOnly = false
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.delegate = self
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
    }
    
    func draw(in view: MTKView) {
        guard let pixelBuffer = currentPixelBuffer,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        var cvTexture: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault, textureCache, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTexture
        )
        
        guard let cvTex = cvTexture, let sourceTexture = CVMetalTextureGetTexture(cvTex) else { return }
        
        guard let encoder = commandBuffer.makeBlitCommandEncoder() else { return }
        let origin = MTLOrigin(x: 0, y: 0, z: 0)
        let size = MTLSize(width: min(sourceTexture.width, drawable.texture.width),
                           height: min(sourceTexture.height, drawable.texture.height),
                           depth: 1)
        
        encoder.copy(from: sourceTexture,
                     sourceSlice: 0,
                     sourceLevel: 0,
                     sourceOrigin: origin,
                     sourceSize: size,
                     to: drawable.texture,
                     destinationSlice: 0,
                     destinationLevel: 0,
                     destinationOrigin: origin)
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
