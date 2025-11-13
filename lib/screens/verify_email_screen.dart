import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_router.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _checking = false;

  Future<void> _refresh() async {
    setState(() => _checking = true);
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    setState(() => _checking = false);
    if (user != null && user.emailVerified) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.awaitApproval);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('A verification link was sent to:\\n$email'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _checking ? null : _refresh, child: Text(_checking ? 'Checking…' : 'Ive verified, continue')),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email re-sent')));
                }
              },
              child: const Text('Resend verification email'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.pushNamedAndRemoveUntil(context, Routes.signIn, (_) => false);
              },
              child: const Text('Sign out'),
            )
          ],
        ),
      ),
    );
  }
}
