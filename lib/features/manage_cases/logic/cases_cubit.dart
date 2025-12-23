import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../seasons/data/services/season_service.dart';
import 'cases_state.dart';

class CasesCubit extends Cubit<CasesState> {
  final FirebaseFirestore _firestore;
  final SeasonService _seasonService;
  List<Map<String, dynamic>> _localCache = [];
  StreamSubscription? _casesSubscription;
  String? _currentSeasonId;

  CasesCubit({SeasonService? seasonService})
      : _firestore = FirebaseFirestore.instance,
        _seasonService = seasonService ?? SeasonService(),
        super(CasesInitial()) {
    _initWithSeason();
  }

  /// Initialize by getting the active season first
  Future<void> _initWithSeason() async {
    final activeSeason = await _seasonService.getActiveSeason();
    _currentSeasonId = activeSeason?.id;
    loadCases();
  }

  /// Get current season ID
  String? get currentSeasonId => _currentSeasonId;

  /// Update the season and reload cases
  Future<void> setSeasonId(String? seasonId) async {
    if (_currentSeasonId == seasonId) return;
    _currentSeasonId = seasonId;
    await _casesSubscription?.cancel();
    loadCases();
  }

  void _sortLocalCache() {
    _localCache.sort((a, b) {
      final numA = a['الرقم'] is int
          ? a['الرقم'] as int
          : int.tryParse(a['الرقم'].toString()) ?? 0;
      final numB = b['الرقم'] is int
          ? b['الرقم'] as int
          : int.tryParse(b['الرقم'].toString()) ?? 0;
      return numA.compareTo(numB);
    });
  }

  Future<void> loadCases() async {
    emit(CasesLoading());
    try {
      // Cancel existing subscription
      await _casesSubscription?.cancel();

      // Build query based on season
      Query<Map<String, dynamic>> query = _firestore.collection('cases');

      // Only filter by season if we have an active season
      if (_currentSeasonId != null) {
        query = query.where('seasonId', isEqualTo: _currentSeasonId);
      }

      _casesSubscription = query.snapshots().listen((snapshot) {
        _localCache =
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
        _sortLocalCache();
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
      _sortLocalCache();
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
      _sortLocalCache();
      emit(CasesLoaded(List.from(_localCache)));
    } catch (e) {
      emit(CasesError('Failed to update state: $e'));
    }
  }

  Future<void> addCase(Map<String, dynamic> caseData) async {
    try {
      // Add seasonId to the case data
      if (_currentSeasonId != null) {
        caseData['seasonId'] = _currentSeasonId;
      }

      final docId = caseData['الرقم'].toString();
      final newCase = {...caseData, 'id': docId};
      _localCache = [..._localCache, newCase];
      await _firestore.collection('cases').doc(docId).set(caseData);
      _sortLocalCache();
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
      _sortLocalCache();
      emit(CasesLoaded(List.from(_localCache)));
    } catch (e) {
      emit(CasesError('Failed to update case: $e'));
    }
  }

  Future<void> deleteCase(String docId) async {
    try {
      _localCache.removeWhere((c) => c['id'] == docId);
      await _firestore.collection('cases').doc(docId).delete();
      _sortLocalCache();
      emit(CasesLoaded(List.from(_localCache)));
    } catch (e) {
      emit(CasesError('Failed to delete case: $e'));
    }
  }

  @override
  Future<void> close() {
    _casesSubscription?.cancel();
    return super.close();
  }
}
