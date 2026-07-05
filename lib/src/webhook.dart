// Docs: docs/architecture/client-side-oauth-libraries.md
//
// Local webhook helpers — no network, no token. [verifyWebhook] validates the
// `x-mailkite-signature` header (HMAC-SHA256 over `'$t.' + payload`); the reply
// helpers return the canonical control strings a webhook consumer sends back.
// Pure Dart (`crypto`) so it runs under `dart test`.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Default freshness window: 5 minutes.
const int kDefaultToleranceMs = 5 * 60 * 1000;

/// Verify the `x-mailkite-signature` header on an inbound webhook delivery.
///
/// [payload] may be the raw body as a `String` or as bytes (`List<int>`).
/// Signature format is `t=<ms>,v1=<hex>`. Returns true only when the HMAC
/// matches and the event is within [toleranceMs] of now (set 0 to skip the
/// freshness check).
bool verifyWebhook(
  String signature,
  Object payload,
  String secret, {
  int toleranceMs = kDefaultToleranceMs,
}) {
  if (signature.isEmpty) return false;

  final parts = <String, String>{};
  for (final seg in signature.split(',')) {
    final i = seg.indexOf('=');
    if (i != -1) {
      parts[seg.substring(0, i).trim()] = seg.substring(i + 1).trim();
    }
  }
  final tStr = parts['t'];
  final v1 = parts['v1'];
  if (tStr == null || v1 == null) return false;
  final t = int.tryParse(tStr);
  if (t == null) return false;

  if (toleranceMs > 0 &&
      (DateTime.now().millisecondsSinceEpoch - t).abs() > toleranceMs) {
    return false;
  }

  final payloadBytes = payload is String
      ? utf8.encode(payload)
      : (payload as List<int>);
  final builder = BytesBuilder()
    ..add(utf8.encode('$t.'))
    ..add(payloadBytes);
  final mac = Hmac(sha256, utf8.encode(secret)).convert(builder.toBytes());
  return _constantTimeEquals(mac.toString(), v1.toLowerCase());
}

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

/// Acknowledge a webhook event — the string `{"status":"ok"}`.
String replyOk() => '{"status":"ok"}';

/// Tell MailKite to mark the message as spam — the string `{"status":"spam"}`.
String replySpam() => '{"status":"spam"}';

/// Tell MailKite to drop (discard) the message — the string `{"status":"drop"}`.
String replyDrop() => '{"status":"drop"}';

/// Tell MailKite to block the sender —
/// `{"status":"ok","actions":[{"type":"block-sender"}]}`.
String replyBlockSender() =>
    '{"status":"ok","actions":[{"type":"block-sender"}]}';
