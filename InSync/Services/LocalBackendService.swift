import AppKit
import Foundation

final class LocalBackendService {
    static let shared = LocalBackendService()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    var currentUserId: String {
        if let existingUserId = defaults.string(forKey: DefaultsKey.localUserId) {
            return existingUserId
        }

        let newUserId = "local-\(UUID().uuidString)"
        defaults.set(newUserId, forKey: DefaultsKey.localUserId)
        return newUserId
    }

    func createPair() async throws -> Pair {
        var store = try loadStore()
        let userId = currentUserId

        for _ in 0..<24 {
            let pairCode = PairCodeFormatter.generate()
            guard store.pairs[pairCode] == nil else { continue }

            let record = LocalPairRecord(
                pairCode: pairCode,
                createdAt: Date().timeIntervalSince1970,
                createdBy: userId,
                userA: userId,
                userB: nil,
                status: PairStatus.waiting.rawValue,
                latestByUserA: nil,
                latestByUserB: nil
            )

            store.pairs[pairCode] = record
            try saveStore(store)
            return record.pair
        }

        throw InSyncError.invalidPair
    }

    func joinPair(code: String) async throws -> Pair {
        let pairCode = PairCodeFormatter.normalize(code)
        let userId = currentUserId
        var store = try loadStore()

        guard var record = store.pairs[pairCode] else {
            throw InSyncError.codeNotFound
        }

        if let userB = record.userB, !userB.isEmpty, userB != userId {
            throw InSyncError.pairAlreadyUsed
        }

        if record.userA == userId {
            record.userB = DefaultsKey.demoPartnerUserId
        } else {
            record.userB = userId
        }

        record.status = PairStatus.connected.rawValue
        try ensureDemoPartnerDrawing(for: &record)
        store.pairs[pairCode] = record
        try saveStore(store)

        return record.pair
    }

    func fetchPair(pairCode: String) async throws -> Pair {
        var store = try loadStore()

        guard var record = store.pairs[pairCode] else {
            throw InSyncError.codeNotFound
        }

        let shouldAutoConnect = record.status == PairStatus.waiting.rawValue
            && Date().timeIntervalSince1970 - record.createdAt > 1.2

        if shouldAutoConnect {
            record.userB = DefaultsKey.demoPartnerUserId
            record.status = PairStatus.connected.rawValue
            try ensureDemoPartnerDrawing(for: &record)
            store.pairs[pairCode] = record
            try saveStore(store)
        }

        return record.pair
    }

    func sendDrawing(pngData: Data, pairCode: String, role: AppRole) async throws {
        var store = try loadStore()

        guard var record = store.pairs[pairCode] else {
            throw InSyncError.codeNotFound
        }

        let userId: String
        switch role {
        case .userA:
            userId = record.userA
        case .userB:
            userId = record.userB ?? currentUserId
        }

        let imageURL = try drawingURL(pairCode: pairCode, userId: userId)
        try FileManager.default.createDirectory(at: imageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try pngData.write(to: imageURL, options: [.atomic])

        let metadata = LocalDrawingMetadata(
            imagePath: imageURL.path,
            updatedAt: Date().timeIntervalSince1970
        )

        switch role {
        case .userA:
            record.latestByUserA = metadata
        case .userB:
            record.latestByUserB = metadata
        }

        store.pairs[pairCode] = record
        try saveStore(store)
    }

    func refreshPartnerDrawing(pairCode: String, role: AppRole) async throws -> Date {
        let pair = try await fetchPair(pairCode: pairCode)

        guard let metadata = pair.latestPartnerDrawing(for: role),
              !metadata.isEmpty else {
            throw InSyncError.noPartnerDrawing
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: metadata.imagePath))
        try WidgetStorageService.shared.savePartnerDrawing(
            data: data,
            updatedAt: metadata.updatedAt,
            partnerLabel: "your person"
        )

        return metadata.updatedAt
    }

