import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_router.dart';
import '../services/auth_service.dart';

class AwaitApprovalScreen extends StatelessWidget {
  const AwaitApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final auth = AuthService();

    return Scaffold(
      appBar: AppBar(title: const Text('Awaiting Admin Approval')),
      body: StreamBuilder<String?>(
        stream: auth.therapistStatusStream(user.uid),
        builder: (context, snap) {
          final status = snap.data;
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (status == 'approved') {
            Future.microtask(() => Navigator.pushReplacementNamed(context, Routes.home));
            return const SizedBox.shrink();
          }
          if (status == 'blocked') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Your account has been blocked. Contact support.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, Routes.signIn, (_) => false);
                      }
                    },
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Thanks for signing up!'),
                const SizedBox(height: 8),
                Text('An admin is reviewing your KYC. Youll get access once approved.'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, Routes.signIn, (_) => false);
                    }
                  },
                  child: const Text('Sign out'),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
