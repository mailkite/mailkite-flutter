// Docs: docs/architecture/client-side-oauth-libraries.md
//
// The MailKite client core. Pure Dart: it extends the generated method surface
// and implements `request()` over an injected `http.Client`, so the whole
// transport + OAuth state machine is exercisable under `dart test` with a
// MockClient. The Flutter-only pieces (secure storage, opening the system
// browser) are passed in from `flutter.dart` — this file imports no plugins.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'exception.dart';
import 'methods.generated.dart';
import 'oauth.dart';
import 'storage.dart';
import 'webhook.dart' as webhook;

const String _defaultBaseUrl = 'https://api.mailkite.dev';
const String _defaultIssuer = 'https://mcp.mailkite.dev';

class _PkceStash {
  final Pkce pkce;
  final String clientId;
  const _PkceStash(this.pkce, this.clientId);
}

/// Drives the MailKite API as a signed-in user (OAuth 2.1 + PKCE) or with any
/// bearer token you already hold. The generated methods (`send`, `listDomains`,
/// …) all route through [request].
class MailKiteClient extends GeneratedMethods {
  final http.Client _http;
  final bool _ownsHttp;
  final String baseUrl;

  /// Where tokens persist. Defaults to in-memory; pass `SecureStorageTokenStore`
  /// (from `flutter.dart`) in a real app.
  final TokenStore store;

  final OAuthConfig _oauth;

  /// Opens the auth URL in the system browser and resolves to the full redirect
  /// URL (`…?code=&state=`). Supplied by `flutter.dart` (flutter_web_auth_2).
  final Future<String> Function(String url)? openAuthUrl;

  final String? _staticToken;
  _PkceStash? _stash;

