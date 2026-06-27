// Docs: docs/architecture/client-side-oauth-libraries.md
//
// OAuth 2.1 Authorization-Code + PKCE against MailKite's existing OAuth server
// (api/src/oauth/server.ts). Pure Dart — `dart:math`/`dart:convert` + `crypto`
// for PKCE and an injected `http.Client` for the network, so this whole file
// runs under plain `dart test` with no Flutter plugins or device.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'exception.dart';

const _defaultScope = 'mcp';

String _base64Url(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

Uint8List _randomBytes(int n) {
  final rnd = Random.secure();
  final b = Uint8List(n);
  for (var i = 0; i < n; i++) {
    b[i] = rnd.nextInt(256);
  }
  return b;
}

/// A PKCE pair + CSRF `state` for one authorization request.
class Pkce {
  final String verifier;
  final String challenge;
  final String state;

  const Pkce(this.verifier, this.challenge, this.state);
}

/// verifier = base64url(32 random bytes); challenge = base64url(SHA-256(verifier));
/// state = base64url(16 random bytes). All base64url is unpadded.
Pkce createPkce() {
  final verifier = _base64Url(_randomBytes(32)); // 43 chars, unreserved
  final challenge = _base64Url(sha256.convert(utf8.encode(verifier)).bytes);
  final state = _base64Url(_randomBytes(16));
  return Pkce(verifier, challenge, state);
}

/// OAuth endpoints + the public client id this app uses.
class OAuthConfig {
  /// `mcp.mailkite.dev` issuer base, e.g. `https://mcp.mailkite.dev`.
  String issuer;

  /// Public client id (pre-provisioned or from dynamic registration).
  String? clientId;
  String redirectUri;

  /// Defaults to `mcp` (full account; the only scope today).
  String? scope;

  OAuthConfig({
    required this.issuer,
    this.clientId,
    required this.redirectUri,
    this.scope,
  });
}

/// A stored set of tokens. `expiresAt` is epoch ms (already includes a safety margin).
class TokenSet {
  final String accessToken;
  final String? refreshToken;
  final int expiresAt;
  final String tokenType;

  const TokenSet({
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
    this.tokenType = 'Bearer',
  });

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    if (refreshToken != null) 'refreshToken': refreshToken,
    'expiresAt': expiresAt,
    'tokenType': tokenType,
  };

  factory TokenSet.fromJson(Map<String, dynamic> j) => TokenSet(
    accessToken: j['accessToken'] as String,
    refreshToken: j['refreshToken'] as String?,
    expiresAt: (j['expiresAt'] as num).toInt(),
    tokenType: (j['tokenType'] as String?) ?? 'Bearer',
  );
}

/// RFC 7591 dynamic client registration — returns a public `client_id`.
Future<String> registerClient(
  http.Client client,
  OAuthConfig cfg, {
  String clientName = 'MailKite Flutter Client',
}) async {
  final res = await client.post(
    Uri.parse('${cfg.issuer}/oauth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'client_name': clientName,
      'redirect_uris': [cfg.redirectUri],
      'token_endpoint_auth_method': 'none', // public client, PKCE-protected
      'grant_types': ['authorization_code', 'refresh_token'],
      'response_types': ['code'],
    }),
  );
  if (res.statusCode < 200 || res.statusCode >= 300) throw _oauthError(res);
  final body = jsonDecode(res.body) as Map<String, dynamic>;
  return body['client_id'] as String;
}

/// Build the `/oauth/authorize` URL the user is sent to.
String authorizeUrl(OAuthConfig cfg, Pkce pkce) {
  final u = Uri.parse('${cfg.issuer}/oauth/authorize').replace(
    queryParameters: <String, String>{
      'response_type': 'code',
      'client_id': cfg.clientId!,
      'redirect_uri': cfg.redirectUri,
      'scope': cfg.scope ?? _defaultScope,
      'state': pkce.state,
      'code_challenge': pkce.challenge,
      'code_challenge_method': 'S256',
    },
  );
  return u.toString();
}

/// Exchange an authorization code for tokens.
Future<TokenSet> exchangeCode(
  http.Client client,
  OAuthConfig cfg,
  String code,
  String verifier,
) => _tokenRequest(client, cfg, {
  'grant_type': 'authorization_code',
  'code': code,
  'redirect_uri': cfg.redirectUri,
  'client_id': cfg.clientId!,
  'code_verifier': verifier,
});

/// Rotate a refresh token for a fresh access token (refresh token rotates too).
Future<TokenSet> refreshTokens(
  http.Client client,
  OAuthConfig cfg,
  String refreshToken,
) => _tokenRequest(client, cfg, {
  'grant_type': 'refresh_token',
  'refresh_token': refreshToken,
  'client_id': cfg.clientId!,
});

/// RFC 7009 revocation — call on logout.
Future<void> revoke(http.Client client, OAuthConfig cfg, String token) async {
  await client.post(
    Uri.parse('${cfg.issuer}/oauth/revoke'),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: _form({'token': token, 'client_id': cfg.clientId!}),
  );
}

Future<TokenSet> _tokenRequest(
  http.Client client,
  OAuthConfig cfg,
  Map<String, String> params,
) async {
  final res = await client.post(
    Uri.parse('${cfg.issuer}/oauth/token'),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: _form(params),
  );
  if (res.statusCode < 200 || res.statusCode >= 300) throw _oauthError(res);
  final b = jsonDecode(res.body) as Map<String, dynamic>;
  final expiresIn = (b['expires_in'] as num?)?.toInt() ?? 3600;
  return TokenSet(
    accessToken: b['access_token'] as String,
    refreshToken: b['refresh_token'] as String?,
    // 30s safety margin so we refresh just before the server considers it dead.
    expiresAt: DateTime.now().millisecondsSinceEpoch + expiresIn * 1000 - 30000,
    tokenType: (b['token_type'] as String?) ?? 'Bearer',
  );
}

String _form(Map<String, String> m) => m.entries
    .map(
      (e) =>
          '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
    )
    .join('&');

MailKiteException _oauthError(http.Response res) {
  var detail = res.reasonPhrase ?? 'error';
  try {
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    detail = (j['error_description'] ?? j['error'] ?? detail).toString();
  } catch (_) {}
  return MailKiteException(res.statusCode, 'OAuth ${res.statusCode}: $detail');
}
