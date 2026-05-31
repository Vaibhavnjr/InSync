import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Text("InSync")
                    .font(.system(size: 58, weight: .bold, design: .rounded))

                Text("Draw tiny messages for someone close.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                Button {
                    appState.chooseCreatePair()
                } label: {
                    Label("Create Pair Code", systemImage: "link.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(InSyncPrimaryButtonStyle())

                Button {
                    appState.chooseJoinPair()
                } label: {
                    Label("Join Someone", systemImage: "heart")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(InSyncSecondaryButtonStyle())
            }
            .frame(width: 280)

            Spacer()
        }
        .padding(48)
    }
}