  MailKiteClient({
    String? redirectUri,
    String? clientId,
    String baseUrl = _defaultBaseUrl,
    String issuer = _defaultIssuer,
    String? scope,
    TokenStore? store,
    String? token,
    this.openAuthUrl,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client(),
       _ownsHttp = httpClient == null,
       baseUrl = _trimSlash(baseUrl),
       store = store ?? MemoryTokenStore(),
       _staticToken = token,
       _oauth = OAuthConfig(
         issuer: _trimSlash(issuer),
         clientId: clientId,
         // Native custom-scheme redirect when a client id is known up front.
         redirectUri:
             redirectUri ??
             (clientId != null ? 'mailkite-$clientId://callback' : ''),
         scope: scope,
       );

  /// Construct a client from a token you already hold (API key or access token).
  factory MailKiteClient.withToken(
    String token, {
    String baseUrl = _defaultBaseUrl,
    http.Client? httpClient,
  }) => MailKiteClient(token: token, baseUrl: baseUrl, httpClient: httpClient);

  /// The current OAuth client id, once registered/provided.
  String? get clientId => _oauth.clientId;

  /// The redirect URI in use — its scheme is the `callbackUrlScheme` for
  /// flutter_web_auth_2 (everything before `://`).
  String get redirectUri => _oauth.redirectUri;

  // --- Auth -----------------------------------------------------------------

  /// Step 1 of the redirect flow: returns the URL to send the user to.
  /// Registers a client id on first use.
  Future<String> beginLogin() async {
    if (_oauth.redirectUri.isEmpty) {
      throw StateError('Provide a clientId or redirectUri to log in');
    }
    _oauth.clientId ??= await registerClient(_http, _oauth);
    final pkce = createPkce();
    _stash = _PkceStash(pkce, _oauth.clientId!);
    return authorizeUrl(_oauth, pkce);
  }

  /// Step 2 of the redirect flow: pass the redirect URL (or its query string)
  /// the browser came back with. Verifies state, exchanges the code, stores tokens.
  Future<void> completeLogin(String redirectUrlOrQuery) async {
    final params = _parseCallback(redirectUrlOrQuery);
    final err = params['error'];
    if (err != null) {
      throw MailKiteException(
        0,
        'Authorization failed: ${params['error_description'] ?? err}',
      );
    }
    final code = params['code'];
    final state = params['state'];
    final stash = _stash;
    if (stash == null) {
      throw StateError('No login in progress (missing PKCE state)');
    }
    if (code == null || state == null || state != stash.pkce.state) {
      throw StateError('State mismatch — possible CSRF; aborting');
    }
    _oauth.clientId = stash.clientId;
    final tokens = await exchangeCode(_http, _oauth, code, stash.pkce.verifier);
    await store.save(tokens);
    _stash = null;
  }

  /// One-call login: opens the auth URL via [openAuthUrl] (flutter_web_auth_2)
  /// and completes the exchange. Requires [openAuthUrl].
  Future<void> login() async {
    final opener = openAuthUrl;
    if (opener == null) {
      throw StateError(
        'login() needs openAuthUrl — use beginLogin()/completeLogin() instead',
      );
    }
    final url = await beginLogin();
    final redirectUrl = await opener(url);
    await completeLogin(redirectUrl);
  }

  /// Revoke the refresh token and clear local storage.
  Future<void> logout() async {
    final t = await store.load();
    if (t?.refreshToken != null && _oauth.clientId != null) {
      try {
        await revoke(_http, _oauth, t!.refreshToken!);
      } catch (_) {}
    }
    await store.clear();
  }

  Future<bool> isAuthenticated() async =>
      _staticToken != null || (await store.load()) != null;

  // --- Transport ------------------------------------------------------------

  /// Low-level request used by every generated method. Injects the bearer
  /// token, refreshes it when expired or on 401, and surfaces 429 Retry-After.
  @override
  Future<dynamic> request(String method, String path, [Object? body]) {
    return _dispatch(
      method,
      baseUrl + path,
      headers: body != null ? {'Content-Type': 'application/json'} : {},
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<dynamic> _dispatch(
    String method,
    String url, {
    required Map<String, String> headers,
    Object? body,
    bool retried = false,
  }) async {
    final token = await _bearer();
    final req = http.Request(method, Uri.parse(url));
    req.headers.addAll(headers);
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    if (body is String) {
      req.body = body;
    } else if (body is List<int>) {
      req.bodyBytes = body;
    }

    final res = await http.Response.fromStream(await _http.send(req));

    if (res.statusCode == 401 &&
        !retried &&
        _staticToken == null &&
        await _tryRefresh()) {
      return _dispatch(
        method,
        url,
        headers: headers,
        body: body,
        retried: true,
      );
    }
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    final text = res.body;
    final data = text.isNotEmpty ? _safeJson(text) : null;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : ((res.reasonPhrase?.isNotEmpty ?? false)
                ? res.reasonPhrase!
                : 'HTTP ${res.statusCode}');
      int? retryAfter;
      if (res.statusCode == 429) {
        final ra = res.headers['retry-after'];
        if (ra != null) retryAfter = int.tryParse(ra);
      }
      throw MailKiteException(
        res.statusCode,
        msg,
        body: data,
        retryAfter: retryAfter,
      );
    }
    return data;
  }

  /// Current valid access token, refreshing if expired.
  Future<String?> _bearer() async {
    if (_staticToken != null) return _staticToken;
    var t = await store.load();
    if (t != null && t.expiresAt <= DateTime.now().millisecondsSinceEpoch) {
      await _tryRefresh();
      t = await store.load();
    }
    return t?.accessToken;
  }

  Future<bool> _tryRefresh() async {
    final t = await store.load();
    if (t?.refreshToken == null || _oauth.clientId == null) return false;
    try {
      final next = await refreshTokens(_http, _oauth, t!.refreshToken!);
      await store.save(next);
      return true;
    } catch (_) {
      await store.clear();
      return false;
    }
  }

  // --- Hand-written methods (special transport / local crypto) --------------

  /// Upload a file and get a time-limited URL to reference in send(). Pass a
  /// remote [url], base64 [content], or raw [bytes] (`List<int>`/`Uint8List`).
  Future<Map<String, dynamic>> uploadAttachment({
    String? filename,
    String? url,
    String? content,
    List<int>? bytes,
    String? contentType,
    int? retentionDays,
  }) async {
    if (url != null) {
      return (await request(
            'POST',
            '/v1/attachments',
            _compact({
              'url': url,
              'filename': filename,
              'contentType': contentType,
              'retentionDays': retentionDays,
            }),
          ))
          as Map<String, dynamic>;
    }
    if (bytes != null) {
      final q = <String, String>{'filename': filename ?? 'file'};
      if (retentionDays != null) q['retentionDays'] = '$retentionDays';
      final uri = Uri.parse(
        '$baseUrl/v1/attachments',
      ).replace(queryParameters: q).toString();
      return (await _dispatch(
            'POST',
            uri,
            headers: {
              'Content-Type': contentType ?? 'application/octet-stream',
            },
            body: bytes,
          ))
          as Map<String, dynamic>;
    }
    if (content != null) {
      return (await request(
            'POST',
            '/v1/attachments',
            _compact({
              'content': content,
              'filename': filename,
              'contentType': contentType,
              'retentionDays': retentionDays,
            }),
          ))
          as Map<String, dynamic>;
    }
    throw MailKiteException(
      0,
      'uploadAttachment needs one of: url, content, or bytes',
    );
  }

  /// Verify an inbound webhook's `x-mailkite-signature` header (HMAC-SHA256).
  /// Local — no network, no token. [payload] is a `String` or bytes.
  bool verifyWebhook(
    String signature,
    Object payload,
    String secret, {
    int toleranceMs = webhook.kDefaultToleranceMs,
  }) => webhook.verifyWebhook(
    signature,
    payload,
    secret,
    toleranceMs: toleranceMs,
  );

  String replyOk() => webhook.replyOk();
  String replySpam() => webhook.replySpam();
  String replyDrop() => webhook.replyDrop();
  String replyBlockSender() => webhook.replyBlockSender();

  /// Close the underlying HTTP client (only if this client created it).
  void close() {
    if (_ownsHttp) _http.close();
  }
}

// --- helpers ------------------------------------------------------------------

String _trimSlash(String s) => s.replaceAll(RegExp(r'/+$'), '');

Map<String, String> _parseCallback(String input) {
  final qIndex = input.indexOf('?');
  final query = qIndex >= 0 ? input.substring(qIndex + 1) : input;
  return Uri.splitQueryString(query);
}

dynamic _safeJson(String text) {
  try {
    return jsonDecode(text);
  } catch (_) {
    return text;
  }
}

Map<String, dynamic> _compact(Map<String, dynamic> m) {
  final out = <String, dynamic>{};
  m.forEach((k, v) {
    if (v != null) out[k] = v;
  });
  return out;
}
