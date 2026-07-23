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
                
                Button("Minta Izin Kamera") {
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        DispatchQueue.main.async {
                            cameraStatus = granted ? "Izin Diberikan. Coba Buka Kamera." : "Izin Ditolak"
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
