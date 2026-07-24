import SwiftUI
import MetalKit
import CoreVideo

class LogPreviewRenderer: NSObject, ObservableObject, MTKViewDelegate {
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue?
    var textureCache: CVMetalTextureCache?
    
    var currentPixelBuffer: CVPixelBuffer?
    private let queue = DispatchQueue(label: "log.preview.queue")

    override init() {
        super.init()
        self.device = MTLCreateSystemDefaultDevice()
        self.commandQueue = device?.makeCommandQueue()
        if let device = device {
            CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        }
    }
    
    func update(with pixelBuffer: CVPixelBuffer) {
        queue.async { [weak self] in
            self?.currentPixelBuffer = pixelBuffer
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let pixelBuffer = currentPixelBuffer,
              let textureCache = textureCache,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue?.makeCommandBuffer() else {
            return
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &cvTextureOut
        )
        
        guard let cvTex = cvTextureOut, let cameraTexture = CVMetalTextureGetTexture(cvTex) else { return }
        
        // Pass to drawable (Simple passthrough render)
        let renderPassDescriptor = view.currentRenderPassDescriptor
        if let rpd = renderPassDescriptor, let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
            // Karena ini MTKView biasa, kita bisa pakai MPSImageCopy kalau ada MetalPerformanceShaders, 
            // tapi yang paling gampang adalah gambar pakai compute shader sederhana (atau langsung copy)
            // Di sini kita delegate copy manual atau blit
            encoder.endEncoding()
        }
        
        // Blit dari Texture Kamera ke Drawable
        if let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
            blitEncoder.copy(from: cameraTexture,
                             sourceSlice: 0,
                             sourceLevel: 0,
                             sourceOrigin: MTLOriginMake(0, 0, 0),
                             sourceSize: MTLSizeMake(min(cameraTexture.width, drawable.texture.width), 
                                                   min(cameraTexture.height, drawable.texture.height), 1),
                             to: drawable.texture,
                             destinationSlice: 0,
                             destinationLevel: 0,
                             destinationOrigin: MTLOriginMake(0, 0, 0))
            blitEncoder.endEncoding()
        }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
