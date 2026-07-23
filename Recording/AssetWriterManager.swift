import AVFoundation
import VideoToolbox

class AssetWriterManager {
    var writer: AVAssetWriter?
    var videoInput: AVAssetWriterInput?
    var audioInput: AVAssetWriterInput?
    var isWriting = false
    var hasStartedSession = false

    func setupAssetWriter(outputURL: URL, width: Int, height: Int) throws {
        writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        hasStartedSession = false

        // Video Settings
        let vSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.hevc,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 150_000_000,
                AVVideoProfileLevelKey: kVTProfileLevel_HEVC_Main10_AutoLevel
            ]
        ]
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: vSettings)
        videoInput?.expectsMediaDataInRealTime = true
        if let vi = videoInput, writer!.canAdd(vi) { writer!.add(vi) }

        // Audio Settings
        var acl = AudioChannelLayout()
        memset(&acl, 0, MemoryLayout<AudioChannelLayout>.size)
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo
        let aSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: 128000,
            AVChannelLayoutKey: Data(bytes: &acl, count: MemoryLayout<AudioChannelLayout>.size)
        ]
        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: aSettings)
        audioInput?.expectsMediaDataInRealTime = true
        if let ai = audioInput, writer!.canAdd(ai) { writer!.add(ai) }

        isWriting = true
    }

    func write(sampleBuffer: CMSampleBuffer, isVideo: Bool) {
        guard isWriting, let writer = writer else { return }
        
        if writer.status == .unknown && isVideo {
            writer.startWriting()
            writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            hasStartedSession = true
        }
        
        guard hasStartedSession, writer.status == .writing else { return }
        
        let input = isVideo ? videoInput : audioInput
        if input?.isReadyForMoreMediaData == true {
            input?.append(sampleBuffer)
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        isWriting = false
        guard let writer = writer, writer.status == .writing else {
            completion(nil)
            return
        }
        
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()
        let url = writer.outputURL
        writer.finishWriting {
            self.writer = nil
            self.videoInput = nil
            self.audioInput = nil
            completion(url)
        }
    }
}
