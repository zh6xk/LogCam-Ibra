import AVFoundation

struct MetadataTagger {
    static let colorProperties: [String: Any] = [
        AVVideoColorPrimariesKey: AVVideoColorPrimaries_P3_D65,
        AVVideoTransferFunctionKey: "S-Log3",
        AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
    ]
}
