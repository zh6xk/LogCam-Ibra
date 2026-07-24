import SwiftUI

struct ContentView: View {
    @StateObject var camera = CameraController()
    
    // Status UI
    @State private var isPortrait: Bool = UIDevice.current.orientation.isPortrait || UIDevice.current.orientation == .unknown
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if camera.isRunning {
                    // LAYAR PREVIEW: 
                    // Pakai full screen agar center tanpa kepotong/offset
                    CameraPreviewView(renderer: camera.previewRenderer)
                        // Paksa frame sesuai geometry pembungkus terluar layar (ignoresSafeArea)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2) // Kunci di center murni
                        .ignoresSafeArea(.all)
                    
                    // UI KONTROL (Tombol Shutter Saja di layar bersih, TANPA PANEL HITAM)
                    if isPortrait {
                        VStack {
                            Spacer()
                            
                            // Tombol Shutter Mengambang di Bawah
                            Button(action: {
                                camera.toggleRecording()
                            }) {
                                Circle()
                                    // Putih saat idle, Merah saat record
                                    .fill(camera.isRecording ? Color.red : Color.white)
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
                    } else {
                        // Landscape Layout
                        HStack {
                            Spacer()
                            
                            // Tombol Shutter Mengambang di Kanan
                            Button(action: {
                                camera.toggleRecording()
                            }) {
                                Circle()
                                    // Putih saat idle, Merah saat record
                                    .fill(camera.isRecording ? Color.red : Color.white)
                                    .frame(width: 65, height: 65)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: 3)
                                    )
                                    .padding(4)
                                    .overlay(
                                        Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    )
                            }
                            .padding(.trailing, 40)
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
            // Notifikasi rotasi
            NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    let orientation = UIDevice.current.orientation
                    self.isPortrait = orientation.isPortrait || orientation == .unknown
                }
            }
        }
    }
}
