# Changelog

## 0.10.4

- No API changes. Diagnostic verbose CI publish run.

## 0.10.3

- No API changes. Verify CI OIDC publish after pub.dev config fix.

## 0.10.2

- No API changes. Retry CI OIDC publish via `dart pub publish`.

## 0.10.1

- No API changes. Re-release to verify automated (OIDC) publishing from CI;
  0.10.0 was published manually.

## 0.10.0

- Add at-rest encryption: `encrypt(plaintext, publicKeyPem)` and
  `decrypt(envelope, privateKeyPem)` produce/open MailKite's hybrid envelope
  (RSA-OAEP-256 wrapping an AES-256-GCM content key), wire-compatible with every
  other MailKite SDK. Adds `pointycastle` + `basic_utils`.

## 0.1.0

- Initial release. Client-side MailKite SDK: a user signs into their own MailKite
  account via OAuth 2.1 + PKCE (`flutter_web_auth_2`) and the resulting token drives
  the API. Includes the generated method surface, secure token storage
  (`flutter_secure_storage`), webhook signature verification, and reply helpers.
