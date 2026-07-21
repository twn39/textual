import SwiftUI

extension StructuredText {
  /// A proxy for a rendered code block that custom code block styles can use.
  public struct CodeBlockProxy {
    private let content: AttributedSubstring

    internal init(_ content: AttributedSubstring) {
      self.content = content
    }

    /// Copies the code block contents to the system pasteboard.
    ///
    /// Textual writes both a plain-text and an HTML representation when possible.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func copyToPasteboard() {
      #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit) && !targetEnvironment(macCatalyst)
        TransferableText(attributedString: NSAttributedString(AttributedString(content)))
          .write(to: .general)
      #elseif TEXTUAL_ENABLE_TEXT_SELECTION && canImport(UIKit)
        TransferableText(attributedString: NSAttributedString(AttributedString(content)))
          .writeToGeneralPasteboard()
      #endif
    }
  }
}
