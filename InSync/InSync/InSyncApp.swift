import SwiftUI
import AppKit

@main
struct InSyncApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .background(ProportionalWindowConfigurator())
                .frame(
                    minWidth: InSyncWindowMetrics.minWidth,
                    idealWidth: InSyncWindowMetrics.idealWidth,
                    minHeight: InSyncWindowMetrics.minHeight,
                    idealHeight: InSyncWindowMetrics.idealHeight
                )
                .onOpenURL { url in
                    appState.handleDeepLink(url)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

private enum InSyncWindowMetrics {
    static let minWidth: CGFloat = 591
    static let minHeight: CGFloat = 675
    static let idealWidth: CGFloat = 591
    static let idealHeight: CGFloat = 675
    static let horizontalPadding: CGFloat = 16
    static let topPadding: CGFloat = 28
    static let bottomPadding: CGFloat = 28
    static let scalableContentWidth: CGFloat = 559
    static let scalableContentHeight: CGFloat = 619

    static func normalizedContentSize(for proposedSize: NSSize) -> NSSize {
        let availableWidth = max(scalableContentWidth, proposedSize.width - horizontalPadding * 2)
        let availableHeight = max(scalableContentHeight, proposedSize.height - topPadding - bottomPadding)
        let scale = max(1, min(availableWidth / scalableContentWidth, availableHeight / scalableContentHeight))

        return NSSize(
            width: scalableContentWidth * scale + horizontalPadding * 2,
            height: scalableContentHeight * scale + topPadding + bottomPadding
        )
    }
}

private struct ProportionalWindowConfigurator: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(view.window, coordinator: context.coordinator)
        }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(view.window, coordinator: context.coordinator)
        }
    }

    private func configure(_ window: NSWindow?, coordinator: Coordinator) {
        guard let window else { return }

        if coordinator.window !== window {
            coordinator.window = window
            coordinator.didNormalizeSize = false
        }

        window.contentMinSize = NSSize(width: InSyncWindowMetrics.minWidth, height: InSyncWindowMetrics.minHeight)
        window.delegate = coordinator
        window.title = Constants.appName
        window.titleVisibility = .hidden

        guard !coordinator.didNormalizeSize else { return }
        coordinator.didNormalizeSize = true
        normalize(window)
    }

    private func normalize(_ window: NSWindow) {
        let visibleFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame
        let maxSize = NSSize(
            width: max(InSyncWindowMetrics.minWidth, (visibleFrame?.width ?? 1280) - 80),
            height: max(InSyncWindowMetrics.minHeight, (visibleFrame?.height ?? 980) - 80)
        )

        let proposedSize = NSSize(
            width: min(maxSize.width, InSyncWindowMetrics.idealWidth),
            height: min(maxSize.height, InSyncWindowMetrics.idealHeight)
        )
        let targetSize = InSyncWindowMetrics.normalizedContentSize(for: proposedSize)
        window.setContentSize(targetSize)
        window.center()
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        weak var window: NSWindow?
        var didNormalizeSize = false

        func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
            let proposedContentRect = sender.contentRect(
                forFrameRect: NSRect(origin: .zero, size: frameSize)
            )
            let normalizedContentSize = InSyncWindowMetrics.normalizedContentSize(
                for: proposedContentRect.size
            )
            let normalizedFrameRect = sender.frameRect(
                forContentRect: NSRect(origin: .zero, size: normalizedContentSize)
            )

            return normalizedFrameRect.size
        }
    }
}
