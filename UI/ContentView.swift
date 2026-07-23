import SwiftUI
import AVFoundation

struct ContentView: View {
    @State var cameraStatus: String = "Menunggu Izin..."
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Text(cameraStatus)
                    .foregroundColor(.white)
                    .padding()
                
                Button("Cek Status Izin") {
                    let status = AVCaptureDevice.authorizationStatus(for: .video)
                    switch status {
                    case .authorized:
                        cameraStatus = "Status: Sudah Diizinkan"
                    case .denied:
                        cameraStatus = "Status: Ditolak (Cek Settings)"
                    case .notDetermined:
                        cameraStatus = "Status: Belum Diminta"
                    case .restricted:
                        cameraStatus = "Status: Restricted"
                    @unknown default:
                        cameraStatus = "Status: Unknown"
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Minta Izin Kamera") {
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        DispatchQueue.main.async {
                            cameraStatus = granted ? "Izin Diberikan." : "Izin Ditolak"
                        }
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
}
