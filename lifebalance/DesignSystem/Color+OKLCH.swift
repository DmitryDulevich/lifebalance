import SwiftUI

extension Color {
    /// Exact OKLCH -> sRGB conversion (Björn Ottosson's OKLab), matching how
    /// browsers render `oklch(L C H)` — used so design tokens copied from the
    /// reference mockup render identically rather than as approximated hex.
    init(oklch l: Double, _ c: Double, _ h: Double, opacity: Double = 1) {
        let hRad = h * .pi / 180
        let a = c * cos(hRad)
        let b = c * sin(hRad)

        let l_ = l + 0.3963377774 * a + 0.2158037573 * b
        let m_ = l - 0.1055613458 * a - 0.0638541728 * b
        let s_ = l - 0.0894841775 * a - 1.2914855480 * b

        let lCubed = l_ * l_ * l_
        let mCubed = m_ * m_ * m_
        let sCubed = s_ * s_ * s_

        let rLin = 4.0767416621 * lCubed - 3.3077115913 * mCubed + 0.2309699292 * sCubed
        let gLin = -1.2684380046 * lCubed + 2.6097574011 * mCubed - 0.3413193965 * sCubed
        let bLin = -0.0041960863 * lCubed - 0.7034186147 * mCubed + 1.7076147010 * sCubed

        func gammaCorrect(_ x: Double) -> Double {
            let clamped = min(max(x, 0), 1)
            return clamped <= 0.0031308 ? 12.92 * clamped : 1.055 * pow(clamped, 1 / 2.4) - 0.055
        }

        self.init(
            red: gammaCorrect(rLin),
            green: gammaCorrect(gLin),
            blue: gammaCorrect(bLin),
            opacity: opacity
        )
    }
}
