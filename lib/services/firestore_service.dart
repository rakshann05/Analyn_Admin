import 'package:cloud_firestore/cloud_firestore.dart';


class FirestoreService {
final _db = FirebaseFirestore.instance;


Future<Map<String, dynamic>?> getTherapist(String uid) async {
final doc = await _db.collection('therapists').doc(uid).get();
return doc.data();
}
}