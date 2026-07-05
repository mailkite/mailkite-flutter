// Client-side OAuth: a button that signs the end user into THEIR OWN MailKite
// account (await mk.login()) then sends mail as that user (await mk.send(...)).
// Scheme setup: the factory derives the redirect `mailkite-<clientId>://callback`
// — register that custom scheme for each platform (README → Platform setup) so
// flutter_web_auth_2 can catch the redirect; tokens persist in flutter_secure_storage.
//
// Run: copy into a Flutter app's lib/, set your public OAuth clientId below, then
//   flutter pub add mailkite_client && flutter run

import 'package:flutter/material.dart';
import 'package:mailkite_client/mailkite_client.dart';

// Your pre-provisioned public OAuth client id (its scheme is mailkite-<clientId>).
final mk = mailKiteClient(clientId: 'cli_your_public_id');

class LoginAndSend extends StatefulWidget {
  const LoginAndSend({super.key});

  @override
  State<LoginAndSend> createState() => _LoginAndSendState();
}

class _LoginAndSendState extends State<LoginAndSend> {
  String _status = 'Not signed in';

  Future<void> _loginAndSend() async {
    try {
      // 1. Opens the system browser → user signs into their own MailKite account.
      setState(() => _status = 'Opening browser…');
      await mk.login();

      // 2. Send as that signed-in user, over one of their verified domains.
      final res = await mk.send(
        const SendMessage(
          from: 'you@yourdomain.com',
          to: 'someone@example.com',
          subject: 'Hello from Flutter',
          text: 'Sent with mailkite_client after a client-side OAuth login.',
        ),
      );
      setState(() => _status = 'Sent ${res.id} (${res.status})');
    } on MailKiteException catch (e) {
      setState(() => _status = 'Failed (${e.status}): ${e.message}');
    } catch (e) {
      setState(() => _status = 'Login failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_status),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loginAndSend,
          child: const Text('Sign in & send'),
        ),
      ],
    ),
  );
}
