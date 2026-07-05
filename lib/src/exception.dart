// Docs: docs/architecture/client-side-oauth-libraries.md
//
// The one error type every MailKite call can throw. Carries the HTTP [status],
// the parsed [body], and — on a 429 — the [retryAfter] seconds the server asked
// us to wait (forward-compatible with the OAuth-token throttling phase).

/// Thrown when a MailKite request fails (non-2xx) or a local guard trips.
class MailKiteException implements Exception {
  /// HTTP status code (0 for local/client-side errors).
  final int status;

  /// Human-readable message — the server's `error` field when present.
  final String message;

  /// Parsed response body, when there was one.
  final Object? body;

  /// Seconds to wait before retrying, from a 429 `Retry-After` header.
  final int? retryAfter;

  MailKiteException(this.status, this.message, {this.body, this.retryAfter});

  @override
  String toString() => 'MailKiteException($status): $message';
}
