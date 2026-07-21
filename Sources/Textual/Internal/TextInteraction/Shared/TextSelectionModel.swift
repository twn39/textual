#if TEXTUAL_ENABLE_TEXT_SELECTION
  import SwiftUI

  // MARK: - Overview
  //
  // `TextSelectionModel` is the shared state object that backs selection and interaction.
  //
  // Platform views (AppKit/UIKit) mutate `selectedRange` in response to gestures and editing
  // commands. The model delegates layout-specific work to a `TextLayoutCollection`, which can be
  // rebuilt at any time as SwiftUI resolves new `Text.Layout` values. When the layout collection
  // changes, the model attempts to reconcile the current selection into the new layout so the
  // selection stays stable across updates.

  @Observable
  final class TextSelectionModel {
    var selectedRange: TextRange? {
      willSet {
        selectionWillChange?()
      }
      didSet {
        if selectedRange != nil {
          coordinator?.modelDidSelectText(self)
        }
        selectionDidChange?()
      }
    }

    @ObservationIgnored
    var selectionWillChange: (() -> Void)?

    @ObservationIgnored
    var selectionDidChange: (() -> Void)?

    @ObservationIgnored
    private var layoutCollection: any TextLayoutCollection

    @ObservationIgnored
    private weak var coordinator: TextSelectionCoordinator?

    init(
      layoutCollection: any TextLayoutCollection = EmptyTextLayoutCollection(),
      coordinator: TextSelectionCoordinator? = nil
    ) {
      self.layoutCollection = layoutCollection
      setCoordinator(coordinator)
    }

    func setLayoutCollection(_ layoutCollection: any TextLayoutCollection) {
      guard !layoutCollection.isEqual(to: self.layoutCollection) else {
        return
      }

      let oldLayoutCollection = self.layoutCollection
      self.layoutCollection = layoutCollection

      guard
        let selectedRange,
        layoutCollection.needsPositionReconciliation(with: oldLayoutCollection)
      else {
        return
      }

      // Try to reconcile the selected text range
      self.selectedRange = layoutCollection.reconcileRange(
        selectedRange,
        from: oldLayoutCollection
      )
    }

    func setCoordinator(_ coordinator: TextSelectionCoordinator?) {
      if self.coordinator === coordinator {
        return
      }

      self.coordinator = coordinator
      coordinator?.register(self)
    }

    func url(for point: CGPoint) -> URL? {
      layoutCollection.url(for: point)
    }

    func layoutIndex(of layout: Text.Layout) -> Int? {
      layoutCollection.index(of: layout)
    }
  }

  extension TextSelectionModel {
    var hasText: Bool {
      layoutCollection.stringLength > 0
    }

    var startPosition: TextPosition {
      layoutCollection.startPosition
    }

    var endPosition: TextPosition {
      layoutCollection.endPosition
    }

    func attributedText(in range: TextRange) -> NSAttributedString {
      layoutCollection.attributedText(in: range)
    }

    func text(in range: TextRange) -> String {
      attributedText(in: range).string
    }

    func position(from position: TextPosition, offset: Int) -> TextPosition? {
      layoutCollection.position(from: position, offset: offset)
    }

    func offset(from: TextPosition, to: TextPosition) -> Int {
      layoutCollection.characterIndex(at: to) - layoutCollection.characterIndex(at: from)
    }

    func firstRect(for range: TextRange) -> CGRect {
      layoutCollection.firstRect(for: range)
    }

    func caretRect(for position: TextPosition) -> CGRect {
      layoutCollection.caretRect(for: position)
    }

    func selectionRects(for range: TextRange) -> [TextSelectionRect] {
      layoutCollection.selectionRects(for: range)
    }

    func selectionRects(for range: TextRange, layout: Text.Layout) -> [TextSelectionRect] {
      layoutCollection.selectionRects(for: range, layout: layout)
    }

    func closestPosition(to point: CGPoint) -> TextPosition? {
      layoutCollection.closestPosition(to: point)
    }

    func closestPosition(to point: CGPoint, within range: TextRange) -> TextPosition? {
      guard let position = closestPosition(to: point) else { return nil }
      if position <= range.start { return range.start }
      if position >= range.end { return range.end }
      return position
    }

    func isPositionAtBlockBoundary(_ position: TextPosition) -> Bool {
      layoutCollection.isPositionAtBlockBoundary(position)
    }

    func positionAbove(_ position: TextPosition, anchor: TextPosition) -> TextPosition? {
      layoutCollection.positionAbove(position, anchor: anchor)
    }

    func positionBelow(_ position: TextPosition, anchor: TextPosition) -> TextPosition? {
      layoutCollection.positionBelow(position, anchor: anchor)
    }

    func characterRange(at point: CGPoint) -> TextRange? {
      layoutCollection.characterRange(at: point)
    }

    /// Moves from `position` in a layout direction by `offset` steps.
    ///
    /// - Returns: `nil` when `offset` is negative or the move would leave the document.
    ///   A zero `offset` returns `position` unchanged.
    func position(
      from position: TextPosition,
      in direction: TextLayoutNavigationDirection,
      offset: Int
    ) -> TextPosition? {
      guard offset >= 0 else {
        return nil
      }
      guard offset > 0 else {
        return position
      }

      switch direction {
      case .left:
        return self.position(from: position, offset: -offset)
      case .right:
        return self.position(from: position, offset: offset)
      case .up:
        var current = position
        for _ in 0..<offset {
          guard let next = positionAbove(current, anchor: position), next != current else {
            return current
          }
          current = next
        }
        return current
      case .down:
        var current = position
        for _ in 0..<offset {
          guard let next = positionBelow(current, anchor: position), next != current else {
            return current
          }
          current = next
        }
        return current
      }
    }

    /// Returns the farthest endpoint of `range` in the given layout direction, using caret geometry.
    func farthestPosition(
      within range: TextRange,
      in direction: TextLayoutNavigationDirection
    ) -> TextPosition {
      if range.isCollapsed {
        return range.start
      }

      let startRect = caretRect(for: range.start)
      let endRect = caretRect(for: range.end)

      switch direction {
      case .left:
        return startRect.midX <= endRect.midX ? range.start : range.end
      case .right:
        return startRect.midX >= endRect.midX ? range.start : range.end
      case .up:
        return startRect.midY <= endRect.midY ? range.start : range.end
      case .down:
        return startRect.midY >= endRect.midY ? range.start : range.end
      }
    }

    /// Returns a one-unit range extending from `position` in `direction`, or `nil` if it cannot move.
    func characterRange(
      byExtending position: TextPosition,
      in direction: TextLayoutNavigationDirection
    ) -> TextRange? {
      guard
        let adjacent = self.position(from: position, in: direction, offset: 1),
        adjacent != position
      else {
        return nil
      }
      return TextRange(from: position, to: adjacent)
    }

    /// Moves the caret in `direction`, or collapses a non-empty selection to its farthest endpoint
    /// in that direction (matching AppKit arrow-key behavior without Shift).
    ///
    /// - Returns: `false` when there is no selection, or a collapsed caret cannot move further.
    @discardableResult
    func moveSelection(in direction: TextLayoutNavigationDirection) -> Bool {
      guard let selectedRange else {
        return false
      }

      if selectedRange.isCollapsed {
        guard
          let next = position(from: selectedRange.start, in: direction, offset: 1),
          next != selectedRange.start
        else {
          return false
        }
        self.selectedRange = TextRange(start: next, end: next)
        return true
      }

      let collapsed = farthestPosition(within: selectedRange, in: direction)
      self.selectedRange = TextRange(start: collapsed, end: collapsed)
      return true
    }

    /// Collapses the selection to `position` when non-empty, otherwise applies `transform` to the caret.
    @discardableResult
    func moveSelection(
      collapsingTo collapsingPosition: (TextRange) -> TextPosition,
      orTransform transform: (TextPosition) -> TextPosition?
    ) -> Bool {
      guard let selectedRange else {
        return false
      }

      if !selectedRange.isCollapsed {
        let collapsed = collapsingPosition(selectedRange)
        self.selectedRange = TextRange(start: collapsed, end: collapsed)
        return true
      }

      guard let next = transform(selectedRange.start), next != selectedRange.start else {
        return false
      }
      self.selectedRange = TextRange(start: next, end: next)
      return true
    }

    func blockStart(for position: TextPosition) -> TextPosition? {
      layoutCollection.blockStart(for: position)
    }

    func blockEnd(for position: TextPosition) -> TextPosition? {
      layoutCollection.blockEnd(for: position)
    }

    func blockRange(for position: TextPosition) -> TextRange? {
      layoutCollection.blockRange(for: position)
    }

    @available(macOS 10.0, *)
    @available(iOS, unavailable)
    @available(visionOS, unavailable)
    func wordRange(for position: TextPosition) -> TextRange? {
      layoutCollection.wordRange(for: position)
    }

    @available(macOS 10.0, *)
    @available(iOS, unavailable)
    @available(visionOS, unavailable)
    func nextWord(from position: TextPosition) -> TextPosition? {
      layoutCollection.nextWord(from: position)
    }

    @available(macOS 10.0, *)
    @available(iOS, unavailable)
    @available(visionOS, unavailable)
    func previousWord(from position: TextPosition) -> TextPosition? {
      layoutCollection.previousWord(from: position)
    }
  }
#endif
