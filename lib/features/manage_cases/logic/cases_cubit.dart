import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cases_state.dart';

class CasesCubit extends Cubit<CasesState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CasesCubit() : super(CasesInitial()) {
    loadCases();
  }

  Future<void> loadCases() async {
    emit(CasesLoading());
    try {
      _firestore.collection('cases').snapshots().listen((snapshot) {
        final cases = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        emit(CasesLoaded(cases));
      });
    } catch (e) {
      emit(CasesError('Failed to load cases: $e'));
    }
  }

  Future<void> addCase(Map<String, dynamic> caseData) async {
    try {
      final docId = caseData['الرقم'].toString();
      await _firestore.collection('cases').doc(docId).set(caseData);
      caseData['id'] = docId;
    } catch (e) {
      emit(CasesError('Failed to add case: $e'));
    }
  }

  Future<void> updateCase(String docId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('cases').doc(docId).update(updates);
    } catch (e) {
      emit(CasesError('Failed to update case: $e'));
    }
  }

  Future<void> updateCaseState(
      String docId, String field, bool newValue) async {
    try {
      await _firestore.collection('cases').doc(docId).update({field: newValue});
    } catch (e) {
      emit(CasesError('Failed to update state: $e'));
    }
  }

  Future<void> deleteCase(String docId) async {
    try {
      await _firestore.collection('cases').doc(docId).delete();
    } catch (e) {
      emit(CasesError('Failed to delete case: $e'));
    }
  }
}
