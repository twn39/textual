import SwiftUI

extension StructuredText {
  /// Font-relative spacing used by ``DefaultStyle`` recipes.
  ///
  /// Theme styles should prefer these constants over ad-hoc `.textual.padding` literals so spacing
  /// tweaks stay local to the theme instead of depending on every public modifier overload.
  enum DefaultStyleMetrics {
    static let blockQuoteLineSpacing = FontScaled<CGFloat>.fontScaled(0.471)
    static let blockQuotePadding = FontScaled<CGFloat>.fontScaled(0.941)
    static let tableCellLineSpacing = FontScaled<CGFloat>.fontScaled(0.471)
    static let tableCellPadding = FontScaled<CGFloat>.fontScaled(0.588)
    static let paragraphLineSpacing = FontScaled<CGFloat>.fontScaled(0.23)
    static let paragraphBlockSpacing = FontScaled<BlockSpacing>.fontScaled(top: 0.8)
  }
}
