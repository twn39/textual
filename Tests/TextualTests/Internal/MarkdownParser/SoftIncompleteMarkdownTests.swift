import Foundation
import Testing

@testable import Textual

struct SoftIncompleteMarkdownTests {
  @Test func leavesCompleteMarkdownUnchanged() {
    let input = """
      # Title

      A **bold** word and `code`.

      ```swift
      print("hi")
      ```
      """

    #expect(SoftIncompleteMarkdown.prepare(input) == input)
  }

  @Test func closesUnclosedBacktickFence() {
    let input = """
      Before

      ```swift
      print(1)
      """

    let output = SoftIncompleteMarkdown.prepare(input)
    #expect(output.hasSuffix("```"))
    #expect(output.contains("print(1)"))
  }

  @Test func closesUnclosedTildeFence() {
    let input = """
      ~~~python
      x = 1
      """

    let output = SoftIncompleteMarkdown.prepare(input)
    #expect(output.hasSuffix("~~~"))
  }

  @Test func closesTrailingIncompleteLink() {
    let input = "See [docs](https://example.com/path"
    #expect(SoftIncompleteMarkdown.prepare(input) == input + ")")
  }

  @Test func closesTrailingInlineCode() {
    let input = "Use `partial"
    #expect(SoftIncompleteMarkdown.prepare(input) == "Use `partial`")
  }

  @Test func closesTrailingStrongEmphasis() {
    let input = "This is **bold"
    #expect(SoftIncompleteMarkdown.prepare(input) == "This is **bold**")
  }

  @Test func closesTrailingEmphasis() {
    let input = "This is *italic"
    #expect(SoftIncompleteMarkdown.prepare(input) == "This is *italic*")
  }

  @Test func doesNotTreatFencedContentAsInline() {
    let input = """
      ```
      **not emphasis
      """

    let output = SoftIncompleteMarkdown.prepare(input)
    // Fence is closed; the `**` inside the fence should not gain a trailing closer outside.
    #expect(output.hasSuffix("```"))
    #expect(!output.hasSuffix("****"))
  }

  @Test func ignoresBareTrailingDelimiterWithoutContent() {
    let input = "Hello **"
    #expect(SoftIncompleteMarkdown.prepare(input) == input)
  }

  @Test func growingStreamKeepsCompletedPrefixIntact() {
    let mid = SoftIncompleteMarkdown.prepare(
      """
      # Title

      Hello **world** and `co
      """
    )
    let complete = SoftIncompleteMarkdown.prepare(
      """
      # Title

      Hello **world** and `code`
      """
    )

    #expect(mid.contains("Hello **world** and "))
    #expect(mid.hasSuffix("`"))
    #expect(complete.contains("Hello **world** and `code`"))
    #expect(complete.hasPrefix("# Title"))
  }
}

@MainActor
struct StreamingMarkupSchedulerTests {
  @Test func disabledFlushesImmediatelyWithoutSoftening() async {
    var flushed: [String] = []
    let scheduler = StreamingMarkupScheduler { flushed.append($0) }

    scheduler.update("**bold", policy: .disabled)

    #expect(flushed == ["**bold"])
  }

  @Test func coalescedFlushesLatestSoftenedMarkup() async throws {
    var flushed: [String] = []
    let scheduler = StreamingMarkupScheduler { flushed.append($0) }

    scheduler.update("a", policy: .coalesced(interval: .milliseconds(30)))
    scheduler.update("**bold", policy: .coalesced(interval: .milliseconds(30)))

    try await Task.sleep(for: .milliseconds(80))

    #expect(flushed == ["**bold**"])
  }

  @Test func flushEmitsPendingImmediately() {
    var flushed: [String] = []
    let scheduler = StreamingMarkupScheduler { flushed.append($0) }

    scheduler.update("`code", policy: .coalesced(interval: .seconds(10)))
    scheduler.flush()

    #expect(flushed == ["`code`"])
  }
}

@MainActor
struct StructuredTextStreamingModelTests {
  private struct CountingParser: MarkupParser {
    let count: LockedCounter
    func attributedString(for input: String) throws -> AttributedString {
      count.increment()
      return AttributedString(input)
    }
  }

  final class LockedCounter: @unchecked Sendable {
    private var value = 0
    private let lock = NSLock()
    func increment() {
      lock.lock()
      value += 1
      lock.unlock()
    }
    var current: Int {
      lock.lock()
      defer { lock.unlock() }
      return value
    }
  }

  @Test func skipsRedundantParseWhenPreparedMarkupUnchanged() {
    let count = LockedCounter()
    let model = StructuredText.Model()
    let parser = CountingParser(count: count)
    let policy = StreamingUpdates.coalesced(interval: .seconds(10))

    model.update(markup: "**bold", parser: parser, policy: policy)
    model.flush()
    #expect(count.current == 1)
    #expect(String(model.attributedString.characters) == "**bold**")

    // Soft-prepare of the same incomplete string yields the same payload; skip re-parse.
    model.update(markup: "**bold", parser: parser, policy: policy)
    model.flush()
    #expect(count.current == 1)

    model.update(markup: "Hello", parser: parser, policy: policy)
    model.flush()
    #expect(count.current == 2)
    #expect(String(model.attributedString.characters) == "Hello")
  }
}
