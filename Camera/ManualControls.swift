import AVFoundation

extension CameraController {
    func setISO(_ iso: Float) throws {
        guard let device = videoDevice else { return }
        try device.lockForConfiguration()
        let clamped = min(max(iso, device.activeFormat.minISO), device.activeFormat.maxISO)
        device.setExposureModeCustom(duration: device.exposureDuration, iso: clamped, completionHandler: nil)
        device.unlockForConfiguration()
    }

    func setShutterSpeed(seconds: Double) throws {
        guard let device = videoDevice else { return }
        try device.lockForConfiguration()
        let duration = CMTimeMakeWithSeconds(seconds, preferredTimescale: 1_000_000)
        device.setExposureModeCustom(duration: duration, iso: device.iso, completionHandler: nil)
        device.unlockForConfiguration()
    }

    func setWhiteBalance(temperature: Float, tint: Float) throws {
        guard let device = videoDevice else { return }
        try device.lockForConfiguration()
        let gains = device.deviceWhiteBalanceGains(
            for: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: temperature, tint: tint)
        )
        device.setWhiteBalanceModeLocked(with: gains, completionHandler: nil)
        device.unlockForConfiguration()
    }

    func setFocus(lensPosition: Float) throws {
        guard let device = videoDevice else { return }
        try device.lockForConfiguration()
        device.setFocusModeLocked(lensPosition: lensPosition, completionHandler: nil)
        device.unlockForConfiguration()
    }
}
