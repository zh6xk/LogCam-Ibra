import SwiftUI

struct ContentView: View {
    @StateObject var camera = CameraController()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if camera.isRunning {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
                
                // Rotasi UI supaya tombol gak nyangkut di tengah pas landscape
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ControlPanelView()
                            .padding(.bottom, 20)
                        Spacer()
                    }
                    
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
