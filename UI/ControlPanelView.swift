import SwiftUI

struct ControlPanelView: View {
    var body: some View {
        VStack {
            Text("ISO | Shutter | WB | Focus")
                .font(.caption)
                .foregroundColor(.white)
                .padding()
        }
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)
    }
}
