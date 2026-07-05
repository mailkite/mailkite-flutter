// Docs: docs/architecture/client-side-oauth-libraries.md
//
// Where the token set lives between calls. The abstract [TokenStore] keeps the
// client core pure (no Flutter); [MemoryTokenStore] is the in-memory impl used
// by tests. The platform store (`SecureStorageTokenStore`, backed by
// flutter_secure_storage) lives in `flutter.dart` so this file stays dart-test
// runnable.

import 'oauth.dart';

/// Pluggable persistence for the OAuth [TokenSet].
abstract class TokenStore {
  Future<TokenSet?> load();
  Future<void> save(TokenSet tokens);
  Future<void> clear();
}

/// Non-persistent store. The default for tests and stateless usage.
class MemoryTokenStore implements TokenStore {
  TokenSet? _tokens;

  @override
  Future<TokenSet?> load() async => _tokens;

  @override
  Future<void> save(TokenSet tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
