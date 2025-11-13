import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  double _totalEarnings = 0.0;
  double _monthlyEarnings = 0.0;

  Stream<QuerySnapshot<Map<String, dynamic>>> get _earningsStream =>
      FirebaseFirestore.instance
          .collection('transactions')
          .where('therapistId', isEqualTo: _uid)
          .orderBy('dateCompleted', descending: true)
          .snapshots();

  // Compute totals from docs (pure function)
  Map<String, double> _computeTotalsFromDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    double total = 0.0;
    double monthly = 0.0;
    final now = DateTime.now();

    for (var doc in docs) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final ts = data['dateCompleted'];
      DateTime? date;
      if (ts is Timestamp) {
        date = ts.toDate();
      } else if (ts is DateTime) {
        date = ts;
      }
      if (date == null) continue;

      total += amount;
      if (date.year == now.year && date.month == now.month) {
        monthly += amount;
      }
    }

    return {'total': total, 'monthly': monthly};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: SafeArea(
        child: Column(
          children: [
            // Header showing current totals
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.06),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Total: ₹${_totalEarnings.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('This Month: ₹${_monthlyEarnings.toStringAsFixed(2)}'),
                ],
              ),
            ),

            // StreamBuilder for transaction list and totals
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _earningsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    // Reset totals if previously set
                    if (_totalEarnings != 0.0 || _monthlyEarnings != 0.0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _totalEarnings = 0.0;
                            _monthlyEarnings = 0.0;
                          });
                        }
                      });
                    }
                    return const Center(child: Text('No recorded transactions yet.'));
                  }

                  final docs = snapshot.data!.docs;
                  final totals = _computeTotalsFromDocs(docs);
                  final total = totals['total'] ?? 0.0;
                  final monthly = totals['monthly'] ?? 0.0;

                  // Update state only when values changed
                  if (_totalEarnings != total || _monthlyEarnings != monthly) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _totalEarnings = total;
                          _monthlyEarnings = monthly;
                        });
                      }
                    });
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final ts = data['dateCompleted'];
                      DateTime date = DateTime.now();
                      if (ts is Timestamp) date = ts.toDate();
                      else if (ts is DateTime) date = ts;

                      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                      final service = (data['serviceType'] as String?) ?? 'Service';
                      final jobId = (data['jobId'] as String?) ?? data['bookingId'] ?? '—';
                      final payoutStatus = (data['payoutStatus'] as String?) ?? 'unknown';

                      return ListTile(
                        leading: Icon(
                          payoutStatus.toLowerCase() == 'paid' ? Icons.check_circle_outline : Icons.hourglass_top,
                          color: payoutStatus.toLowerCase() == 'paid' ? Colors.green : Colors.orange,
                        ),
                        title: Text('$service • ₹${amount.toStringAsFixed(2)}'),
                        subtitle: Text('Job: $jobId\nCompleted: ${date.month}/${date.day}/${date.year}'),
                        trailing: Text(
                          payoutStatus.toUpperCase(),
                          style: TextStyle(
                            color: payoutStatus.toLowerCase() == 'paid' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        isThreeLine: true,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
