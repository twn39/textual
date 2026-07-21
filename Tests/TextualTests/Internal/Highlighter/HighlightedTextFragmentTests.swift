import Foundation
import SwiftUI
import Testing

@testable import Textual

@MainActor
struct HighlightedTextFragmentTests {
  @Test
  func modelTokenizeAndHighlight() async {
    let model = HighlightedTextFragment.Model()
    let str = AttributedString("let x = 1")
    let content = str[str.startIndex..<str.endIndex]

    // when
    await model.tokenize(content: content, languageHint: "swift")

    // then
    #expect(model.tokens.count > 0)

    // given theme and environment
    let theme = StructuredText.HighlighterTheme.default
    let environment = TextEnvironmentValues()

    // when
    model.highlight(
      tokens: model.tokens,
      presentationIntent: nil,
      using: theme,
      environment: environment
    )

    // then
    #expect(model.highlightedCode != nil)
    let highlightedString = model.highlightedCode!
    #expect(!highlightedString.characters.isEmpty)
  }

  @Test
  func themeChangeUpdatesHighlight() async {
    // given
    let model = HighlightedTextFragment.Model()
    let str = AttributedString("let x = 1")
    let content = str[str.startIndex..<str.endIndex]
    await model.tokenize(content: content, languageHint: "swift")

    let environment = TextEnvironmentValues()

    // when highlighted with default theme
    model.highlight(
      tokens: model.tokens,
      presentationIntent: nil,
      using: .default,
      environment: environment
    )
    let codeWithDefaultTheme = model.highlightedCode
    #expect(codeWithDefaultTheme != nil)

    // when highlighted with plain theme
    model.highlight(
      tokens: model.tokens,
      presentationIntent: nil,
      using: .plain,
      environment: environment
    )
    let codeWithPlainTheme = model.highlightedCode
    #expect(codeWithPlainTheme != nil)

    // verify that the default theme and plain theme produce different attributed output
    #expect(codeWithDefaultTheme != codeWithPlainTheme)
  }
}
