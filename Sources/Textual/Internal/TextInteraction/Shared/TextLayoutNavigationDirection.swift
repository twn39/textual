#if TEXTUAL_ENABLE_TEXT_SELECTION
  import Foundation

  /// Layout-relative navigation used by platform text-input adapters (UIKit/AppKit).
  ///
  /// Horizontal directions follow storage order (matching AppKit move left/right), while vertical
  /// directions preserve the caret’s visual anchor via `positionAbove` / `positionBelow`.
  enum TextLayoutNavigationDirection: Hashable, Sendable {
    case left
    case right
    case up
    case down
  }
#endif
