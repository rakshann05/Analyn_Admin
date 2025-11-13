import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // We'll need to update this file next
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  PlatformFile? _pickedFile;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // --- THIS FUNCTION HAS BEEN UPDATED ---
  Future<void> _signUp() async {
    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload your KYC document')));
      return; // Stop if no file is selected
    }
   
    setState(() => _loading = true);

    try {
      // --- STEP 1: Create the user account FIRST ---
      // We will modify auth_service to remove kycUrl from this call
      final userCredential = await _auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _fullName.text.trim(),
        phone: _phone.text.trim(),
      );
      
      // --- STEP 2: Now that user is logged in, upload the file ---
      String? kycFileUrl;
      // We use the new user's ID to create a unique file path
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('kyc_documents/${userCredential.user!.uid}/${_pickedFile!.name}');

      final fileToUpload = File(_pickedFile!.path!);
      await storageRef.putFile(fileToUpload);

      // --- STEP 3: Get the public download URL ---
      kycFileUrl = await storageRef.getDownloadURL();
      
      // --- STEP 4: Update the user's document with the new URL ---
      // We will add this new function to AuthService
      await _auth.updateTherapistKycUrl(
        uid: userCredential.user!.uid,
        kycUrl: kycFileUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email sent. Please verify.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Therapist Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(controller: _fullName, hint: 'Full name'),
              const SizedBox(height: 12),
              AppTextField(controller: _email, hint: 'Email'),
              const SizedBox(height: 12),
              AppTextField(controller: _phone, hint: 'Phone (optional)'),
              const SizedBox(height: 12),
              AppTextField(controller: _password, hint: 'Password', obscure: true),
              const SizedBox(height: 12),
              AppTextField(controller: _confirm, hint: 'Confirm password', obscure: true),
              const SizedBox(height: 12),
              
              OutlinedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles();

                  if (result != null) {
                    setState(() {
                      _pickedFile = result.files.first;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('File selected: ${_pickedFile!.name}')),
                    );
                  } else {
                    print('User canceled the file picker');
                  }
                },
                child: Text(_pickedFile == null ? 'Upload KYC Documents' : _pickedFile!.name),
              ),
              
              const SizedBox(height: 16),
              AppButton(label: _loading ? 'Please wait…' : 'Sign up', onPressed: _loading ? null : _signUp),
            ],
          ),
        ),
      ),
    );
  }
}