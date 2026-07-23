import AVFoundation
import VideoToolbox

class AssetWriterManager {
    var writer: AVAssetWriter?
    var input: AVAssetWriterInput?
    var isWriting = false

    func setupAssetWriter(outputURL: URL, width: Int, height: Int) throws {
        writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.hevc,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 150_000_000,
                AVVideoProfileLevelKey: kVTProfileLevel_HEVC_Main10_AutoLevel
            ]
        ]

        input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input?.expectsMediaDataInRealTime = true

        if let input = input, let writer = writer, writer.canAdd(input) {
            writer.add(input)
        }
        isWriting = true
    }

    func write(sampleBuffer: CMSampleBuffer) {
        guard isWriting, let writer = writer, let input = input else { return }
        
        if writer.status == .unknown {
            writer.startWriting()
            writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        }
        
        if writer.status == .writing && input.isReadyForMoreMediaData {
            input.append(sampleBuffer)
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        isWriting = false
        guard let writer = writer, writer.status == .writing else {
            completion(nil)
            return
        }
        
        input?.markAsFinished()
        let url = writer.outputURL
        writer.finishWriting {
            self.writer = nil
            self.input = nil
            completion(url)
        }
    }
}
