import Foundation

enum PairStatus: String {
    case waiting
    case connected
    case disconnected
}

enum AppRole: String, Codable {
    case userA
    case userB

    var latestFieldName: String {
        switch self {
        case .userA:
            return "latestByUserA"
        case .userB:
            return "latestByUserB"
        }
    }

    var partnerLatestFieldName: String {
        switch self {
        case .userA:
            return "latestByUserB"
        case .userB:
            return "latestByUserA"
        }
    }
}

struct Pair: Equatable {
    let pairCode: String
    let createdBy: String
    let userA: String
    let userB: String?
    let status: PairStatus
    let latestByUserA: DrawingMetadata?
    let latestByUserB: DrawingMetadata?

    var isConnected: Bool {
        status == .connected && userB?.isEmpty == false
    }

    func latestDrawing(for role: AppRole) -> DrawingMetadata? {
        switch role {
        case .userA:
            return latestByUserA
        case .userB:
            return latestByUserB
        }
    }

    func latestPartnerDrawing(for role: AppRole) -> DrawingMetadata? {
        switch role {
        case .userA:
            return latestByUserB
        case .userB:
            return latestByUserA
        }
    }
}