    private func ensureDemoPartnerDrawing(for record: inout LocalPairRecord) throws {
        guard record.latestByUserB == nil else { return }

        let partnerUserId = record.userB ?? DefaultsKey.demoPartnerUserId
        let imageURL = try drawingURL(pairCode: record.pairCode, userId: partnerUserId)
        try FileManager.default.createDirectory(at: imageURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        let data = try demoPartnerPNGData()
        try data.write(to: imageURL, options: [.atomic])

        record.latestByUserB = LocalDrawingMetadata(
            imagePath: imageURL.path,
            updatedAt: Date().timeIntervalSince1970
        )
    }

    private func demoPartnerPNGData() throws -> Data {
        let size = Constants.canvasSize
        let image = NSImage(size: size)

        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()

        NSColor(hex: "#FF6BAA").setStroke()
        let heart = NSBezierPath()
        heart.lineWidth = 9
        heart.lineCapStyle = .round
        heart.lineJoinStyle = .round
        heart.move(to: CGPoint(x: 142, y: 214))
        heart.curve(to: CGPoint(x: 256, y: 130), controlPoint1: CGPoint(x: 132, y: 145), controlPoint2: CGPoint(x: 230, y: 121))
        heart.curve(to: CGPoint(x: 370, y: 214), controlPoint1: CGPoint(x: 282, y: 121), controlPoint2: CGPoint(x: 380, y: 145))
        heart.curve(to: CGPoint(x: 256, y: 294), controlPoint1: CGPoint(x: 360, y: 276), controlPoint2: CGPoint(x: 282, y: 290))
        heart.curve(to: CGPoint(x: 142, y: 214), controlPoint1: CGPoint(x: 230, y: 290), controlPoint2: CGPoint(x: 152, y: 276))
        heart.stroke()

        let message = "hi :)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 42, weight: .bold),
            .foregroundColor: NSColor(hex: "#1F1F1F")
        ]
        message.draw(at: CGPoint(x: 214, y: 174), withAttributes: attributes)

        image.unlockFocus()

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw CanvasRendererError.couldNotCreatePNG
        }

        return pngData
    }

    private func loadStore() throws -> LocalStore {
        let url = try storeURL()

        guard let data = try? Data(contentsOf: url) else {
            return LocalStore()
        }

        return try decoder.decode(LocalStore.self, from: data)
    }

    private func saveStore(_ store: LocalStore) throws {
        let url = try storeURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try encoder.encode(store)
        try data.write(to: url, options: [.atomic])
    }

    private func storeURL() throws -> URL {
        try baseURL().appendingPathComponent("store.json")
    }

    private func drawingURL(pairCode: String, userId: String) throws -> URL {
        try baseURL()
            .appendingPathComponent("drawings", isDirectory: true)
            .appendingPathComponent(pairCode, isDirectory: true)
            .appendingPathComponent(userId, isDirectory: true)
            .appendingPathComponent("latest.png")
    }

    private func baseURL() throws -> URL {
        let appSupportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let url = appSupportURL.appendingPathComponent("InSync/LocalBackend", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

private struct LocalStore: Codable {
    var pairs: [String: LocalPairRecord] = [:]
}

private struct LocalPairRecord: Codable {
    var pairCode: String
    var createdAt: TimeInterval
    var createdBy: String
    var userA: String
    var userB: String?
    var status: String
    var latestByUserA: LocalDrawingMetadata?
    var latestByUserB: LocalDrawingMetadata?

    var pair: Pair {
        Pair(
            pairCode: pairCode,
            createdBy: createdBy,
            userA: userA,
            userB: userB,
            status: PairStatus(rawValue: status) ?? .waiting,
            latestByUserA: latestByUserA?.drawingMetadata,
            latestByUserB: latestByUserB?.drawingMetadata
        )
    }
}

private struct LocalDrawingMetadata: Codable {
    var imagePath: String
    var updatedAt: TimeInterval

    var drawingMetadata: DrawingMetadata {
        DrawingMetadata(
            imagePath: imagePath,
            updatedAt: Date(timeIntervalSince1970: updatedAt)
        )
    }
}

private enum DefaultsKey {
    static let localUserId = "localBackendUserId"
    static let demoPartnerUserId = "local-demo-partner"
}

