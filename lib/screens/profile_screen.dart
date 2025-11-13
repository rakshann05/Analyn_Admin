import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
// --- NEW IMPORT ---
import 'package:firebase_messaging/firebase_messaging.dart';
// ------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- Personal Info ---
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // --- Service Info ---
  final List<String> _allServices = [
    'Individual Counseling',
    'Couples Therapy',
    'Child Psychology',
    'Group Therapy',
    'Addiction Counseling',
  ];
  Map<String, bool> _servicesMap = {};

  // --- Availability Info ---
  String _selectedHours = '9:00 AM - 5:00 PM'; 
  double _maxDistance = 10.0; 

  // --- Payout Info ---
  String _stripeAccountId = ''; 
  bool _payoutsEnabled = false; 
  
  // --- Notification Info ---
  String _fcmTokenStatus = "Disabled"; // To display status on screen
  // -------------------------

  // --- Document Info ---
  PlatformFile? _newKycFile;
  String _currentKycDocInfo = "Loading...";

  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = true;
  bool _isSaving = false;

  // --- NEW FUNCTION: Gets FCM token and saves to Firestore ---
  Future<void> _getAndSaveToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('therapists')
          .doc(_uid)
          .update({'fcmToken': token});
          
      if (mounted) {
        setState(() => _fcmTokenStatus = "Enabled");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications enabled successfully!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get FCM token.')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('therapists')
          .doc(_uid)
          .get();

      final data = doc.data();

      if (data != null) {
        // Load existing data
        _fullNameController.text = data['fullName'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        final servicesFromDb = Map<String, dynamic>.from(data['services'] ?? {});
        _servicesMap = {};
        for (final serviceName in _allServices) {
          _servicesMap[serviceName] = servicesFromDb[serviceName] ?? false;
        }

        // Load availability info
        _selectedHours = data['workingHours'] ?? _selectedHours;
        _maxDistance = (data['maxDistance'] as num?)?.toDouble() ?? 10.0;
        
        // Load Payout Info
        _stripeAccountId = data['stripeAccountId'] ?? '';
        _payoutsEnabled = data['payoutsEnabled'] ?? false;

        // Load Notification Status (NEW)
        final fcmToken = data['fcmToken'];
        if (fcmToken != null && fcmToken.isNotEmpty) {
           _fcmTokenStatus = "Enabled";
        }
        
        // Load document info
        final kycUrl = data['kycDocumentUrl'];
        if (kycUrl != null && (kycUrl as String).isNotEmpty) {
          _currentKycDocInfo = "A document is on file.";
        } else {
          _currentKycDocInfo = "No document submitted.";
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _newKycFile = result.files.first;
        _currentKycDocInfo = "";
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() { _isSaving = true; });

    try {
      String? newKycFileUrl; 

      if (_newKycFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('kyc_documents/$_uid/${_newKycFile!.name}');

        final fileToUpload = File(_newKycFile!.path!);
        await storageRef.putFile(fileToUpload);
        newKycFileUrl = await storageRef.getDownloadURL();
      }

      final Map<String, dynamic> dataToUpdate = {
        'fullName': _fullNameController.text,
        'phone': _phoneController.text,
        'services': _servicesMap,
        'workingHours': _selectedHours, 
        'maxDistance': _maxDistance,   
      };

      if (newKycFileUrl != null) {
        dataToUpdate['kycDocumentUrl'] = newKycFileUrl;
      }

      await FirebaseFirestore.instance
          .collection('therapists')
          .doc(_uid)
          .update(dataToUpdate);

      if (newKycFileUrl != null) {
        setState(() {
          _newKycFile = null;
          _currentKycDocInfo = "A new document has been saved.";
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Personal Info Section ---
                    const Text('Personal Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    TextFormField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()), keyboardType: TextInputType.phone),

                    // --- Availability & Radius Section ---
                    const SizedBox(height: 24),
                    const Text('Availability & Radius', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Working Hours:', style: TextStyle(fontSize: 16)),
                        DropdownButton<String>(
                          value: _selectedHours,
                          items: const [
                            DropdownMenuItem(value: '9:00 AM - 5:00 PM', child: Text('9:00 AM - 5:00 PM')),
                            DropdownMenuItem(value: '10:00 AM - 7:00 PM', child: Text('10:00 AM - 7:00 PM')),
                            DropdownMenuItem(value: '1:00 PM - 9:00 PM', child: Text('1:00 PM - 9:00 PM')),
                          ],
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() { _selectedHours = newValue; });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Max Travel Distance: ${_maxDistance.round()} km', style: const TextStyle(fontSize: 16)),
                    Slider(
                      value: _maxDistance, min: 5, max: 100, divisions: 19, label: _maxDistance.round().toString(),
                      onChanged: (double value) { setState(() { _maxDistance = value; }); },
                    ),
                    
                    // --- Services Section ---
                    const SizedBox(height: 24),
                    const Text('My Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    ListView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      itemCount: _allServices.length,
                      itemBuilder: (context, index) {
                        final serviceName = _allServices[index];
                        return CheckboxListTile(
                          title: Text(serviceName),
                          value: _servicesMap[serviceName] ?? false,
                          onChanged: (bool? newValue) { setState(() { _servicesMap[serviceName] = newValue ?? false; }); },
                        );
                      },
                    ),

                    // --- Documents Section ---
                    const SizedBox(height: 24),
                    const Text('KYC Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    OutlinedButton.icon(icon: const Icon(Icons.upload_file), label: const Text('Upload New Document'), onPressed: _pickFile),
                    const SizedBox(height: 8),
                    Text(
                      _newKycFile != null ? 'New file selected: ${_newKycFile!.name}' : _currentKycDocInfo,
                      style: const TextStyle(fontStyle: FontStyle.italic), textAlign: TextAlign.center,
                    ),
                    
                    // --- NEW: Notifications Section ---
                    const SizedBox(height: 24),
                    const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status: $_fcmTokenStatus', style: TextStyle(color: _fcmTokenStatus == 'Enabled' ? Colors.green : Colors.red)),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.notifications_active),
                          onPressed: _fcmTokenStatus == 'Enabled' ? null : _getAndSaveToken,
                          label: Text(_fcmTokenStatus == 'Enabled' ? 'Enabled' : 'Enable Notifications'),
                        ),
                      ],
                    ),
                    // ------------------------------------

                    // --- Payout Settings Section ---
                    const SizedBox(height: 24),
                    const Text('Payout Settings (Stripe Connect)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text(_stripeAccountId.isEmpty ? 'Status: Not Connected' : _payoutsEnabled ? 'Status: Ready for Payouts' : 'Status: Verification Pending',
                      style: TextStyle(color: _payoutsEnabled ? Colors.green : Colors.red),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () { 
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stripe Connect logic not implemented yet!')));
                      },
                      child: Text(_stripeAccountId.isEmpty ? 'Connect Bank Account' : 'Manage Account'),
                    ),
                    // -----------------------------

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save All Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}