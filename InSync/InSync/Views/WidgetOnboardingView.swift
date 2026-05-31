import SwiftUI

struct WidgetOnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var isSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Add InSync to your desktop")
                    .font(.largeTitle.weight(.bold))

                Text("Your person’s latest drawing will show there.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                InstructionRow(number: 1, text: "Right-click your desktop.")
                InstructionRow(number: 2, text: "Choose Edit Widgets.")
                InstructionRow(number: 3, text: "Search for InSync.")
                InstructionRow(number: 4, text: "Drag the widget onto your desktop.")
            }

            Spacer()

            Button {
                if isSheet {
                    dismiss()
                } else {
                    appState.markWidgetOnboardingSeen()
                }
            } label: {
                Label("I added the widget", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(InSyncPrimaryButtonStyle())

            if !isSheet {
                Button("Continue without it") {
                    appState.markWidgetOnboardingSeen()
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.secondary)
            }
        }
        .padding(44)
        .background(Color.insyncBackground)
    }
}

private struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(Color.insyncInk)
                .frame(width: 30, height: 30)
                .background(Color.insyncSoftPink, in: Circle())

            Text(text)
                .font(.title3)
        }
    }
}

