import Foundation
import WidgetKit

struct InSyncWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> InSyncWidgetEntry {
        previewEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (InSyncWidgetEntry) -> Void) {
        let currentEntry = entry()
        completion(context.isPreview && currentEntry.imageData == nil ? previewEntry() : currentEntry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<InSyncWidgetEntry>) -> Void) {
        let entry = entry()
        let nextRefresh = Date().addingTimeInterval(30 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func entry() -> InSyncWidgetEntry {
        let snapshot = WidgetStorageService.shared.loadPartnerDrawing()

        return InSyncWidgetEntry(
            date: Date(),
            imageData: snapshot.imageData,
            updatedAt: snapshot.updatedAt,
            partnerLabel: snapshot.partnerLabel,
            isPreview: false
        )
    }

    private func previewEntry() -> InSyncWidgetEntry {
        InSyncWidgetEntry(
            date: Date(),
            imageData: nil,
            updatedAt: Date(),
            partnerLabel: "preview",
            isPreview: true
        )
    }
}
