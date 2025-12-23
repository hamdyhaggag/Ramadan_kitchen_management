import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/logic/cases_cubit.dart';
import '../../../manage_cases/logic/cases_state.dart';

import 'package:ramadan_kitchen_management/features/seasons/data/services/season_service.dart';

part 'donation_state.dart';

class DonationCubit extends Cubit<DonationState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CasesCubit _casesCubit;
  final SeasonService _seasonService = SeasonService(); // Instance of service
  StreamSubscription? _casesSubscription;

  DonationCubit(this._casesCubit) : super(DonationInitial()) {
    _casesSubscription = _casesCubit.stream.listen((_) => getDonations());
    getDonations();
  }

  Future<void> getDonations() async {
    try {
      final activeSeason = await _seasonService.getActiveSeason();
      final activeSeasonId = activeSeason?.id;

      // If no active season, return empty list immediately
      if (activeSeasonId == null) {
        emit(DonationLoaded(donations: []));
        return;
      }

      final snapshot = await _firestore
          .collection('donations')
          .where('seasonId', isEqualTo: activeSeasonId)
          .orderBy('created_at', descending: true)
          .get();

      List<Map<String, dynamic>> donations = snapshot.docs.map((doc) {
        return {...doc.data(), 'id': doc.id};
      }).toList();

      if (kDebugMode) {
        print(
            'Donations loaded: ${donations.length} for season $activeSeasonId');
      }
      emit(DonationLoaded(donations: donations));
    } catch (e) {
      // Fallback: If index is missing for [seasonId, created_at], log it or try without ordering
      // But for now, just emit error.
      if (kDebugMode) {
        print('Error loading donations: $e');
      }
      emit(DonationError('Failed to load data: $e'));
    }
  }

  Future<void> createNewDonation(Map<String, dynamic> data) async {
    try {
      final activeSeason = await _seasonService.getActiveSeason();
      final seasonId = activeSeason?.id;

      final totalIndividuals = _calculateTotalIndividuals();
      await _firestore.collection('donations').add({
        ...data,
        'numberOfIndividuals': totalIndividuals,
        'created_at': FieldValue.serverTimestamp(),
        'seasonId': seasonId,
      });
      getDonations();
    } catch (e) {
      emit(DonationError('Failed to create donation: $e'));
    }
  }

  int _calculateTotalIndividuals() {
    final state = _casesCubit.state;
    if (state is CasesLoaded) {
      return state.cases
          .fold(0, (sum, e) => sum + (e['عدد الأفراد'] as int? ?? 0));
    }
    return 0;
  }

  Future<void> updateDonation({
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('donations').doc(documentId).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
      getDonations();
    } catch (e) {
      emit(DonationError('Failed to update donation: $e'));
    }
  }

  @override
  Future<void> close() {
    _casesSubscription?.cancel();
    return super.close();
  }
}
