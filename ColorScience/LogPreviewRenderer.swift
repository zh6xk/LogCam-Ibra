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
        
        let renderPassDescriptor = view.currentRenderPassDescriptor
        if let rpd = renderPassDescriptor, let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
            encoder.endEncoding()
        }
        
        if let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
            // Karena orientasi asli kamera (portrait) adalah landscape_right di level sensor (1920x1080),
            // ukuran drawable MTKView (1080x1920) nggak sama dimensinya dengan cameraTexture, 
            // sehingga Blit command 'copy' memotong sisa texture jadi hitam di sisi kanan 
            // karena max size yang dicopy ngikut min(width) dan min(height).
            
            // Kita hitung titik aman untuk origin copy agar di-center dari buffer asli
            let texW = cameraTexture.width
            let texH = cameraTexture.height
            let drawW = drawable.texture.width
            let drawH = drawable.texture.height
            
            let sourceSize = MTLSizeMake(min(texW, drawW), min(texH, drawH), 1)
            
            // Offset source kalau texture kamera lebih gede
            let sourceX = max(0, (texW - sourceSize.width) / 2)
            let sourceY = max(0, (texH - sourceSize.height) / 2)
            
            // Offset destination kalau drawable lebih gede
            let destX = max(0, (drawW - sourceSize.width) / 2)
            let destY = max(0, (drawH - sourceSize.height) / 2)
            
            blitEncoder.copy(from: cameraTexture,
                             sourceSlice: 0,
                             sourceLevel: 0,
                             sourceOrigin: MTLOriginMake(sourceX, sourceY, 0),
                             sourceSize: sourceSize,
                             to: drawable.texture,
                             destinationSlice: 0,
                             destinationLevel: 0,
                             destinationOrigin: MTLOriginMake(destX, destY, 0))
            blitEncoder.endEncoding()
        }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
