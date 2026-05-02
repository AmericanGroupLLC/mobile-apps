import SwiftUI
import WidgetKit

@main
struct MyHealthWidgetBundle: WidgetBundle {
    var body: some Widget {
        ReadinessWidget()
        TodaysPlanWidget()
        MacroRingsWidget()
    }
}
