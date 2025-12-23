import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../seasons/data/services/season_service.dart';
import '../../../../core/networking/firestore_constants.dart';

class CasesRepository {
  CollectionReference get _casesCollection =>
      SeasonService().getCollection(FirestoreCollections.cases);

  Stream<QuerySnapshot> getCasesStream() {
    return _casesCollection.snapshots();
  }

  Future<void> updateCase(String docId, String field, bool value) async {
    await _casesCollection.doc(docId).update({field: value});
  }
}
