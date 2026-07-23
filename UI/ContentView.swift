import SwiftUI

struct ContentView: View {
    @StateObject var camera = CameraController()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if camera.isRunning {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
                ControlPanelView()
                    .padding(.bottom, 120)
            } else {
                Color.black.ignoresSafeArea()
                Text("Memuat Kamera...")
                    .foregroundColor(.white)
            }
        }
    }
}
