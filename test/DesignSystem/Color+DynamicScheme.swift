import SwiftUI
import UIKit

extension Color {
    /// A color that resolves differently per light/dark appearance, independent
    /// of Asset Catalog color sets — needed because the design tokens are defined
    /// in code (extracted from the reference mockup) rather than as asset colors.
    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
