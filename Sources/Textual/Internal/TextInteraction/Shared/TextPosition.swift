#if TEXTUAL_ENABLE_TEXT_SELECTION
  import Foundation

  // MARK: - Overview
  //
  // `TextPosition` identifies a caret position inside the resolved text layout.
  //
  // Positions are expressed as an `IndexPath` into the layout tree (layout → line → run → slice).
  // `Affinity` disambiguates positions that sit exactly on a boundary, like the end of a line or
  // the edge between two run slices. That extra bit of information makes range comparisons and
  // containment behave consistently when the same visual location can map to two adjacent indices.
  //
  // ## Invariants
  //
  // - `indexPath.layout` indexes a fragment in `TextLayoutCollection.layouts` (one SwiftUI
  //   `Text` fragment / block). Nested lines/runs/slices are local to that layout.
  // - `Affinity.downstream` is the leading edge of a slice (lower character bound);
  //   `.upstream` is the trailing edge (upper bound). Equal index paths compare by affinity.
  // - Character offsets used for text ops are derived from the layout’s attributed string,
  //   not from visual geometry. Geometry may change without changing character identity.
  // - Across layout rebuilds (including streaming flushes), selection reconciliation maps each
  //   endpoint by `(layoutIndex, localCharacterIndex)`. Growing the layout list preserves
  //   selections that still land in an existing layout; removing a layout clears endpoints
  //   that pointed into it.

  struct TextPosition: Hashable, Comparable, CustomStringConvertible {
    enum Affinity: Comparable {
      case downstream  // leading edge in the current layout direction
      case upstream  // trailing edge
    }

    let indexPath: IndexPath
    let affinity: Affinity

    var description: String {
      let path = "(\(indexPath.map(\.description).joined(separator: ", ")))"
      switch affinity {
      case .downstream:
        return "^\(path)"
      case .upstream:
        return "\(path)^"
      }
    }

    static func < (lhs: TextPosition, rhs: TextPosition) -> Bool {
      if lhs.indexPath == rhs.indexPath {
        return lhs.affinity < rhs.affinity
      }
      return lhs.indexPath < rhs.indexPath
    }
  }
#endif
