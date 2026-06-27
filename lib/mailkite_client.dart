// Docs: docs/architecture/client-side-oauth-libraries.md
//
// mailkite_client — the client-side MailKite SDK. Your user signs into their own
// MailKite account via OAuth 2.1 + PKCE and the short-lived token (which IS the
// user) drives the same API the server SDKs expose. Public barrel.

library mailkite_client;

export 'src/client.dart' show MailKiteClient;
export 'src/exception.dart';
export 'src/flutter.dart';
export 'src/methods.generated.dart' show GeneratedMethods;
export 'src/oauth.dart' show Pkce, OAuthConfig, TokenSet, createPkce;
export 'src/storage.dart';
export 'src/types.dart';
export 'src/webhook.dart';
