import SwiftUI

struct ContentView: View {
    @StateObject var camera = CameraController()
    
    var body: some View {
        ZStack {
            if camera.isRunning {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
                Text("Memuat Kamera...")
                    .foregroundColor(.white)
            }
        }
    }
}
