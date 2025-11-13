import 'package:cloud_firestore/cloud_firestore.dart'; // <-- New Import Needed Here
import 'package:flutter/material.dart';
import '../app_router.dart';
import '../services/auth_service.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _auth = AuthService();
  late StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    // We listen to the Auth State change once
    _authSubscription = _auth.authStateChanges().listen(_handleNavigation);
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  // --- MODIFIED: Changed function to async and simplified the check ---
  void _handleNavigation(User? user) async {
    if (!mounted) return;

    // 1. If not logged in, go to sign in
    if (user == null) {
      _authSubscription.cancel();
      Navigator.pushReplacementNamed(context, Routes.signIn);
      return;
    }

    // 2. If logged in but not verified, go to verify email
    if (!user.emailVerified) {
      _authSubscription.cancel();
      Navigator.pushReplacementNamed(context, Routes.verifyEmail);
      return;
    }

    // 3. User is verified. Await the document data using .get()

    // Get the document snapshot (a one-time fetch)
    final therapistDoc = await FirebaseFirestore.instance
        .collection('therapists')
        .doc(user.uid)
        .get();

    final status = therapistDoc.data()?['status']; // Read the status field

    if (mounted) {
      _authSubscription.cancel(); // Cancel subscription before navigating

      if (status == "approved") {
        Navigator.pushReplacementNamed(context, Routes.home);
      } else {
        // Catches "pending", "blocked", or anything else.
        Navigator.pushReplacementNamed(context, Routes.awaitApproval);
      }
    }
  }
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
