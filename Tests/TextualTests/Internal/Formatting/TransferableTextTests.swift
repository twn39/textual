import Foundation
import Testing
import UniformTypeIdentifiers

@testable import Textual

struct TransferableTextTests {
  @Test func plainTextAndHTMLMatchFormatter() throws {
    // given
    let attributed = try NSAttributedString(
      markdown: """
        **Hello** _world_

        - one
        - two
        """
    )
    let transferable = TransferableText(attributedString: attributed)
    let formatter = Formatter(attributed)

    // when / then
    #expect(transferable.plainText == formatter.plainText())
    #expect(transferable.html == formatter.html())
    #expect(transferable.plainText.contains("Hello"))
    #expect(transferable.html.contains("<strong>Hello</strong>"))
  }

  @Test func itemProviderWritableTypes() throws {
    // given
    let transferable = TransferableText(
      attributedString: NSAttributedString(string: "sample")
    )

    // then
    #expect(
      TransferableText.writableTypeIdentifiersForItemProvider
        == [UTType.plainText.identifier, UTType.html.identifier]
    )
    #expect(transferable.plainText == "sample")
    #expect(transferable.html.contains("sample"))
  }
}
