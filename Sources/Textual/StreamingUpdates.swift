import SwiftUI

/// Controls how ``StructuredText`` applies markup updates while content is still growing.
///
/// Use streaming updates when feeding incrementally accumulated markup—for example, tokens from an
/// AI chat completion stream. Rapid changes are coalesced into fewer parse/layout passes, and
/// incomplete Markdown at the trailing edge is softened so mid-stream parsing stays usable.
///
/// ```swift
/// StructuredText(markdown: accumulated)
///   .textual.streamingUpdates(.coalesced)
/// ```
///
/// The default is ``disabled``, which parses every markup change immediately and leaves the
/// source string unchanged—matching Textual’s non-streaming behavior.
///
/// - Important: Streaming updates are not true incremental parsing. Each flush still re-parses the
///   full markup string. Prefer coalescing to bound update rate on long responses.
public enum StreamingUpdates: Hashable, Sendable {
  /// Parse every markup change immediately without softening incomplete Markdown.
  case disabled

  /// Coalesce rapid markup changes and soften incomplete trailing Markdown before parsing.
  ///
  /// - Parameter interval: Minimum delay between parse flushes. Later updates within the interval
  ///   replace the pending markup and restart the timer.
  case coalesced(interval: Duration)

  /// Coalesces updates using an 80ms interval.
  public static var coalesced: StreamingUpdates {
    .coalesced(interval: .milliseconds(80))
  }

  /// Whether streaming coalescing is enabled.
  public var isEnabled: Bool {
    switch self {
    case .disabled:
      false
    case .coalesced:
      true
    }
  }

  /// The coalescing interval when enabled; otherwise `nil`.
  public var interval: Duration? {
    switch self {
    case .disabled:
      nil
    case .coalesced(let interval):
      interval
    }
  }
}

extension EnvironmentValues {
  @usableFromInline
  @Entry var streamingUpdates = StreamingUpdates.disabled
}
