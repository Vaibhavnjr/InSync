import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("InSync")
                .font(.title.weight(.bold))

            if let pairCode = appState.pairCode {
                LabeledContent("Pair code", value: pairCode)
            }

            Button {
                appState.showWidgetOnboarding()
            } label: {
                Label("Widget instructions", systemImage: "rectangle.on.rectangle")
            }
            .buttonStyle(InSyncSecondaryButtonStyle())
        }
        .padding(28)
    }
}

