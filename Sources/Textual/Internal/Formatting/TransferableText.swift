import Foundation
import UniformTypeIdentifiers

#if canImport(UIKit)
  import UIKit
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
#endif

final class TransferableText: NSObject {
  let attributedString: NSAttributedString

  private let formatter: Formatter

  init(attributedString: NSAttributedString) {
    self.attributedString = attributedString
    self.formatter = Formatter(attributedString)
    super.init()
  }

  var plainText: String {
    formatter.plainText()
  }

  var html: String {
    formatter.html()
  }
}

extension TransferableText {
  #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit) && !targetEnvironment(macCatalyst)
    func write(to pasteboard: NSPasteboard) {
      pasteboard.clearContents()
      pasteboard.setString(plainText, forType: .string)
      pasteboard.setString(html, forType: .html)
    }
  #endif

  #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(UIKit)
    func writeToGeneralPasteboard() {
      UIPasteboard.general.setItems(
        [
          [
            UTType.plainText.identifier: plainText,
            UTType.html.identifier: html,
          ]
        ]
      )
    }
  #endif
}

extension TransferableText: NSItemProviderWriting {
  static var writableTypeIdentifiersForItemProvider: [String] {
    [UTType.plainText.identifier, UTType.html.identifier]
  }

  func loadData(
    withTypeIdentifier typeIdentifier: String,
    forItemProviderCompletionHandler completionHandler: @escaping (Data?, (any Error)?) -> Void
  ) -> Progress? {
    switch typeIdentifier {
    case UTType.plainText.identifier:
      completionHandler(plainText.data(using: .utf8), nil)
    case UTType.html.identifier:
      completionHandler(html.data(using: .utf8), nil)
    default:
      completionHandler(nil, nil)
    }
    return nil
  }
}
