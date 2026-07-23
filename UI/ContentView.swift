import SwiftUI

struct ContentView: View {
    @StateObject var camera = CameraController()
    
    // Nangkep orientasi dari system supaya UI ganti layout otomatis
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var isLandscape: Bool {
        return verticalSizeClass == .compact
    }
    
    var body: some View {
        ZStack {
            if camera.isRunning {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
                
                if isLandscape {
                    // Tampilan Landscape: Tombol di Kanan, Info di Bawah Kiri
                    HStack {
                        VStack {
                            Spacer()
                            ControlPanelView()
                                .padding(.bottom, 20)
                                .padding(.leading, 20)
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
                    // Tampilan Portrait: Tombol di Bawah Tengah
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
        }
    }
}
