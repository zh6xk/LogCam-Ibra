import SwiftUI

struct ContentView: View {
    @StateObject var camera = CameraController()
    
    // Simpan sudut rotasi UI untuk muter tombol secara animasi
    @State private var uiRotation: Double = 0
    
    // 1. Tambahkan state untuk orientasi UI
    @State private var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if camera.isRunning {
                    // Kamera 100% full screen
                    CameraPreviewView(session: camera.session)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea(.all)
                    
                    // UI Overlay
                    VStack {
                        Spacer()
                    
                    // Box indikator (ISO dkk) yang tadinya horizontal, sekarang disusun vertikal
                    VStack(spacing: 10) {
                        Text("ISO")
                        Text("Shutter")
                        Text("WB")
                        Text("Focus")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    .padding(.bottom, 20)
                    .rotationEffect(.degrees(uiRotation)) // Puter Box-nya
                    
                    // Tombol Rekam
                    Button(action: {
                        camera.toggleRecording()
                    }) {
                        Circle()
                            .fill(camera.isRecording ? Color.red : Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle().stroke(Color.black.opacity(0.3), lineWidth: 2)
                            )
                    }
                    .padding(.bottom, 40)
                    // (Tombol bulat nggak usah diputar karena bentuknya lingkaran, tetep sama diliat dari mana aja)
                }
            } else {
                Color.black.ignoresSafeArea()
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Memuat Kamera...")
                        .foregroundColor(.white)
                        .padding(.top, 10)
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            camera.start()
            // Pasangkan notifikasi rotasi untuk mutar UI secara halus
            NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    let orientation = UIDevice.current.orientation
                    switch orientation {
                    case .landscapeLeft:
                        self.uiRotation = 90
                    case .landscapeRight:
                        self.uiRotation = -90
                    case .portraitUpsideDown:
                        self.uiRotation = 180
                    case .portrait:
                        self.uiRotation = 0
                    default:
                        break
                    }
                }
            }
        }
    }
}
