#if TEXTUAL_ENABLE_TEXT_SELECTION && !targetEnvironment(macCatalyst)
  import Foundation
  import SwiftUI
  import Testing

  @testable import Textual

  struct TextSelectionModelTests {
    @Test
    func urlForPoint() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let hitPoint = CGPoint(x: 276, y: 25)
      let missPoint = CGPoint(x: 36, y: 25)
      let outsidePoint = CGPoint(x: 10, y: 10)

      // when
      let hitURL = model.url(for: hitPoint)
      let missURL = model.url(for: missPoint)
      let outsideURL = model.url(for: outsidePoint)

      // then
      #expect(hitURL == URL(string: "https://example.com"))
      #expect(missURL == nil)
      #expect(outsideURL == nil)
    }

    @Test
    func empty() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "empty")

      // when
      let hasText = model.hasText

      // then
      #expect(hasText == false)
    }

    @Test
    func nonEmpty() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")

      // when
      let hasText = model.hasText

      // then
      #expect(hasText == true)
    }

    @Test
    func startPosition() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let expected = TextPosition(
        indexPath: .init(runSlice: 0, run: 0, line: 0, layout: 0),
        affinity: .downstream
      )

      // when
      let position = model.startPosition

      // then
      #expect(position == expected)
    }

    @Test
    func endPosition() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let expected = TextPosition(
        indexPath: .init(runSlice: 0, run: 4, line: 1, layout: 1),
        affinity: .upstream
      )

      // when
      let position = model.endPosition

      // then
      #expect(position == expected)
    }

    @Test
    func attributedTextCollapsedRange() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let range = TextRange(start: model.startPosition, end: model.startPosition)

      // when
      let attributed = model.attributedText(in: range)

      // then
      #expect(attributed.string.isEmpty)
    }

    @Test
    func attributedTextTwoParagraphs() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let range = TextRange(
        start: TextPosition(
          indexPath: .init(runSlice: 1, run: 2, line: 0, layout: 0),
          affinity: .downstream
        ),
        end: TextPosition(
          indexPath: .init(runSlice: 5, run: 1, line: 0, layout: 1),
          affinity: .upstream
        )
      )

      // when
      let attributed = model.attributedText(in: range)

      // then
      #expect(attributed.string == "paragraph with a link and \u{2067}مرحبا\u{2069}.Another sample")
    }

    @Test
    func positionFromOffsetZero() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")

      // when
      let result = model.position(from: model.startPosition, offset: 0)

      // then
      #expect(result == model.startPosition)
    }

    @Test
    func positionFromOffsetOutOfRange() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let start = model.startPosition

      // when
      let result = model.position(from: start, offset: 103)

      // then
      #expect(result == nil)
    }

    @Test
    func positionFromOffset() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let offset = 52
      let expected = TextPosition(
        indexPath: .init(runSlice: 0, run: 0, line: 0, layout: 1),
        affinity: .upstream
      )

      // when
      let result = model.position(from: model.startPosition, offset: offset)

      // then
      #expect(result == expected)
    }

    @Test
    func offsetSamePosition() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")

      // when
      let offset = model.offset(from: model.startPosition, to: model.startPosition)

      // then
      #expect(offset == 0)
    }

    @Test
    func offset() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")

      // when
      let offset = model.offset(from: model.startPosition, to: model.endPosition)

      // then
      #expect(offset == 102)
    }

    @Test
    func offsetBackwards() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let start = TextPosition(
        indexPath: .init(runSlice: 3, run: 3, line: 0, layout: 0),
        affinity: .upstream
      )

      // when
      let offset = model.offset(from: start, to: model.startPosition)

      // then
      #expect(offset == -38)
    }

    @Test
    func firstRectCollapsedRange() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let range = TextRange(start: model.startPosition, end: model.startPosition)

      // when
      let rect = model.firstRect(for: range)

      // then
      #expect(rect == model.caretRect(for: model.startPosition))
    }

    @Test
    func firstRect() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let range = TextRange(
        start: model.startPosition,
        end: TextPosition(
          indexPath: .init(runSlice: 0, run: 0, line: 1, layout: 0),
          affinity: .upstream
        )
      )
      let expected = CGRect(x: 16, y: 16, width: 278, height: 20)

      // when
      let rect = model.firstRect(for: range)

      // then
      #expect(rect.integral == expected)
    }

    @Test
    func caretRectDownstream() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let expected = CGRect(x: 16, y: 16, width: 1, height: 20)

      // when
      let rect = model.caretRect(for: model.startPosition)

      // then
      #expect(rect.integral == expected)
    }

    @Test
    func caretRectUpstream() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: IndexPath(runSlice: 0, run: 0, line: 0, layout: 0),
        affinity: .upstream
      )
      let expected = CGRect(x: 25, y: 16, width: 2, height: 20)

      // when
      let rect = model.caretRect(for: position)

      // then
      #expect(rect.integral == expected)
    }

    @Test
    func caretRectDownstreamRightToLeft() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: IndexPath(runSlice: 0, run: 1, line: 1, layout: 0),
        affinity: .downstream
      )
      let expected = CGRect(x: 51, y: 38, width: 2, height: 20)

      // when
      let rect = model.caretRect(for: position)

      // then
      #expect(rect.integral == expected)
    }

    @Test
    func caretRectUpstreamRightToLeft() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: IndexPath(runSlice: 0, run: 1, line: 1, layout: 0),
        affinity: .upstream
      )
      let expected = CGRect(x: 47, y: 38, width: 2, height: 20)

      // when
      let rect = model.caretRect(for: position)

      // then
      #expect(rect.integral == expected)
    }

    @Test
    func selectionRectsCollapsedRange() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let range = TextRange(start: model.startPosition, end: model.startPosition)

      // when
      let rects = model.selectionRects(for: range)

      // then
      #expect(rects.isEmpty)
    }

    @Test
    func selectionRectsSingleLine() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let range = TextRange(
        start: model.startPosition,
        end: TextPosition(
          indexPath: .init(runSlice: 3, run: 0, line: 0, layout: 0),
          affinity: .upstream
        )
      )
      let expected: [TextSelectionRect] = [
        .init(
          rect: CGRect(x: 16, y: 16, width: 31, height: 20),
          layoutDirection: .leftToRight,
          containsStart: true,
          containsEnd: true
        )
      ]

      // when
      let rects = model.selectionRects(for: range)

      // then
      #expect(rects.map(\.integral) == expected)
    }

    @Test
    func selectionRectsMultipleLines() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let range = TextRange(
        start: model.startPosition,
        end: TextPosition(
          indexPath: .init(runSlice: 0, run: 2, line: 1, layout: 0),
          affinity: .upstream
        )
      )
      let expected: [TextSelectionRect] = [
        .init(
          rect: CGRect(x: 16, y: 16, width: 278, height: 20),
          layoutDirection: .leftToRight,
          containsStart: true,
          containsEnd: false
        ),
        .init(
          rect: CGRect(x: 16, y: 35, width: 32, height: 23),
          layoutDirection: .leftToRight,
          containsStart: false,
          containsEnd: false
        ),
        .init(
          rect: CGRect(x: 47, y: 35, width: 35, height: 23),
          layoutDirection: .rightToLeft,
          containsStart: false,
          containsEnd: false
        ),
        .init(
          rect: CGRect(x: 81, y: 35, width: 6, height: 23),
          layoutDirection: .leftToRight,
          containsStart: false,
          containsEnd: true
        ),
      ]

      // when
      let rects = model.selectionRects(for: range)

      // then
      #expect(rects.map(\.integral) == expected)
    }

    @Test
    func closestPositionOnEmptyModel() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "empty")

      // when
      let position = model.closestPosition(to: .zero)

      // then
      #expect(position == nil)
    }

    @Test
    func closestPositionWithinFirstRun() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let point = CGPoint(x: 36.75, y: 25.65)
      let expected = TextPosition(
        indexPath: .init(runSlice: 2, run: 0, line: 0, layout: 0),
        affinity: .downstream
      )

      // when
      let position = model.closestPosition(to: point)

      // then
      #expect(position == expected)
    }

    @Test
    func closestPositionWithinLinkRun() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let point = CGPoint(x: 276.18, y: 25.65)
      let expected = TextPosition(
        indexPath: .init(runSlice: 2, run: 3, line: 0, layout: 0),
        affinity: .downstream
      )

      // when
      let position = model.closestPosition(to: point)

      // then
      #expect(position == expected)
    }

    @Test
    func closestPositionSecondLine() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let point = CGPoint(x: 29.027, y: 47.13)
      let expected = TextPosition(
        indexPath: .init(runSlice: 1, run: 0, line: 1, layout: 0),
        affinity: .downstream
      )

      // when
      let position = model.closestPosition(to: point)

      // then
      #expect(position == expected)
    }

    @Test
    func closestPositionNextLayout() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let point = CGPoint(x: 30.98, y: 82.31)
      let expected = TextPosition(
        indexPath: .init(runSlice: 1, run: 0, line: 0, layout: 1),
        affinity: .downstream
      )

      // when
      let position = model.closestPosition(to: point)

      // then
      #expect(position == expected)
    }

    @Test
    func closestPositionClampsBeforeStart() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let point = CGPoint(x: 6, y: 25.64)

      // when
      let position = model.closestPosition(to: point)

      // then
      #expect(position == model.startPosition)
    }

    @Test
    func closestPositionWithinRange() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let range = TextRange(
        start: .init(
          indexPath: .init(runSlice: 2, run: 0, line: 0, layout: 0),
          affinity: .downstream
        ),
        end: .init(
          indexPath: .init(runSlice: 2, run: 3, line: 0, layout: 0),
          affinity: .upstream
        )
      )
      let point = CGPoint(x: 36.75, y: 25.64)

      // when
      let position = model.closestPosition(to: point, within: range)

      // then
      #expect(position == range.start)
    }

    @Test
    func closestPositionBeforeRange() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let range = TextRange(
        start: .init(
          indexPath: .init(runSlice: 2, run: 0, line: 0, layout: 0),
          affinity: .downstream
        ),
        end: .init(
          indexPath: .init(runSlice: 2, run: 3, line: 0, layout: 0),
          affinity: .upstream
        )
      )
      let point = CGPoint(x: 6, y: 25.6)

      // when
      let position = model.closestPosition(to: point, within: range)

      // then
      #expect(position == range.start)
    }

    @Test
    func closestPositionAfterRange() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let range = TextRange(
        start: .init(
          indexPath: .init(runSlice: 2, run: 0, line: 0, layout: 0),
          affinity: .downstream
        ),
        end: .init(
          indexPath: .init(runSlice: 2, run: 3, line: 0, layout: 0),
          affinity: .upstream
        )
      )
      let point = CGPoint(x: 30.98, y: 82.31)

      // when
      let position = model.closestPosition(to: point, within: range)

      // then
      #expect(position == range.end)
    }

    @Test
    func characterRangeEmptyModel() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "empty")

      // when
      let range = model.characterRange(at: .zero)

      // then
      #expect(range == nil)
    }

    @Test
    func characterRange() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let point = CGPoint(x: 30.98, y: 82.31)
      let expected = TextRange(
        start: .init(
          indexPath: .init(runSlice: 1, run: 0, line: 0, layout: 1),
          affinity: .downstream
        ),
        end: .init(
          indexPath: .init(runSlice: 1, run: 0, line: 0, layout: 1),
          affinity: .upstream
        )
      )

      // when
      let range = model.characterRange(at: point)

      // then
      #expect(range == expected)
    }

    @Test
    func blockRange() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 2, run: 1, line: 0, layout: 0),
        affinity: .downstream
      )
      let expected = TextRange(
        start: .init(
          indexPath: .init(runSlice: 0, run: 0, line: 0, layout: 0),
          affinity: .downstream
        ),
        end: .init(
          indexPath: .init(runSlice: 0, run: 2, line: 1, layout: 0),
          affinity: .upstream
        )
      )

      // when
      let range = model.blockRange(for: position)

      // then
      #expect(range == expected)
    }

    @Test
    func blockStartFromMiddle() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 2, run: 1, line: 0, layout: 0),
        affinity: .downstream
      )
      let expected = TextPosition(
        indexPath: .init(runSlice: 0, run: 0, line: 0, layout: 0),
        affinity: .downstream
      )

      // when
      let result = model.blockStart(for: position)

      // then
      #expect(result == expected)
    }

    @Test
    func blockStartFromStart() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 0, run: 0, line: 0, layout: 1),
        affinity: .downstream
      )
      let expected = TextPosition(
        indexPath: .init(runSlice: 0, run: 0, line: 0, layout: 0),
        affinity: .downstream
      )

      // when
      let result = model.blockStart(for: position)

      // then
      #expect(result == expected)
    }

    @Test
    func blockStartFromVeryStart() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 0, run: 0, line: 0, layout: 0),
        affinity: .downstream
      )
      let expected = position

      // when
      let result = model.blockStart(for: position)

      // then
      #expect(result == expected)
    }

    @Test
    func blockEndFromMiddle() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      // Position in middle of first layout
      let position = TextPosition(
        indexPath: .init(runSlice: 2, run: 1, line: 0, layout: 0),
        affinity: .downstream
      )
      let expected = TextPosition(
        indexPath: .init(runSlice: 0, run: 2, line: 1, layout: 0),
        affinity: .upstream
      )

      // when
      let result = model.blockEnd(for: position)

      // then
      #expect(result == expected)
    }

    @Test
    func blockEndFromEnd() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 0, run: 2, line: 1, layout: 0),
        affinity: .upstream
      )  // end of first layout
      let expected = TextPosition(
        indexPath: .init(runSlice: 0, run: 4, line: 1, layout: 1),
        affinity: .upstream
      )

      // when
      let result = model.blockEnd(for: position)

      // then
      #expect(result == expected)
    }

    @Test
    func blockEndFromVeryEnd() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 0, run: 4, line: 1, layout: 1),
        affinity: .upstream
      )
      // Expected: same position (no next block)
      let expected = position

      // when
      let result = model.blockEnd(for: position)

      // then
      #expect(result == expected)
    }

    @Test
    func isPositionAtBlockBoundaryAtStart() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 0, run: 0, line: 0, layout: 0),
        affinity: .downstream
      )

      // when
      let result = model.isPositionAtBlockBoundary(position)

      // then
      #expect(result == true)
    }

    @Test
    func isPositionAtBlockBoundaryAtEnd() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 0, run: 2, line: 1, layout: 0),
        affinity: .upstream
      )

      // when
      let result = model.isPositionAtBlockBoundary(position)

      // then
      #expect(result == true)
    }

    @Test
    func isPositionAtBlockBoundaryInMiddle() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 2, run: 1, line: 0, layout: 0),
        affinity: .downstream
      )

      // when
      let result = model.isPositionAtBlockBoundary(position)

      // then
      #expect(result == false)
    }

    @Test
    func positionAboveSameLayout() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 0, run: 1, line: 1, layout: 0),
        affinity: .downstream
      )
      let anchor = position

      // when
      let result = model.positionAbove(position, anchor: anchor)

      // then
      #expect(result != nil)
      #expect(result?.indexPath.line == 0)
      #expect(result?.indexPath.layout == 0)
    }

    @Test
    func positionAboveAcrossLayouts() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 0, run: 0, line: 0, layout: 1),
        affinity: .downstream
      )
      let anchor = position

      // when
      let result = model.positionAbove(position, anchor: anchor)

      // then
      #expect(result != nil)
      #expect(result?.indexPath.layout == 0)
      #expect(result?.indexPath.line == 1)
    }

    @Test
    func positionAboveFromFirstLine() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 0, run: 0, line: 0, layout: 0),
        affinity: .downstream
      )
      let anchor = position

      // when
      let result = model.positionAbove(position, anchor: anchor)

      // then
      #expect(result == model.startPosition)
    }

    @Test
    func positionBelowSameLayout() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 0, run: 1, line: 0, layout: 0),
        affinity: .downstream
      )
      let anchor = position

      // when
      let result = model.positionBelow(position, anchor: anchor)

      // then
      #expect(result != nil)
      #expect(result?.indexPath.line == 1)
      #expect(result?.indexPath.layout == 0)
    }

    @Test
    func positionBelowAcrossLayouts() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 0, run: 2, line: 1, layout: 0),
        affinity: .upstream
      )
      let anchor = position

      // when
      let result = model.positionBelow(position, anchor: anchor)

      // then
      #expect(result != nil)
      #expect(result?.indexPath.layout == 1)
      #expect(result?.indexPath.line == 0)
    }

    @Test
    func positionBelowFromLastLine() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 0, run: 4, line: 1, layout: 1),
        affinity: .upstream
      )
      let anchor = position

      // when
      let result = model.positionBelow(position, anchor: anchor)

      // then
      #expect(result == model.endPosition)
    }

    @Test
    func positionInDirectionLeftRight() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let start = model.startPosition

      // when
      let right = model.position(from: start, in: .right, offset: 1)
      let left = right.flatMap { model.position(from: $0, in: .left, offset: 1) }
      let zero = model.position(from: start, in: .right, offset: 0)
      let negative = model.position(from: start, in: .left, offset: -1)

      // then
      #expect(right == model.position(from: start, offset: 1))
      #expect(left == start)
      #expect(zero == start)
      #expect(negative == nil)
    }

    @Test
    func positionInDirectionUpDown() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let position = TextPosition(
        indexPath: .init(runSlice: 0, run: 1, line: 1, layout: 0),
        affinity: .downstream
      )

      // when
      let up = model.position(from: position, in: .up, offset: 1)
      let down = up.flatMap { model.position(from: $0, in: .down, offset: 1) }

      // then
      #expect(up?.indexPath.line == 0)
      #expect(up?.indexPath.layout == 0)
      #expect(down?.indexPath.line == 1)
      #expect(down?.indexPath.layout == 0)
    }

    @Test
    func farthestPositionWithinRange() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let range = TextRange(
        start: model.startPosition,
        end: model.endPosition
      )

      // when
      let left = model.farthestPosition(within: range, in: .left)
      let right = model.farthestPosition(within: range, in: .right)
      let up = model.farthestPosition(within: range, in: .up)
      let down = model.farthestPosition(within: range, in: .down)

      // then
      #expect(left == range.start || left == range.end)
      #expect(right == range.start || right == range.end)
      #expect(up == range.start || up == range.end)
      #expect(down == range.start || down == range.end)
      #expect(Set([left, right]).count == 2 || range.isCollapsed)
      #expect(Set([up, down]).count == 2 || range.isCollapsed)
    }

    @Test
    func characterRangeByExtending() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let start = model.startPosition

      // when
      let right = model.characterRange(byExtending: start, in: .right)
      let leftFromStart = model.characterRange(byExtending: start, in: .left)

      // then
      #expect(right?.start == start)
      #expect(right?.end == model.position(from: start, offset: 1))
      #expect(leftFromStart == nil)
    }

    @Test
    func moveSelectionMovesCollapsedCaret() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let start = model.startPosition
      model.selectedRange = TextRange(start: start, end: start)

      // when
      let moved = model.moveSelection(in: .right)

      // then
      #expect(moved)
      #expect(model.selectedRange?.isCollapsed == true)
      #expect(model.selectedRange?.start == model.position(from: start, offset: 1))
    }

    @Test
    func moveSelectionCollapsesNonEmptyRange() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let range = TextRange(start: model.startPosition, end: model.endPosition)
      model.selectedRange = range
      let expected = model.farthestPosition(within: range, in: .left)

      // when
      let moved = model.moveSelection(in: .left)

      // then
      #expect(moved)
      #expect(model.selectedRange?.isCollapsed == true)
      #expect(model.selectedRange?.start == expected)
    }

    @Test
    func moveSelectionByWordAndBlock() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let start = model.startPosition
      model.selectedRange = TextRange(start: start, end: start)

      // when
      #if os(macOS)
        let movedWord = model.moveSelection(collapsingTo: \.end) { position in
          model.nextWord(from: position)
        }
        let afterWord = model.selectedRange?.start
        let movedBlock = model.moveSelection(collapsingTo: \.end) { position in
          model.blockEnd(for: position)
        }
      #else
        let movedWord = model.moveSelection(collapsingTo: \.end) { position in
          model.blockEnd(for: position)
        }
        let afterWord = model.selectedRange?.start
        let movedBlock = model.moveSelection(collapsingTo: \.start) { position in
          model.blockStart(for: position)
        }
      #endif

      // then
      #expect(movedWord)
      #expect(afterWord != start)
      #expect(movedBlock)
      #expect(model.selectedRange?.isCollapsed == true)
    }

    @Test
    func reconcileRangePreservesCharacterOffsets() throws {
      // given
      let original = try loadLayoutCollection(named: "two-paragraphs-bidi")
      let rebuilt = try loadLayoutCollection(named: "two-paragraphs-bidi")
      let range = TextRange(
        start: TextPosition(
          indexPath: .init(runSlice: 1, run: 2, line: 0, layout: 0),
          affinity: .downstream
        ),
        end: TextPosition(
          indexPath: .init(runSlice: 5, run: 1, line: 0, layout: 1),
          affinity: .upstream
        )
      )
      let startOffset = original.characterIndex(at: range.start)
      let endOffset = original.characterIndex(at: range.end)

      // when
      let reconciled = rebuilt.reconcileRange(range, from: original)

      // then
      #expect(reconciled != nil)
      #expect(rebuilt.characterIndex(at: reconciled!.start) == startOffset)
      #expect(rebuilt.characterIndex(at: reconciled!.end) == endOffset)
    }

    @Test
    func setLayoutCollectionReconcilesSelection() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let range = TextRange(
        start: TextPosition(
          indexPath: .init(runSlice: 1, run: 2, line: 0, layout: 0),
          affinity: .downstream
        ),
        end: TextPosition(
          indexPath: .init(runSlice: 5, run: 1, line: 0, layout: 1),
          affinity: .upstream
        )
      )
      model.selectedRange = range
      let startOffset = model.offset(from: model.startPosition, to: range.start)
      let endOffset = model.offset(from: model.startPosition, to: range.end)

      var rebuilt = try loadLayoutCollection(named: "two-paragraphs-bidi")
      rebuilt = rebuilt.withPerturbedGeometry()
      rebuilt.needsReconciliation = true

      // when
      model.setLayoutCollection(rebuilt)

      // then
      let selected = try #require(model.selectedRange)
      #expect(model.offset(from: model.startPosition, to: selected.start) == startOffset)
      #expect(model.offset(from: model.startPosition, to: selected.end) == endOffset)
    }

    #if os(iOS)
      @Test(.disabled())
      @MainActor
      func recordTwoParagraphsBidi() throws {
        let view = StructuredText(
          markdown: """
            This is a **sample** paragraph with a [link](https://example.com) and \u{2067}مرحبا\u{2069}.

            Another *sample* paragraph with `code` and \u{2067}كيف حالك؟\u{2069}.
            """
        ).padding()

        try TextSelectionModel.recordFixture(for: view, named: "two-paragraphs-bidi")
      }
    #endif
  }

  extension TextSelectionRect {
    var integral: Self {
      TextSelectionRect(
        rect: rect.integral,
        layoutDirection: layoutDirection,
        containsStart: containsStart,
        containsEnd: containsEnd
      )
    }
  }
#endif
