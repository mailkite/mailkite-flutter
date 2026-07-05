// Docs: docs/architecture/client-side-oauth-libraries.md
// Pure-logic unit tests — run with `dart test` (or `flutter test`), no device.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mailkite_client/src/oauth.dart';
import 'package:test/test.dart';

void main() {
  test('PKCE: challenge is base64url(SHA-256(verifier)), unpadded', () {
    final p = createPkce();
    final expected = base64Url
        .encode(sha256.convert(utf8.encode(p.verifier)).bytes)
        .replaceAll('=', '');
    expect(p.challenge, expected);
    expect(RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(p.verifier), isTrue);
    expect(p.verifier.length, 43); // base64url of 32 bytes, unpadded
    expect(p.state, isNotEmpty);
  });

  test('PKCE: each call is unique', () {
    final a = createPkce();
    final b = createPkce();
    expect(a.verifier, isNot(b.verifier));
    expect(a.state, isNot(b.state));
  });

  test('authorizeUrl carries the PKCE challenge + S256 + scope', () {
    final cfg = OAuthConfig(
      issuer: 'https://mcp.mailkite.dev',
      clientId: 'cli_1',
      redirectUri: 'mailkite-cli_1://callback',
    );
    final p = createPkce();
    final u = Uri.parse(authorizeUrl(cfg, p));
    expect('${u.origin}${u.path}', 'https://mcp.mailkite.dev/oauth/authorize');
    expect(u.queryParameters['response_type'], 'code');
    expect(u.queryParameters['code_challenge_method'], 'S256');
    expect(u.queryParameters['code_challenge'], p.challenge);
    expect(u.queryParameters['state'], p.state);
    expect(u.queryParameters['scope'], 'mcp');
    expect(u.queryParameters['redirect_uri'], 'mailkite-cli_1://callback');
  });
}
