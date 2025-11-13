import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signOut() async => _auth.signOut();

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // --- MODIFIED ---
  // We've removed the 'kycUrl' parameter from this method.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user!.updateDisplayName(fullName);
    await cred.user!.sendEmailVerification();

    // The document is now created *without* the kycDocumentUrl.
    await _db.collection('therapists').doc(cred.user!.uid).set({
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'status': 'pending', 
      'createdAt': FieldValue.serverTimestamp(),
      // The 'kycDocumentUrl' field is no longer added here.
    });
    return cred;
  }

  // --- NEW ---
  // We've added this new method to update the user *after* the file upload.
  Future<void> updateTherapistKycUrl({
    required String uid,
    required String kycUrl,
  }) async {
    // This 'update' method merges data into the existing document.
    return _db.collection('therapists').doc(uid).update({
      'kycDocumentUrl': kycUrl,
    });
  }
  // --------------------------------------------------

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Stream<String?> therapistStatusStream(String uid) {
    return _db.collection('therapists').doc(uid).snapshots().map((doc) => doc.data()?['status'] as String?);
  }
}