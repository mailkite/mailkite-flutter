// Verifies at-rest encryption is wire-compatible with the reference vector (produced by the Node
// SDK) and round-trips locally. Pure Dart — runs under `dart test`.
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:mailkite_client/src/encryption.dart';

void main() {
  test('decrypts the reference vector and round-trips', () {
    final vec = jsonDecode(File('../../spec/encryption-vectors.json').readAsStringSync()) as Map<String, dynamic>;
    final pt = vec['plaintext'] as String;
    final pub = vec['publicKeyPem'] as String;
    final priv = vec['privateKeyPem'] as String;
    final env = vec['envelope'] as String;

    expect(decrypt(env, priv), pt, reason: 'decrypt(reference envelope)');
    expect(decrypt(encrypt(pt, pub), priv), pt, reason: 'round-trip');
    expect(decrypt(encrypt('dart→node', pub), priv), 'dart→node');
  });
}
