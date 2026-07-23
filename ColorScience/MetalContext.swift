import Metal
import CoreVideo

class MetalContext {
    static let shared = MetalContext()
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLComputePipelineState?
    var textureCache: CVMetalTextureCache?

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
    
    func applyLogShader(to pixelBuffer: CVPixelBuffer) {
        guard let pipelineState = pipelineState,
              let textureCache = textureCache else { return }
        
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
        
        guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else { return }
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(texture, index: 0) // Input
        encoder.setTexture(texture, index: 1) // Output (In-place)
        
        let threadGroupSize = MTLSize(width: 8, height: 8, depth: 1)
        let threadGroups = MTLSize(
            width: (width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )
        
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted() // Tunggu selesai supaya datanya fix sebelum direkam/dirender
    }
}
