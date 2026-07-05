// Docs: docs/architecture/client-side-oauth-libraries.md
// Pure-logic unit tests — run with `dart test` (or `flutter test`), no device.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mailkite_client/src/webhook.dart';
import 'package:test/test.dart';

String sign(int t, String secret, String payload) => Hmac(
  sha256,
  utf8.encode(secret),
).convert(utf8.encode('$t.$payload')).toString();

void main() {
  const secret = 'whsec_test';
  final payload = jsonEncode({'event': 'inbound', 'id': 'msg_9'});

  test('verifyWebhook accepts a valid server signature', () {
    final t = DateTime.now().millisecondsSinceEpoch;
    final sig = 't=$t,v1=${sign(t, secret, payload)}';
    expect(verifyWebhook(sig, payload, secret), isTrue);
    // bytes payload works too
    expect(verifyWebhook(sig, utf8.encode(payload), secret), isTrue);
  });

  test('verifyWebhook rejects tampering, wrong secret, and stale events', () {
    final t = DateTime.now().millisecondsSinceEpoch;
    final v1 = sign(t, secret, payload);
    final sig = 't=$t,v1=$v1';
    expect(verifyWebhook(sig, '${payload}x', secret), isFalse); // tampered body
    expect(verifyWebhook(sig, payload, 'wrong'), isFalse); // wrong secret
    final stale = t - 10 * 60 * 1000;
    expect(verifyWebhook('t=$stale,v1=$v1', payload, secret), isFalse); // stale
  });

  test('verifyWebhook rejects malformed signatures', () {
    expect(verifyWebhook('', payload, secret), isFalse);
    expect(verifyWebhook('v1=abc', payload, secret), isFalse); // no t
    expect(verifyWebhook('t=notanumber,v1=abc', payload, secret), isFalse);
  });

  test('reply helpers are the canonical control strings', () {
    expect(replyOk(), '{"status":"ok"}');
    expect(replySpam(), '{"status":"spam"}');
    expect(replyDrop(), '{"status":"drop"}');
    expect(
      replyBlockSender(),
      '{"status":"ok","actions":[{"type":"block-sender"}]}',
    );
  });
}
