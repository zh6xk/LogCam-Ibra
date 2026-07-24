import Metal
import CoreVideo

class MetalContext {
    static let shared = MetalContext()
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLComputePipelineState?
    var textureCache: CVMetalTextureCache?
    
    // Pixel Buffer Pool untuk Output (mencegah in-place read/write dan memori leak)
    private var pixelBufferPool: CVPixelBufferPool?
    private var poolWidth: Int = 0
    private var poolHeight: Int = 0

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
    
    private func setupPixelBufferPool(width: Int, height: Int) {
        if pixelBufferPool != nil && poolWidth == width && poolHeight == height { return }
        
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
    
    func applyLogShader(to inputPixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard let pipelineState = pipelineState,
              let textureCache = textureCache else { return nil }
        
        let width = CVPixelBufferGetWidth(inputPixelBuffer)
        let height = CVPixelBufferGetHeight(inputPixelBuffer)
        
        // Pastikan pool siap
        setupPixelBufferPool(width: width, height: height)
        
        guard let pool = pixelBufferPool else { return nil }
        
        // Alokasikan output buffer dari pool
        var outputPixelBufferOut: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &outputPixelBufferOut)
        
        guard status == kCVReturnSuccess, let outputPixelBuffer = outputPixelBufferOut else {
            print("Warning: Gagal alokasi CVPixelBuffer dari pool.")
            return nil
        }
        
        // Buat Texture Input
        var cvTextureIn: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            inputPixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &cvTextureIn
        )
        
        // Buat Texture Output
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            outputPixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &cvTextureOut
        )
        
        guard let cvTexIn = cvTextureIn, let inTexture = CVMetalTextureGetTexture(cvTexIn),
              let cvTexOut = cvTextureOut, let outTexture = CVMetalTextureGetTexture(cvTexOut) else {
            return nil
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return nil }
        
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(inTexture, index: 0) // Input
        encoder.setTexture(outTexture, index: 1) // Output
        
        let threadGroupSize = MTLSize(width: 8, height: 8, depth: 1)
        let threadGroups = MTLSize(
            width: (width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )
        
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted() // Tunggu rendering selesai
        
        return outputPixelBuffer
    }
}
