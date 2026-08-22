import SwiftUI

/// The soft diagonal wash used behind every primary screen in the app.
struct ScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: Palette.screenBackgroundStops,
            startPoint: UnitPoint(x: 0.15, y: 0),
            endPoint: UnitPoint(x: 0.85, y: 1)
        )
        .ignoresSafeArea()
    }
}
