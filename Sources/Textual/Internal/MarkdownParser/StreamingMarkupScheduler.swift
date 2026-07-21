import Foundation

/// Coalesces rapid markup updates for streaming rendering.
///
/// When ``StreamingUpdates/disabled``, each update flushes immediately with the raw markup.
/// When coalesced, updates replace a pending value and flush after `interval`, running
/// ``SoftIncompleteMarkdown/prepare(_:)`` first.
@MainActor
final class StreamingMarkupScheduler {
  private var pendingMarkup: String?
  private var task: Task<Void, Never>?
  private let onFlush: (String) -> Void

  init(onFlush: @escaping (String) -> Void) {
    self.onFlush = onFlush
  }

  /// Schedules or immediately applies a markup update according to `policy`.
  func update(_ markup: String, policy: StreamingUpdates) {
    switch policy {
    case .disabled:
      task?.cancel()
      task = nil
      pendingMarkup = nil
      onFlush(markup)

    case .coalesced(let interval):
      pendingMarkup = markup
      task?.cancel()
      task = Task { [weak self] in
        do {
          try await Task.sleep(for: interval)
        } catch {
          return
        }
        guard !Task.isCancelled else {
          return
        }
        self?.flushPending()
      }
    }
  }

  /// Immediately flushes any pending coalesced markup.
  func flush() {
    task?.cancel()
    task = nil
    flushPending()
  }

  private func flushPending() {
    guard let pendingMarkup else {
      return
    }
    self.pendingMarkup = nil
    onFlush(SoftIncompleteMarkdown.prepare(pendingMarkup))
  }
}
