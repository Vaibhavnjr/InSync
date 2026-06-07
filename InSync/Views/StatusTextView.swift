import SwiftUI

struct StatusTextView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if let errorMessage = appState.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.08), in: Capsule())
            } else if let statusMessage = appState.statusMessage {
                Text(statusMessage)
                    .foregroundStyle(Color.insyncInk.opacity(0.48))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.42), in: Capsule())
            }
        }
        .font(.footnote.weight(.medium))
    }
}
