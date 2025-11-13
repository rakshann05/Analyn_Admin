import 'package:flutter/material.dart';
import '../app_router.dart';
import '../services/auth_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // --- MODIFIED: Added Navigation ---
  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await _auth.signIn(_email.text.trim(), _password.text);
      
      // --- NEW: Successful Login Navigation ---
      if (mounted) {
        // We push back to the Splash Screen (assuming it's Routes.splash 
        // or the initial route) to re-run the status checks we built.
        Navigator.pushNamedAndRemoveUntil(context, Routes.splash, (_) => false);
      }
      // ----------------------------------------
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  // -----------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Therapist Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(controller: _email, hint: 'Email'),
            const SizedBox(height: 12),
            AppTextField(controller: _password, hint: 'Password', obscure: true),
            const SizedBox(height: 16),
            // The Log In button calls the updated _login function
            AppButton(label: _loading ? 'Please wait…' : 'Log in', onPressed: _loading ? null : _login),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pushNamed(context, Routes.signUp), child: const Text('Create account')),
            TextButton(
              onPressed: () async {
                if (_email.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter email to reset')));
                  return;
                }
                try {
                  await _auth.resetPassword(_email.text.trim());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent')));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Forgot password?'),
            ),
          ],
        ),
      ),
    );
  }
}