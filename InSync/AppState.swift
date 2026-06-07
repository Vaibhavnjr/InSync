import Foundation
import WidgetKit

enum AppRoute: Equatable {
    case welcome
    case createPair
    case joinPair
    case widgetOnboarding
    case drawing
}

@MainActor
final class AppState: ObservableObject {
    @Published var route: AppRoute = .welcome
    @Published var userId: String?
    @Published var pairCode: String?
    @Published var role: AppRole?
    @Published var isPaired = false
    @Published var hasSeenWidgetOnboarding = false
    @Published var statusMessage: String?
    @Published var errorMessage: String?
    @Published var latestReceivedAt: Date?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        startFrontendOnlySession()
    }

    func handleDeepLink(_ url: URL) {
        guard url.scheme == "insync" else { return }

        route = .drawing
    }

    func goHome() {
        route = .drawing
    }

    func chooseCreatePair() {
        errorMessage = nil
        statusMessage = "Frontend-only mode."
        route = .drawing
    }

    func chooseJoinPair() {
        errorMessage = nil
        statusMessage = "Frontend-only mode."
        route = .drawing
    }

    func showWidgetOnboarding() {
        route = .drawing
    }

    func markWidgetOnboardingSeen() {
        hasSeenWidgetOnboarding = true
        defaults.set(true, forKey: DefaultsKey.hasSeenWidgetOnboarding)
        route = .drawing
    }

    func createPairIfNeeded() async {
        startFrontendOnlySession(status: "Frontend-only mode.")
    }

    func pollForConnection() async {
        startFrontendOnlySession(status: "Ready to draw.")
    }

    func joinPair(code: String) async {
        startFrontendOnlySession(status: "Frontend-only mode.")
    }

    func sendDrawing(pngData: Data) async {
        do {
            errorMessage = nil
            statusMessage = "Saving..."
            let updatedAt = Date()
            try WidgetStorageService.shared.savePartnerDrawing(
                data: pngData,
                updatedAt: updatedAt,
                partnerLabel: "latest drawing"
            )
            latestReceivedAt = updatedAt
            WidgetCenter.shared.reloadAllTimelines()
            statusMessage = "Saved to widget."
        } catch {
            errorMessage = "Couldn’t save to widget."
            statusMessage = nil
        }
    }

    func refreshPartnerDrawing() async {
        errorMessage = nil
        statusMessage = "Drawing board is local only."
    }

    private func startFrontendOnlySession(status: String? = nil) {
        userId = "frontend-local-user"
        pairCode = "LOCAL"
        role = .userA
        isPaired = true
        hasSeenWidgetOnboarding = true
        route = .drawing
        statusMessage = status
        errorMessage = nil
        saveLocalState()
    }

    private func markConnected(pairCode: String, role: AppRole, userId: String) {
        self.pairCode = pairCode
        self.role = role
        self.userId = userId
        self.isPaired = true
        saveLocalState()
        statusMessage = "Connected."
        route = hasSeenWidgetOnboarding ? .drawing : .widgetOnboarding
    }

    private func loadLocalState() {
        userId = defaults.string(forKey: DefaultsKey.userId)
        pairCode = defaults.string(forKey: DefaultsKey.pairCode)

        if let roleRawValue = defaults.string(forKey: DefaultsKey.role) {
            role = AppRole(rawValue: roleRawValue)
        }

        isPaired = defaults.bool(forKey: DefaultsKey.isPaired)
        hasSeenWidgetOnboarding = defaults.bool(forKey: DefaultsKey.hasSeenWidgetOnboarding)
    }

    private func saveLocalState() {
        defaults.set(userId, forKey: DefaultsKey.userId)
        defaults.set(pairCode, forKey: DefaultsKey.pairCode)
        defaults.set(role?.rawValue, forKey: DefaultsKey.role)
        defaults.set(isPaired, forKey: DefaultsKey.isPaired)
        defaults.set(hasSeenWidgetOnboarding, forKey: DefaultsKey.hasSeenWidgetOnboarding)
    }

    private func initialRoute() -> AppRoute {
        return .drawing
    }
}

private enum DefaultsKey {
    static let userId = "userId"
    static let pairCode = "pairCode"
    static let role = "role"
    static let isPaired = "isPaired"
    static let hasSeenWidgetOnboarding = "hasSeenWidgetOnboarding"
}
