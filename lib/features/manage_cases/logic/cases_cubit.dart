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
        _localCache = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        emit(CasesLoaded(List.from(_localCache)));
      });
    } catch (e) {
      emit(_localCache.isEmpty
          ? CasesError('Failed to load cases: $e')
          : CasesLoaded(List.from(_localCache)));
    }
  }

  Future<void> addCase(Map<String, dynamic> caseData) async {
    try {
      final docId = caseData['الرقم'].toString();

      final newCase = {...caseData, 'id': docId};
      _localCache = [..._localCache, newCase];
      emit(CasesLoaded(List.from(_localCache)));

      await _firestore.collection('cases').doc(docId).set(caseData);
    } catch (e) {
      _localCache.removeWhere((c) => c['id'] == caseData['الرقم'].toString());
      emit(CasesLoaded(List.from(_localCache)));
      emit(CasesError('Failed to add case: $e'));
    }
  }

  Future<void> updateCase(String docId, Map<String, dynamic> updates) async {
    try {
      final index = _localCache.indexWhere((c) => c['id'] == docId);
      if (index != -1) {
        _localCache[index] = {..._localCache[index], ...updates};
        emit(CasesLoaded(List.from(_localCache)));
      }

      await _firestore.collection('cases').doc(docId).update(updates);
    } catch (e) {
      emit(CasesLoaded(List.from(_localCache)));
      emit(CasesError('Failed to update case: $e'));
    }
  }

  Future<void> updateCaseState(
      String docId, String field, bool newValue) async {
    try {
      final index = _localCache.indexWhere((c) => c['id'] == docId);
      if (index != -1) {
        _localCache[index][field] = newValue;
        emit(CasesLoaded(List.from(_localCache)));
      }

      await _firestore.collection('cases').doc(docId).update({field: newValue});
    } catch (e) {
      emit(CasesLoaded(List.from(_localCache)));
      emit(CasesError('Failed to update state: $e'));
    }
  }

  Future<void> deleteCase(String docId) async {
    try {
      _localCache.removeWhere((c) => c['id'] == docId);
      emit(CasesLoaded(List.from(_localCache)));

      await _firestore.collection('cases').doc(docId).delete();
    } catch (e) {
      emit(CasesLoaded(List.from(_localCache)));
      emit(CasesError('Failed to delete case: $e'));
    }
  }
}
