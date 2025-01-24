import 'package:cloud_firestore/cloud_firestore.dart';

class CasesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getCasesStream() {
    return _firestore.collection('cases').snapshots();
  }

  Future<void> updateCase(String docId, String field, bool value) async {
    await _firestore.collection('cases').doc(docId).update({field: value});
  }
}
