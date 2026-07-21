import SwiftUI

extension StructuredText {
  /// Font-relative spacing used by ``GitHubStyle`` recipes.
  enum GitHubStyleMetrics {
    static let blockQuoteBarWidth = FontScaled<CGFloat>.fontScaled(0.2)
    static let blockQuoteLabelPadding = FontScaled<CGFloat>.fontScaled(1)
    static let paragraphLineSpacing = FontScaled<CGFloat>.fontScaled(0.25)
  }
}
