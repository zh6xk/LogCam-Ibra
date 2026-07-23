import SwiftUI

struct ContentView: View {
    @StateObject var camera = CameraController()
    
    // Simpan sudut rotasi UI untuk muter tombol secara animasi
    @State private var uiRotation: Double = 0
    @State private var isPortrait: Bool = UIDevice.current.orientation.isPortrait || UIDevice.current.orientation == .unknown
    
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
                    
                    // UI Overlay (Layout Landscape vs Portrait)
                    if isPortrait {
                        // PORTRAIT LAYOUT
                        VStack {
                            Spacer()
                            
                            // Baris Pengaturan Atas Tombol Rekam
                            HStack {
                                // Teks Resolusi / Codec
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("24FPS")
                                    Text("HEVC 420 10-bit")
                                    Text("Apple Log")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Zoom Lenses
                                HStack(spacing: 15) {
                                    Text("0.5")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("1")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.orange)
                                        .padding(8)
                                        .overlay(Circle().stroke(Color.orange, lineWidth: 1))
                                    Text("3")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Menu Icons Kanan
                                HStack(spacing: 20) {
                                    Image(systemName: "slider.horizontal.3")
                                    Image(systemName: "drop.fill")
                                    Image(systemName: "scope")
                                    Image(systemName: "sun.max.fill")
                                }
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                            }
                            .padding(.horizontal, 30)
                            .padding(.bottom, 20)
                            
                            // Baris Paling Bawah (Settings, Shutter, Flip)
                            HStack {
                                // Teks Status
                                Text("Ready")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Record Button (Tengah)
                                Button(action: {
                                    camera.toggleRecording()
                                }) {
                                    Circle()
                                        .fill(camera.isRecording ? Color.red : Color.clear)
                                        .frame(width: 65, height: 65)
                                        .overlay(
                                            Circle().stroke(Color.white, lineWidth: 3)
                                        )
                                        .padding(4)
                                        .overlay(
                                            Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                        )
                                }
                                
                                Spacer()
                                
                                // Flip Camera (Kanan)
                                Button(action: {
                                    // Action flip
                                }) {
                                    Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.bottom, 30)
                        }
                    } else {
                        // LANDSCAPE LAYOUT
                        HStack {
                            // Sisi Kiri (bawah HP) -> Resolusi, FPS
                            VStack {
                                Spacer()
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("24FPS")
                                    Text("HEVC 420 10-bit")
                                    Text("Apple Log")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(uiRotation))
                                .padding(.leading, 30)
                                .padding(.bottom, 40)
                            }
                            
                            Spacer()
                            
                            // Tengah (Zoom Lenses)
                            VStack {
                                Spacer()
                                HStack(spacing: 15) {
                                    Text("0.5")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("1")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.orange)
                                        .padding(8)
                                        .overlay(Circle().stroke(Color.orange, lineWidth: 1))
                                    Text("3")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(uiRotation))
                                .padding(.bottom, 30)
                            }
                            
                            Spacer()
                            
                            // Sisi Kanan (atas HP) -> Shutter Button & Tools
                            VStack {
                                HStack(spacing: 20) {
                                    Image(systemName: "slider.horizontal.3")
                                    Image(systemName: "drop.fill")
                                    Image(systemName: "scope")
                                    Image(systemName: "sun.max.fill")
                                }
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(uiRotation))
                                .padding(.top, 40)
                                
                                Spacer()
                                
                                Button(action: {
                                    camera.toggleRecording()
                                }) {
                                    Circle()
                                        .fill(camera.isRecording ? Color.red : Color.clear)
                                        .frame(width: 65, height: 65)
                                        .overlay(
                                            Circle().stroke(Color.white, lineWidth: 3)
                                        )
                                        .padding(4)
                                        .overlay(
                                            Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                        )
                                }
                                .padding(.bottom, 40)
                            }
                            .padding(.trailing, 30)
                        }
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
        }
        .ignoresSafeArea(.all)
        .onAppear {
            camera.start()
            // Pasangkan notifikasi rotasi untuk mutar UI secara halus
            NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    let orientation = UIDevice.current.orientation
                    self.isPortrait = orientation.isPortrait || orientation == .unknown
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
