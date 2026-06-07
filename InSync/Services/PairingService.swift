import Foundation

final class PairingService {
    static let shared = PairingService()

    private init() {}

    func createPair() async throws -> Pair {
        try await FirebaseService.shared.createPair()
    }

    func joinPair(code: String) async throws -> Pair {
        try await FirebaseService.shared.joinPair(code: code)
    }

    func fetchPair(pairCode: String) async throws -> Pair {
        try await FirebaseService.shared.fetchPair(pairCode: pairCode)
    }
}

