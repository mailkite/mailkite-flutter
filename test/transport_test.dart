// Docs: docs/architecture/client-side-oauth-libraries.md
// Pure-logic unit tests — run with `dart test` (or `flutter test`), no device.
// Drives the client core over a MockClient (no real network).

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mailkite_client/src/client.dart';
import 'package:mailkite_client/src/exception.dart';
import 'package:mailkite_client/src/oauth.dart';
import 'package:mailkite_client/src/types.dart';
import 'package:test/test.dart';

void main() {
  test(
    'request: sends Bearer token, correct verb + path + JSON body',
    () async {
      final requests = <http.Request>[];
      final mk = MailKiteClient.withToken(
        'test_token',
        httpClient: MockClient((req) async {
          requests.add(req);
          return http.Response(
            jsonEncode({'id': 'msg_1', 'status': 'queued'}),
            202,
          );
        }),
      );

      final out = await mk.send(
        const SendMessage(
          from: 'a@app.mailkite.dev',
          to: 'b@example.com',
          subject: 'Hi',
          text: 'yo',
        ),
      );

      expect(out.id, 'msg_1');
      expect(out.status, 'queued');
      expect(requests.single.method, 'POST');
      expect(
        requests.single.url.toString(),
        'https://api.mailkite.dev/v1/send',
      );
      expect(requests.single.headers['Authorization'], 'Bearer test_token');
      expect(jsonDecode(requests.single.body), {
        'from': 'a@app.mailkite.dev',
        'to': 'b@example.com',
        'subject': 'Hi',
        'text': 'yo',
      });
    },
  );

  test('path + query params are URL-encoded', () async {
    final urls = <String>[];
    final mk = MailKiteClient.withToken(
      't',
      httpClient: MockClient((req) async {
        urls.add(req.url.toString());
        return http.Response('{"ok":true}', 200);
      }),
    );

    await mk.getDomain('dom 1');
    await mk.checkDomainAvailability('a b.com');
    expect(urls[0], 'https://api.mailkite.dev/api/domains/dom%201');
    expect(
      urls[1],
      'https://api.mailkite.dev/api/domains/register/check?domain=a%20b.com',
    );
  });

  test(
    'error mapping: non-2xx throws MailKiteException with status + message',
    () async {
      final mk = MailKiteClient.withToken(
        't',
        httpClient: MockClient(
          (req) async =>
              http.Response(jsonEncode({'error': 'bad domain'}), 422),
        ),
      );
      await expectLater(
        () => mk.createDomain({'domain': 'x'}),
        throwsA(
          isA<MailKiteException>()
              .having((e) => e.status, 'status', 422)
              .having((e) => e.message, 'message', 'bad domain'),
        ),
      );
    },
  );

  test('429 surfaces Retry-After seconds', () async {
    final mk = MailKiteClient.withToken(
      't',
      httpClient: MockClient(
        (req) async => http.Response(
          jsonEncode({'error': 'slow down'}),
          429,
          headers: {'retry-after': '30'},
        ),
      ),
    );
    await expectLater(
      () => mk.listMessages(),
      throwsA(
        isA<MailKiteException>()
            .having((e) => e.status, 'status', 429)
            .having((e) => e.retryAfter, 'retryAfter', 30),
      ),
    );
  });

  test('uploadAttachment: remote url goes up as JSON', () async {
    http.Request? captured;
    final mk = MailKiteClient.withToken(
      't',
      httpClient: MockClient((req) async {
        captured = req;
        return http.Response(
          jsonEncode({'url': 'https://files.mailkite.dev/x'}),
          200,
        );
      }),
    );
    await mk.uploadAttachment(
      url: 'https://example.com/a.pdf',
      filename: 'a.pdf',
    );
    expect(captured!.url.toString(), 'https://api.mailkite.dev/v1/attachments');
    expect(jsonDecode(captured!.body), {
      'url': 'https://example.com/a.pdf',
      'filename': 'a.pdf',
    });
  });

  test(
    'uploadAttachment: raw bytes go up as a binary POST with filename query',
    () async {
      http.Request? captured;
      final mk = MailKiteClient.withToken(
        't',
        httpClient: MockClient((req) async {
          captured = req;
          return http.Response(
            jsonEncode({'url': 'https://files.mailkite.dev/y'}),
            200,
          );
        }),
      );
      await mk.uploadAttachment(
        bytes: [1, 2, 3],
        filename: 'a.bin',
        contentType: 'application/pdf',
      );
      expect(
        captured!.url.toString(),
        'https://api.mailkite.dev/v1/attachments?filename=a.bin',
      );
      expect(captured!.headers['Content-Type'], 'application/pdf');
      expect(captured!.bodyBytes, [1, 2, 3]);
    },
  );

  test('login flow: beginLogin registers a client + returns authorize URL; '
      'completeLogin exchanges', () async {
    final mk = MailKiteClient(
      redirectUri: 'https://app.example.com/cb',
      httpClient: MockClient((req) async {
        final u = req.url.toString();
        if (u.endsWith('/oauth/register')) {
          return http.Response(jsonEncode({'client_id': 'cli_123'}), 200);
        }
        if (u.endsWith('/oauth/token')) {
          return http.Response(
            jsonEncode({
              'access_token': 'at_1',
              'refresh_token': 'rt_1',
              'expires_in': 3600,
              'token_type': 'Bearer',
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      }),
    );

    final url = await mk.beginLogin();
    final u = Uri.parse(url);
    expect('${u.origin}${u.path}', 'https://mcp.mailkite.dev/oauth/authorize');
    expect(u.queryParameters['code_challenge_method'], 'S256');
    expect(u.queryParameters['client_id'], 'cli_123');
    final state = u.queryParameters['state'];

    await mk.completeLogin(
      'https://app.example.com/cb?code=auth_code&state=$state',
    );
    expect(await mk.isAuthenticated(), isTrue);
  });

  test('completeLogin rejects a state mismatch (CSRF guard)', () async {
    final mk = MailKiteClient(
      redirectUri: 'https://app.example.com/cb',
      httpClient: MockClient((req) async {
        final u = req.url.toString();
        if (u.endsWith('/oauth/register')) {
          return http.Response(jsonEncode({'client_id': 'c'}), 200);
        }
        return http.Response('{}', 200);
      }),
    );
    await mk.beginLogin();
    await expectLater(
      () => mk.completeLogin('https://app.example.com/cb?code=x&state=WRONG'),
      throwsA(isA<StateError>()),
    );
  });

  test('401 triggers one refresh + retry, then succeeds', () async {
    var calls = 0;
    final mk = MailKiteClient(
      redirectUri: 'https://app.example.com/cb',
      clientId: 'cli_1',
      httpClient: MockClient((req) async {
        final u = req.url.toString();
        if (u.endsWith('/oauth/token')) {
          return http.Response(
            jsonEncode({
              'access_token': 'fresh',
              'refresh_token': 'rt_2',
              'expires_in': 3600,
            }),
            200,
          );
        }
        calls++;
        if (calls == 1) return http.Response('{"error":"expired"}', 401);
        return http.Response('{"ok":true}', 200);
      }),
    );
    // Seed a still-valid token whose refresh will succeed on the 401.
    await mk.store.save(
      TokenSet(
        accessToken: 'stale',
        refreshToken: 'rt_1',
        expiresAt: DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
      ),
    );
    final out = await mk.listMessages();
    expect(out, {'ok': true});
    expect(calls, 2); // original 401 + retried 200
  });
}
