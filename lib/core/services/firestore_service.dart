import 'package:cloud_firestore/cloud_firestore.dart';

import 'data_base_service.dart';

class FireStoreService implements DatabaseService {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  @override
  Future<void> addData({
    required String path,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    if (documentId != null) {
      await firestore.collection(path).doc(documentId).set(data);
    } else {
      await firestore.collection(path).add(data);
    }
  }

  @override
  Future<dynamic> getData({
    required String path,
    required String docuementId,
  }) async {
    var data = await firestore.collection(path).doc(docuementId).get();
    return data.data();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllData(String path) async {
    final snapshot = await firestore.collection(path).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Future<void> updateData({
    required String path,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await firestore.collection(path).doc(documentId).update(data);
  }
}
