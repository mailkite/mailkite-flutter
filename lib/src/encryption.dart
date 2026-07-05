// Docs: docs/architecture/client-side-oauth-libraries.md
//
// At-rest encryption — MailKite's hybrid envelope (RSA-OAEP-256 wraps a fresh AES-256-GCM content
// key). Pure Dart (pointycastle), so it runs under `dart test`. Wire-compatible with every other
// MailKite SDK: what this encrypts, `MailKite.decrypt` in any SDK opens, and vice-versa. You encrypt
// with your SPKI/PEM public key; only the PKCS8/PEM private-key holder can decrypt.
// See docs/architecture/at-rest-encryption.md.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';

Uint8List _randomBytes(int n) {
  final rnd = Random.secure();
  return Uint8List.fromList(List<int>.generate(n, (_) => rnd.nextInt(256)));
}

Uint8List _pemToDer(String pem) => base64.decode(
      pem.replaceAll(RegExp(r'-----[^-]+-----'), '').replaceAll(RegExp(r'\s+'), ''),
    );

String _fingerprint(Uint8List spkiDer) =>
    SHA256Digest().process(spkiDer).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

Uint8List _rsaOaep(Uint8List data, RSAAsymmetricKey key, {required bool encrypt}) {
  // SHA-256 for both the OAEP hash and MGF1 — matches Web Crypto / node.
  final cipher = OAEPEncoding.withSHA256(RSAEngine())
    ..init(
      encrypt,
      encrypt
          ? PublicKeyParameter<RSAPublicKey>(key as RSAPublicKey)
          : PrivateKeyParameter<RSAPrivateKey>(key as RSAPrivateKey),
    );
  return cipher.process(data);
}

Uint8List _aesGcm(Uint8List data, Uint8List key, Uint8List iv, {required bool encrypt}) {
  final gcm = GCMBlockCipher(AESEngine())
    ..init(encrypt, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
  return gcm.process(data); // encrypt: body||tag ; decrypt: verifies + strips the tag
}

/// Encrypt a UTF-8 string to a domain's RSA public key (SPKI/PEM), returning the at-rest envelope
/// JSON. A fresh AES-256-GCM content key encrypts the text; the key is wrapped with RSA-OAEP(SHA-256).
/// Local — no network call.
String encrypt(String plaintext, String publicKeyPem) {
  final der = _pemToDer(publicKeyPem);
  final pub = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);

  final contentKey = _randomBytes(32);
  final iv = _randomBytes(12);
  final ciphertext = _aesGcm(Uint8List.fromList(utf8.encode(plaintext)), contentKey, iv, encrypt: true);
  final wrappedKey = _rsaOaep(contentKey, pub, encrypt: true);

  return jsonEncode({
    'v': 1,
    'keyAlg': 'RSA-OAEP-256',
    'fp': _fingerprint(der),
    'enc': 'A256GCM',
    'iv': base64.encode(iv),
    'wrappedKey': base64.encode(wrappedKey),
    'ciphertext': base64.encode(ciphertext),
  });
}

/// Decrypt a MailKite at-rest envelope JSON with your RSA private key (PKCS8/PEM), returning the
/// original UTF-8 string. Reverses [encrypt] / MailKite's at-rest encryption. Local — no network call.
String decrypt(String envelope, String privateKeyPem) {
  final env = jsonDecode(envelope) as Map<String, dynamic>;
  final priv = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem); // PKCS#8 PEM

  final rawKey = _rsaOaep(base64.decode(env['wrappedKey'] as String), priv, encrypt: false);
  final plaintext = _aesGcm(base64.decode(env['ciphertext'] as String), rawKey, base64.decode(env['iv'] as String), encrypt: false);
  return utf8.decode(plaintext);
}
