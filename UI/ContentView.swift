import SwiftUI

struct ContentView: View {
    @StateObject var camera = CameraController()
    
    // Status UI
    @State private var isPortrait: Bool = UIDevice.current.orientation.isPortrait || UIDevice.current.orientation == .unknown
    @State private var uiRotation: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if camera.isRunning {
                    // LAYAR PREVIEW: 
                    // Pakai fill screen agar center, dipotong di bawah oleh panel hitam
                    CameraPreviewView(renderer: camera.previewRenderer)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea(.all)
                    
                    // UI KONTROL (Mulai dari basic: Tombol Shutter Saja di layar bersih)
                    // Posisinya merespon Portrait / Landscape secara eksplisit
                    if isPortrait {
                        VStack {
                            Spacer()
                            
                            // Kotak hitam di bawah untuk menu/shutter
                            ZStack {
                                Color.black
                                
                                HStack {
                                    Spacer()
                                    // Tombol Shutter (Basic)
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
                                }
                            }
                            .frame(height: 120) // Tinggi area hitam bawah
                            .ignoresSafeArea(edges: .bottom)
                        }
                    } else {
                        // Landscape Layout
                        HStack {
                            Spacer()
                            
                            // Kotak hitam di kanan untuk menu/shutter
                            ZStack {
                                Color.black
                                
                                VStack {
                                    Spacer()
                                    // Tombol Shutter (Basic)
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
                                    .padding(.bottom, 20)
                                }
                            }
                            .frame(width: 120) // Lebar area hitam kanan
                            .ignoresSafeArea(edges: .trailing)
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
