import SwiftUI

struct ContentView: View {
    @StateObject var camera = CameraController()
    
    // Nangkep rotasi device untuk ngatur tombol
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape
    
    var body: some View {
        ZStack {
            if camera.isRunning {
                // Kamera jadi background full
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea(.all)
                
                // UI Overlay
                if isLandscape {
                    // Landscape: Tombol di kanan, teks di kiri bawah
                    HStack {
                        VStack {
                            Spacer()
                            ControlPanelView()
                                .padding(.bottom, 20)
                                .padding(.leading, 40)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Spacer()
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
                            .padding(.trailing, 40)
                            Spacer()
                        }
                    }
                } else {
                    // Portrait: Tombol di bawah tengah
                    VStack {
                        Spacer()
                        ControlPanelView()
                            .padding(.bottom, 20)
                        
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
        .onAppear {
            camera.start()
            // Pantau rotasi pas load
            NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
                let orientation = UIDevice.current.orientation
                if orientation.isLandscape || orientation.isPortrait {
                    self.isLandscape = orientation.isLandscape
                }
            }
        }
    }
}
