# MailKite examples — Flutter

Runnable, copy-pasteable snippets. Each file's header comment lists its purpose and the custom-scheme setup. Client-side OAuth: the end user signs into **their own** MailKite account.

| File | What it shows |
| --- | --- |
| [`login_and_send.dart`](login_and_send.dart) | A button that runs `await mk.login()` (browser OAuth into the user's own account) then `await mk.send(...)` |

> Setup: register the `mailkite-<clientId>://callback` scheme for each platform (README → Platform setup) so `flutter_web_auth_2` can catch the redirect. Tokens persist in `flutter_secure_storage`.

Full docs: <https://mailkite.dev/docs> · Library guide: <https://mailkite.dev/docs/libraries>
