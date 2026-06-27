// Docs: docs/architecture/client-side-oauth-libraries.md
//
// The Flutter-plugin bits, kept out of the pure core so `dart test` never needs
// a device: a [TokenStore] backed by flutter_secure_storage (OS Keychain /
// Keystore), an [openAuthUrl] adapter over flutter_web_auth_2, and a one-call
// [mailKiteClient] factory that wires them together with the native custom-scheme
// redirect (`mailkite-<clientId>://callback`).

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'client.dart';
import 'oauth.dart';
import 'storage.dart';

/// Persists the [TokenSet] in the OS secure enclave via flutter_secure_storage.
class SecureStorageTokenStore implements TokenStore {
  final FlutterSecureStorage _storage;
  final String key;

  SecureStorageTokenStore({
    FlutterSecureStorage? storage,
    this.key = 'mailkite.tokens',
  }) : _storage =
           storage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           );

  @override
  Future<TokenSet?> load() async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    return TokenSet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(TokenSet tokens) =>
      _storage.write(key: key, value: jsonEncode(tokens.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: key);
}

/// An [openAuthUrl] adapter: opens the system browser and returns the redirect
/// URL once it hits the custom scheme. [callbackUrlScheme] is everything before
/// `://` in the redirect URI (e.g. `mailkite-<clientId>`).
Future<String> Function(String url) flutterWebAuthOpener(
  String callbackUrlScheme,
) =>
    (url) => FlutterWebAuth2.authenticate(
      url: url,
      callbackUrlScheme: callbackUrlScheme,
    );

/// Build a fully-wired client for a Flutter app: secure storage + system-browser
/// login with the native `mailkite-<clientId>://callback` redirect. Supply your
/// pre-provisioned public [clientId].
MailKiteClient mailKiteClient({
  required String clientId,
  String? scope,
  String baseUrl = 'https://api.mailkite.dev',
  String issuer = 'https://mcp.mailkite.dev',
  TokenStore? store,
}) {
  final scheme = 'mailkite-$clientId';
  return MailKiteClient(
    clientId: clientId,
    redirectUri: '$scheme://callback',
    scope: scope,
    baseUrl: baseUrl,
    issuer: issuer,
    store: store ?? SecureStorageTokenStore(),
    openAuthUrl: flutterWebAuthOpener(scheme),
  );
}
