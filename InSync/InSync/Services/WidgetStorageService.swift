import Foundation

struct WidgetDrawingSnapshot {
    let imageData: Data?
    let updatedAt: Date?
    let partnerLabel: String

    var hasImage: Bool {
        imageData?.isEmpty == false
    }
}

final class WidgetStorageService {
    static let shared = WidgetStorageService()

    private let localMetadataFilename = "latest_partner_metadata.json"

    private init() {}

    func savePartnerDrawing(data: Data, updatedAt: Date, partnerLabel: String = "your person") throws {
        let imageURL = try latestPartnerImageURLForWrite()
        let containerURL = imageURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: containerURL,
            withIntermediateDirectories: true
        )
        try data.write(to: imageURL, options: [.atomic])

        let metadata = LocalWidgetMetadata(
            updatedAt: updatedAt.timeIntervalSince1970,
            partnerLabel: partnerLabel
        )
        let metadataData = try JSONEncoder().encode(metadata)
        try metadataData.write(
            to: containerURL.appendingPathComponent(localMetadataFilename),
            options: [.atomic]
        )

        if hasAppGroupContainer,
           let defaults = UserDefaults(suiteName: Constants.appGroupIdentifier) {
            defaults.set(updatedAt.timeIntervalSince1970, forKey: Constants.latestPartnerUpdatedAtKey)
            defaults.set(partnerLabel, forKey: Constants.partnerLabelKey)
        }
    }

    func loadPartnerDrawing() -> WidgetDrawingSnapshot {
        let imageURL = latestPartnerImageURLForRead()
        let imageData = try? Data(contentsOf: imageURL)
        let metadata = metadata(
            at: imageURL.deletingLastPathComponent().appendingPathComponent(localMetadataFilename)
        )

        let timestamp = metadata?.updatedAt ?? 0
        let updatedAt = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        let partnerLabel = metadata?.partnerLabel ?? "your person"

        return WidgetDrawingSnapshot(
            imageData: imageData,
            updatedAt: updatedAt,
            partnerLabel: partnerLabel
        )
    }

    private func latestPartnerImageURLForWrite() throws -> URL {
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier
        ) {
            return containerURL.appendingPathComponent(Constants.widgetImageFilename)
        }

        return try localContainerURL().appendingPathComponent(Constants.widgetImageFilename)
    }

    private var hasAppGroupContainer: Bool {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier
        ) != nil
    }

    private func latestPartnerImageURLForRead() -> URL {
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier
        ) {
            return containerURL.appendingPathComponent(Constants.widgetImageFilename)
        }

        return fallbackContainerURL().appendingPathComponent(Constants.widgetImageFilename)
    }

    private func metadata(at metadataURL: URL) -> LocalWidgetMetadata? {
        guard let data = try? Data(contentsOf: metadataURL) else {
            return nil
        }

        return try? JSONDecoder().decode(LocalWidgetMetadata.self, from: data)
    }

    private func localContainerURL() throws -> URL {
        let containerURL = fallbackContainerURL()
        try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
        return containerURL
    }

    private func fallbackContainerURL() -> URL {
        URL(fileURLWithPath: "/tmp/InSyncWidgetCache", isDirectory: true)
    }
}

private struct LocalWidgetMetadata: Codable {
    let updatedAt: TimeInterval
    let partnerLabel: String
}
