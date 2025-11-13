import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> get _incomingJobsStream =>
      FirebaseFirestore.instance
          .collection('bookings')
          .where('therapistId', isEqualTo: _uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots();

  // Create a transaction record when a job completes
  Future<void> _createTransaction(DocumentSnapshot<Map<String, dynamic>> jobDocument) async {
    final jobData = jobDocument.data() ?? {};
    const double earningsAmount = 50.00; // demo; replace with real amount if available

    await FirebaseFirestore.instance.collection('transactions').add({
      'jobId': jobDocument.id,
      'therapistId': _uid,
      'amount': earningsAmount,
      'dateCompleted': FieldValue.serverTimestamp(),
      'serviceType': jobData['serviceType'] ?? 'Unknown',
      'payoutStatus': 'pending',
    });
  }

  // Update booking status and create transaction when completed
  Future<void> _updateJobStatus(
      BuildContext context, DocumentSnapshot<Map<String, dynamic>> jobDocument, String newStatus) async {
    final jobId = jobDocument.id;
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(jobId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (newStatus == 'completed') {
        await _createTransaction(jobDocument);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job $newStatus successfully.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update job: $e')),
        );
      }
    }
  }

  Future<bool?> _confirmDialog(BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Useful for debugging in dev builds
    // print('Current Logged-in UID for Query: $_uid');

    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _incomingJobsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(child: Text('No incoming job requests.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final jobDoc = docs[index];
                final job = jobDoc.data();
                final service = (job['serviceType'] as String?) ?? 'Service';
                final clientName = (job['clientName'] as String?) ?? 'Client';
                final address = job['location']?['address'] as String? ?? '';
                final scheduled = job['when'] != null
                    ? '${job['when']['date'] ?? ''} ${job['when']['start'] ?? ''}'
                    : 'Scheduled time unknown';

                return Card(
                  key: ValueKey(jobDoc.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: service + client
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                service,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Chip(label: Text(job['status']?.toString().toUpperCase() ?? 'PENDING')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Client: $clientName'),
                        const SizedBox(height: 6),
                        if (address.isNotEmpty) Text('Address: $address'),
                        const SizedBox(height: 6),
                        Text('When: $scheduled'),
                        const SizedBox(height: 12),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                final ok = await _confirmDialog(context, 'Reject booking', 'Reject this booking?');
                                if (ok == true) {
                                  await _updateJobStatus(context, jobDoc, 'rejected');
                                }
                              },
                              child: const Text('REJECT', style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                // Accept -> typically moves to active jobs, but we update status to accepted here
                                final ok = await _confirmDialog(context, 'Accept booking', 'Accept this booking?');
                                if (ok == true) {
                                  await _updateJobStatus(context, jobDoc, 'accepted');
                                }
                              },
                              child: const Text('ACCEPT'),
                            ),
                            const SizedBox(width: 8),
                            // Complete button for testing/demo — mark job completed and create transaction
                            OutlinedButton(
                              onPressed: () async {
                                final ok = await _confirmDialog(context, 'Complete job', 'Mark this job as completed? This will create a transaction entry.');
                                if (ok == true) {
                                  await _updateJobStatus(context, jobDoc, 'completed');
                                }
                              },
                              child: const Text('COMPLETE'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
