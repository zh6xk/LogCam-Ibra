import Metal
import CoreVideo

class MetalContext {
    static let shared = MetalContext()
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLComputePipelineState?
    var textureCache: CVMetalTextureCache?
    var pixelBufferPool: CVPixelBufferPool?
    var poolWidth: Int = 0
    var poolHeight: Int = 0

    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal tidak didukung di perangkat ini.")
        }
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        
        guard let library = device.makeDefaultLibrary(),
              let function = library.makeFunction(name: "sLog3Encode") else {
            print("Gagal load Metal shader sLog3Encode")
            return
        }
        
        self.pipelineState = try? device.makeComputePipelineState(function: function)
    }
    
    func applyLogShader(to inputPixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard let pipelineState = pipelineState,
              let textureCache = textureCache else { return nil }
        
        let width = CVPixelBufferGetWidth(inputPixelBuffer)
        let height = CVPixelBufferGetHeight(inputPixelBuffer)
        
        // Buat atau re-create pool jika dimensi berubah
        if pixelBufferPool == nil || poolWidth != width || poolHeight != height {
            let poolAttributes: [String: Any] = [
                kCVPixelBufferPoolMinimumBufferCountKey as String: 3
            ]
            let bufferAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
                kCVPixelBufferIOSurfacePropertiesKey as String: [:]
            ]
            CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as CFDictionary, bufferAttributes as CFDictionary, &pixelBufferPool)
            poolWidth = width
            poolHeight = height
        }
        
        guard let pool = pixelBufferPool else { return nil }
        var outputPixelBufferOut: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &outputPixelBufferOut)
        guard let outputPixelBuffer = outputPixelBufferOut else {
            print("Warning: Gagal alokasi buffer dari pool, skip frame")
            return nil
        }
        
        var cvTextureIn: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault, textureCache, inputPixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTextureIn
        )
        
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault, textureCache, outputPixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTextureOut
        )
        
        guard let inTex = cvTextureIn, let inTexture = CVMetalTextureGetTexture(inTex),
              let outTex = cvTextureOut, let outTexture = CVMetalTextureGetTexture(outTex) else { return nil }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return nil }
        
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(inTexture, index: 0)
        encoder.setTexture(outTexture, index: 1)
        
        let threadGroupSize = MTLSize(width: 8, height: 8, depth: 1)
        let threadGroups = MTLSize(
            width: (width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )
        
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return outputPixelBuffer
    }
}
