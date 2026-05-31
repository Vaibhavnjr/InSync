import Foundation
import WidgetKit

struct InSyncWidgetEntry: TimelineEntry {
    let date: Date
    let imageData: Data?
    let updatedAt: Date?
    let partnerLabel: String
    let isPreview: Bool
}
