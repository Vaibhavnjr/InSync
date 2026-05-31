import Foundation

enum InSyncError: LocalizedError {
    case firebaseNotConfigured
    case notAuthenticated
    case codeNotFound
    case pairAlreadyUsed
    case invalidPair
    case noPartnerDrawing
    case appGroupUnavailable

    var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            return "Add GoogleService-Info.plist to finish Firebase setup."
        case .notAuthenticated:
            return "Couldn’t start your anonymous session."
        case .codeNotFound:
            return "Couldn’t find that code."
        case .pairAlreadyUsed:
            return "This code has already been used."
        case .invalidPair:
            return "Something went wrong. Try again."
        case .noPartnerDrawing:
            return "Nothing from your person yet."
        case .appGroupUnavailable:
            return "App Group storage is not available yet."
        }
    }
}

