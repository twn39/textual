import Foundation

// MARK: - Overview
//
// Softens incomplete Markdown that commonly appears while a document is still streaming in
// (unclosed fences, trailing emphasis, unfinished links). The goal is a best-effort string that
// Foundation’s Markdown parser can render without dropping or mangling earlier content.
//
// This is intentionally heuristic—not a full Markdown repair pass.

enum SoftIncompleteMarkdown {
  /// Returns a Markdown string with trailing incompleteness softened for mid-stream parsing.
  static func prepare(_ markdown: String) -> String {
    var result = closeUnclosedCodeFences(in: markdown)
    result = closeTrailingIncompleteLink(in: result)
    result = closeTrailingInlineCode(in: result)
    result = closeTrailingEmphasis(in: result, delimiter: "**")
    result = closeTrailingEmphasis(in: result, delimiter: "__")
    result = closeTrailingEmphasis(in: result, delimiter: "*")
    result = closeTrailingEmphasis(in: result, delimiter: "_")
    return result
  }
}

extension SoftIncompleteMarkdown {
  /// Closes an unclosed fenced code block by appending a matching fence line.
  static func closeUnclosedCodeFences(in markdown: String) -> String {
    guard let openFence = unclosedFence(in: markdown) else {
      return markdown
    }

    var result = markdown
    if !result.hasSuffix("\n") {
      result.append("\n")
    }
    result.append(String(repeating: openFence.marker, count: openFence.length))
    return result
  }

  private struct Fence {
    let marker: Character
    let length: Int
  }

  private static func unclosedFence(in markdown: String) -> Fence? {
    var open: Fence?

    markdown.enumerateLines { line, _ in
      guard let fence = fenceMarker(in: line) else {
        return
      }

      if let current = open {
        if fence.marker == current.marker, fence.length >= current.length {
          open = nil
        }
      } else {
        open = fence
      }
    }

    return open
  }

  /// Matches a CommonMark fence line: up to 3 spaces, then 3+ backticks or tildes.
  private static func fenceMarker(in line: String) -> Fence? {
    var cursor = line.startIndex
    var indent = 0
    while cursor < line.endIndex, line[cursor] == " ", indent < 3 {
      indent += 1
      cursor = line.index(after: cursor)
    }
    guard cursor < line.endIndex else {
      return nil
    }

    let marker = line[cursor]
    guard marker == "`" || marker == "~" else {
      return nil
    }

    var length = 0
    while cursor < line.endIndex, line[cursor] == marker {
      length += 1
      cursor = line.index(after: cursor)
    }
    guard length >= 3 else {
      return nil
    }

    // Opening fences may carry an info string; closing fences must not contain the fence char.
    if cursor < line.endIndex {
      let rest = line[cursor...]
      if rest.contains(marker) {
        return nil
      }
    }

    return Fence(marker: marker, length: length)
  }
}

extension SoftIncompleteMarkdown {
  /// Appends `)` when the trailing text looks like an unfinished Markdown link destination.
  static func closeTrailingIncompleteLink(in markdown: String) -> String {
    let region = trailingNonCodeRegion(in: markdown)
    guard let linkStart = region.range(of: "](", options: .backwards) else {
      return markdown
    }

    let after = region[linkStart.upperBound...]
    guard !after.contains(")") else {
      return markdown
    }

    return markdown + ")"
  }

  /// Closes an odd number of unescaped inline-code backticks in the trailing non-code region.
  static func closeTrailingInlineCode(in markdown: String) -> String {
    let region = trailingNonCodeRegion(in: markdown)
    let backticks = countUnescaped(delimiter: "`", in: region)
    guard backticks > 0, backticks % 2 == 1 else {
      return markdown
    }
    return markdown + "`"
  }

  /// Closes an unmatched trailing emphasis/strong delimiter in the trailing non-code region.
  static func closeTrailingEmphasis(in markdown: String, delimiter: String) -> String {
    // Longer delimiters must run before shorter ones (`**` before `*`).
    let region = trailingNonCodeRegion(in: markdown)
    let count = countUnescaped(delimiter: delimiter, in: region)
    guard count > 0, count % 2 == 1 else {
      return markdown
    }

    // Require some content after the last opener so we don't invent markers for a bare trailer.
    guard let last = region.range(of: delimiter, options: .backwards) else {
      return markdown
    }
    let after = region[last.upperBound...]
    guard after.contains(where: { !$0.isWhitespace }) else {
      return markdown
    }

    return markdown + delimiter
  }

  /// Text after the last *closed* fence; if a fence is still open, that open body is excluded
  /// once `closeUnclosedCodeFences` has run (caller order matters).
  private static func trailingNonCodeRegion(in markdown: String) -> Substring {
    var lastClosedEnd = markdown.startIndex
    var openFenceStart: String.Index?

    var lineStart = markdown.startIndex
    while lineStart < markdown.endIndex {
      let lineEnd =
        markdown[lineStart...].firstIndex(of: "\n")
        ?? markdown.endIndex
      let line = markdown[lineStart..<lineEnd]

      if let fence = fenceMarker(in: String(line)) {
        if let open = openFenceStart {
          let openLineEnd =
            markdown[open...].firstIndex(of: "\n")
            ?? markdown.endIndex
          if let openFence = fenceMarker(in: String(markdown[open..<openLineEnd])),
            fence.marker == openFence.marker,
            fence.length >= openFence.length
          {
            openFenceStart = nil
            lastClosedEnd = lineEnd == markdown.endIndex ? lineEnd : markdown.index(after: lineEnd)
          }
        } else {
          openFenceStart = lineStart
        }
      }

      if lineEnd == markdown.endIndex {
        break
      }
      lineStart = markdown.index(after: lineEnd)
    }

    if openFenceStart != nil {
      // Still inside a fence (should be rare after closeUnclosedCodeFences).
      return markdown[markdown.endIndex...]
    }
    return markdown[lastClosedEnd...]
  }

  private static func countUnescaped(delimiter: String, in text: Substring) -> Int {
    guard !delimiter.isEmpty else {
      return 0
    }

    var count = 0
    var searchStart = text.startIndex
    while searchStart < text.endIndex {
      guard let match = text.range(of: delimiter, range: searchStart..<text.endIndex) else {
        break
      }

      // Treat a preceding backslash as an escape for single-character delimiters.
      if delimiter.count == 1, match.lowerBound > text.startIndex {
        let previous = text.index(before: match.lowerBound)
        if text[previous] == "\\" {
          searchStart = match.upperBound
          continue
        }
      }

      // For `*` / `_`, skip runs that are part of a longer delimiter already handled separately.
      if delimiter == "*" {
        let beforeOk =
          match.lowerBound == text.startIndex
          || text[text.index(before: match.lowerBound)] != "*"
        let afterOk =
          match.upperBound == text.endIndex
          || text[match.upperBound] != "*"
        if !(beforeOk && afterOk) {
          searchStart = match.upperBound
          continue
        }
      }
      if delimiter == "_" {
        let beforeOk =
          match.lowerBound == text.startIndex
          || text[text.index(before: match.lowerBound)] != "_"
        let afterOk =
          match.upperBound == text.endIndex
          || text[match.upperBound] != "_"
        if !(beforeOk && afterOk) {
          searchStart = match.upperBound
          continue
        }
      }

      count += 1
      searchStart = match.upperBound
    }
    return count
  }
}
