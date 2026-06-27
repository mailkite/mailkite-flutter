# mailkite_client

Client-side MailKite SDK for **Flutter**. Instead of a server API key, your user
**signs into their own MailKite account** with OAuth 2.1 + PKCE (Google / email —
whatever the dashboard supports), and the library gets a short-lived token that
**is** that user. The token then drives the same API the server SDKs expose.

> **Read-only mirror.** This repo is a generated, release-time mirror of the MailKite
> monorepo (the private source of truth); the source isn't developed here. Depend on
> `mailkite_client` from pub.dev rather than cloning. Full docs:
> <https://mailkite.dev/docs/libraries>.
>
> The method surface is generated from the shared MailKite contract — the same as every other MailKite SDK.

## Install

```yaml
# pubspec.yaml
dependencies:
  mailkite_client: ^0.1.0
```

This package depends on [`flutter_web_auth_2`](https://pub.dev/packages/flutter_web_auth_2)
(opens the system browser for sign-in) and
[`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage)
(keeps tokens in the OS Keychain / Keystore). Both need a tiny bit of native
setup — see [Platform setup](#platform-setup).

## Sign in and send

```dart
import 'package:mailkite_client/mailkite_client.dart';

// Use your pre-provisioned public client id. The redirect is the native
// custom scheme `mailkite-<clientId>://callback`; secure storage + the browser
// opener are wired for you.
final mk = mailKiteClient(clientId: 'cli_your_public_id');

// One-call login: opens the system browser, catches the redirect, exchanges
// the code, and stores the tokens securely.
await mk.login();

// Now call the API as that user — the access token refreshes automatically.
await mk.send(const SendMessage(
  from: 'you@yourdomain.com',
  to: 'someone@example.com',
  subject: 'Hello from Flutter',
  text: 'Sent with mailkite_client.',
));

final domains = await mk.listDomains();

// Sign out: revokes the refresh token and clears secure storage.
await mk.logout();
```

No pre-provisioned client id? Pass a `redirectUri` you control and the library
registers a public client dynamically on first login:

```dart
final mk = MailKiteClient(
  redirectUri: 'mailkite-myapp://callback',
  store: SecureStorageTokenStore(),
  openAuthUrl: flutterWebAuthOpener('mailkite-myapp'),
);
await mk.login();
```

## Any bearer token

```dart
final mk = MailKiteClient.withToken(accessTokenOrApiKey);
await mk.listMessages();
```

## Inbound webhooks

Verify the `x-mailkite-signature` header locally (no network), then reply with a
canonical control string:

```dart
final ok = verifyWebhook(signatureHeader, requestBody, webhookSecret);
if (!ok) return; // reject

// In a route running in control mode:
return replyBlockSender(); // or replyOk() / replySpam() / replyDrop()
```

## What you get

- The full API method surface (`send`, `uploadAttachment`, `agent`, `route`,
  `listDomains`, `createDomain`, `verifyDomain`, `setWebhook`, `listRoutes`,
  `createRoute`, `listMessages`, … — generated from the spec).
- OAuth 2.1 + PKCE login (`login` / `beginLogin` / `completeLogin` / `logout`),
  automatic token refresh, and `429` `Retry-After` surfaced on
  `MailKiteException.retryAfter`.
- Local `verifyWebhook(signature, payload, secret)` + `replyOk/Spam/Drop/BlockSender`.
- Pluggable `TokenStore` (`SecureStorageTokenStore`, `MemoryTokenStore`, or your own).

## Platform setup

The redirect URI is `mailkite-<clientId>://callback`, so the custom scheme is
`mailkite-<clientId>`. Register it with `flutter_web_auth_2`:

### iOS (`ios/Runner/Info.plist`)

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>mailkite-cli_your_public_id</string>
    </array>
  </dict>
</array>
```

### Android (`android/app/src/main/AndroidManifest.xml`)

`flutter_web_auth_2` ships a callback activity; point its scheme at yours:

```xml
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true">
  <intent-filter android:label="flutter_web_auth_2">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="mailkite-cli_your_public_id" />
  </intent-filter>
</activity>
```

### Web

Add a callback page at the route you registered and call
`FlutterWebAuth2.authenticate` with `callbackUrlScheme: 'web'` (or follow the
[`flutter_web_auth_2` web notes](https://pub.dev/packages/flutter_web_auth_2#web)).

## Develop

```sh
node ../codegen.mjs        # regenerate lib/src/methods.generated.dart from the spec
flutter pub get
flutter test               # or: dart test (the unit tests are pure Dart — no device)
dart analyze
```

The unit tests in [`test/`](test) drive the transport + OAuth state machine over
an in-memory `MockClient` and exercise PKCE / webhook verification directly, so
they run without a device or network.
