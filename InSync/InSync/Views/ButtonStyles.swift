import SwiftUI

struct InSyncPrimaryButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 22 : 18, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 24 : 24)
            .padding(.vertical, compact ? 15 : 13)
            .frame(minWidth: compact ? 136 : 0, minHeight: compact ? 60 : 0)
            .background(Color.insyncInk.opacity(configuration.isPressed ? 0.84 : 1), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.insyncSoftPink.opacity(0.28), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct InSyncSecondaryButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.insyncInk)
            .padding(.horizontal, compact ? 16 : 20)
            .padding(.vertical, compact ? 10 : 13)
            .background(Color.white.opacity(configuration.isPressed ? 0.65 : 0.9), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.07), lineWidth: 1)
            )
    }
}

struct ToolButtonStyle: ButtonStyle {
    var isSelected = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 25, weight: .regular))
            .foregroundStyle(Color.insyncInk)
            .frame(width: 62, height: 62)
            .background(background(configuration), in: Circle())
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.insyncInk : Color.black.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }

    private func background(_ configuration: Configuration) -> Color {
        if isSelected {
            return Color.white.opacity(configuration.isPressed ? 0.74 : 0.96)
        }

        return Color.white.opacity(configuration.isPressed ? 0.68 : 0.9)
    }
}
