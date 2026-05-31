import SwiftUI
import WidgetKit

struct InSyncWidget: Widget {
    let kind = Constants.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InSyncWidgetProvider()) { entry in
            InSyncWidgetView(entry: entry)
        }
        .configurationDisplayName("InSync")
        .description("See your latest saved drawing.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}
