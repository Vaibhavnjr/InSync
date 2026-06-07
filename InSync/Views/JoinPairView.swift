import SwiftUI

struct JoinPairView: View {
    @EnvironmentObject private var appState: AppState
    @State private var code = ""
    @FocusState private var codeFocused: Bool

    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            Text("Enter their code")
                .font(.title2.weight(.semibold))

            TextField("LOVE-4821", text: $code)
                .textFieldStyle(.plain)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .textCase(.uppercase)
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
                .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .frame(width: 320)
                .focused($codeFocused)
                .onSubmit {
                    Task { await join() }
                }

            Button {
                Task { await join() }
            } label: {
                Label("Join", systemImage: "heart.fill")
                    .frame(width: 180)
            }
            .buttonStyle(InSyncPrimaryButtonStyle())
            .disabled(normalizedCode.isEmpty)

            StatusTextView()

            Button("Back") {
                appState.route = .welcome
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(48)
        .onAppear {
            codeFocused = true
        }
    }

    private var normalizedCode: String {
        PairCodeFormatter.normalize(code)
    }

    private func join() async {
        await appState.joinPair(code: normalizedCode)
    }
}

