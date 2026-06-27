// Docs: docs/architecture/client-side-oauth-libraries.md
//
// Minimal example: sign into a MailKite account from a Flutter app, then send a
// message as that user. Replace `cli_your_public_id` with your public OAuth
// client id and register the matching `mailkite-<clientId>://callback` scheme
// for your platform (see the package README → Platform setup).

import 'package:flutter/material.dart';
import 'package:mailkite_client/mailkite_client.dart';

void main() => runApp(const MailKiteExampleApp());

final mk = mailKiteClient(clientId: 'cli_your_public_id');

class MailKiteExampleApp extends StatelessWidget {
  const MailKiteExampleApp({super.key});

  @override
  Widget build(BuildContext context) =>
      MaterialApp(title: 'MailKite example', home: const HomeScreen());
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _status = 'Not signed in';

  Future<void> _login() async {
    setState(() => _status = 'Opening browser…');
    try {
      await mk.login();
      setState(() => _status = 'Signed in');
    } catch (e) {
      setState(() => _status = 'Login failed: $e');
    }
  }

  Future<void> _send() async {
    try {
      final res = await mk.send(
        const SendMessage(
          from: 'you@yourdomain.com',
          to: 'someone@example.com',
          subject: 'Hello from Flutter',
          text: 'Sent with mailkite_client.',
        ),
      );
      setState(() => _status = 'Sent ${res.id} (${res.status})');
    } on MailKiteException catch (e) {
      setState(() => _status = 'Send failed (${e.status}): ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MailKite example')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_status),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _login, child: const Text('Sign in')),
          ElevatedButton(onPressed: _send, child: const Text('Send email')),
          ElevatedButton(
            onPressed: () async {
              await mk.logout();
              setState(() => _status = 'Signed out');
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    ),
  );
}
