#if TEXTUAL_ENABLE_TEXT_SELECTION
  import Foundation

  // MARK: - Overview
  //
  // Platform menus and command validation should consult this capability snapshot instead of
  // re-encoding selection rules in AppKit/UIKit adapters. Keep semantics here; keep wiring
  // (selectors, menu construction) in the platform views.

  struct TextSelectionCapabilities: Equatable {
    var canSelectAll: Bool
    var canCopy: Bool
    var canNavigate: Bool

    init(hasText: Bool, selectedRange: TextRange?) {
      canSelectAll = hasText
      canCopy = selectedRange.map { !$0.isCollapsed } ?? false
      canNavigate = selectedRange != nil
    }

    init(model: TextSelectionModel) {
      self.init(hasText: model.hasText, selectedRange: model.selectedRange)
    }
  }
#endif
