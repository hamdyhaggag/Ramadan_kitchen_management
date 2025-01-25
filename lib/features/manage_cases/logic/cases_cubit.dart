import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cases_state.dart';

class CasesCubit extends Cubit<CasesState> {
  final FirebaseFirestore _firestore;
  List<Map<String, dynamic>> _localCache = [];

  CasesCubit()
      : _firestore = FirebaseFirestore.instance,
        super(CasesInitial()) {
    loadCases();
  }

  Future<void> loadCases() async {
    emit(CasesLoading());
    try {
      _firestore.collection('cases').snapshots().listen((snapshot) {
        _localCache =
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
        emit(CasesLoaded(List.from(_localCache)));
      });
    } catch (e) {
      emit(_localCache.isEmpty
          ? CasesError('Failed to load cases: $e')
          : CasesLoaded(List.from(_localCache)));
    }
  }

  Future<void> resetAllCases() async {
    emit(CasesLoading());
    try {
      final batch = _firestore.batch();
      final updatedCache = _localCache.map((caseItem) {
        final updated = Map<String, dynamic>.from(caseItem);
        updated['جاهزة'] = false;
        updated['هنا؟'] = false;
        batch.update(_firestore.collection('cases').doc(updated['id']),
            {'جاهزة': false, 'هنا؟': false});
        return updated;
      }).toList();

      _localCache = updatedCache;
      await batch.commit();
      emit(CasesLoaded(List.from(_localCache)));
    } catch (e) {
      emit(CasesError('Failed to reset cases: $e'));
    }
  }

  Future<void> updateCaseState(
      String docId, String field, bool newValue) async {
    try {
      final index = _localCache.indexWhere((c) => c['id'] == docId);
      if (index == -1) return;

      final updatedCase = Map<String, dynamic>.from(_localCache[index]);
      updatedCase[field] = newValue;
      _localCache[index] = updatedCase;

      await _firestore.collection('cases').doc(docId).update({field: newValue});
      emit(CasesLoaded(List.from(_localCache)));
    } catch (e) {
      emit(CasesError('Failed to update state: $e'));
    }
  }

  Future<void> addCase(Map<String, dynamic> caseData) async {
    try {
      final docId = caseData['الرقم'].toString();
      final newCase = {...caseData, 'id': docId};
      _localCache = [..._localCache, newCase];
      await _firestore.collection('cases').doc(docId).set(caseData);
      emit(CasesLoaded(List.from(_localCache)));
    } catch (e) {
      _localCache.removeWhere((c) => c['id'] == caseData['الرقم'].toString());
      emit(CasesError('Failed to add case: $e'));
    }
  }

  Future<void> updateCase(String docId, Map<String, dynamic> updates) async {
    try {
      final index = _localCache.indexWhere((c) => c['id'] == docId);
      if (index == -1) return;

      final updatedCase = {..._localCache[index], ...updates};
      _localCache[index] = updatedCase;

      await _firestore.collection('cases').doc(docId).update(updates);
      emit(CasesLoaded(List.from(_localCache)));
    } catch (e) {
      emit(CasesError('Failed to update case: $e'));
    }
  }

  Future<void> deleteCase(String docId) async {
    try {
      _localCache.removeWhere((c) => c['id'] == docId);
      await _firestore.collection('cases').doc(docId).delete();
      emit(CasesLoaded(List.from(_localCache)));
    } catch (e) {
      emit(CasesError('Failed to delete case: $e'));
    }
  }
}
