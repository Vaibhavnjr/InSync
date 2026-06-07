import AppKit
import SwiftUI

struct CreatePairCodeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            VStack(spacing: 12) {
                Text("Your pair code")
                    .font(.title2.weight(.semibold))

                Text(appState.pairCode ?? "----")
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .padding(.vertical, 8)

                Text("Ask your person to enter this code in InSync.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            if let pairCode = appState.pairCode {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(pairCode, forType: .string)
                    appState.statusMessage = "Copied."
                } label: {
                    Label("Copy Code", systemImage: "doc.on.doc")
                }
                .buttonStyle(InSyncSecondaryButtonStyle())
            }

            StatusTextView()

            Button("Back") {
                appState.route = .welcome
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(48)
        .task {
            await appState.createPairIfNeeded()
            await appState.pollForConnection()
        }
    }
}

