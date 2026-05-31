import Foundation

final class DrawingService {
    static let shared = DrawingService()

    private init() {}

    func sendDrawing(pngData: Data, pairCode: String, role: AppRole) async throws {
        try await FirebaseService.shared.sendDrawing(
            pngData: pngData,
            pairCode: pairCode,
            role: role
        )
    }

    func refreshPartnerDrawing(pairCode: String, role: AppRole) async throws -> Date {
        try await FirebaseService.shared.refreshPartnerDrawing(pairCode: pairCode, role: role)
    }
}

