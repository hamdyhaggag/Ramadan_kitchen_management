import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/logic/cases_cubit.dart';
import '../../../manage_cases/logic/cases_state.dart';

import 'package:ramadan_kitchen_management/core/networking/firestore_constants.dart';
import 'package:ramadan_kitchen_management/features/seasons/data/services/season_service.dart';

part 'donation_state.dart';

class DonationCubit extends Cubit<DonationState> {
  final CasesCubit _casesCubit;
  final SeasonService _seasonService = SeasonService(); // Instance of service
  StreamSubscription? _casesSubscription;

  DonationCubit(this._casesCubit) : super(DonationInitial()) {
    _casesSubscription = _casesCubit.stream.listen((state) {
      if (state is CasesLoaded) {
        getDonations();
      }
    });
    // Initial load
    getDonations();
  }

  Future<void> getDonations() async {
    try {
      final activeSeason = await _seasonService.getActiveSeason();
      if (activeSeason == null) {
        emit(DonationLoaded(donations: []));
        return;
      }

      final collection =
          _seasonService.getCollection(FirestoreCollections.donations);
      Query query = collection;

      // Only filter by seasonId if we're using the legacy root collection
      if (!activeSeason.isMigratedToV2) {
        query = query.where('seasonId', isEqualTo: activeSeason.id);
      }

      final snapshot =
          await query.orderBy('created_at', descending: true).get();

      List<Map<String, dynamic>> donations = snapshot.docs.map((doc) {
        return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
      }).toList();

      if (kDebugMode) {
        print(
            'Donations loaded: ${donations.length} for season ${activeSeason.id}');
      }
      emit(DonationLoaded(donations: donations));
    } catch (e) {
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
      final collection =
          _seasonService.getCollection(FirestoreCollections.donations);

      await collection.add({
        ...data,
        'numberOfIndividuals': totalIndividuals,
        'created_at': FieldValue.serverTimestamp(),
        'seasonId': seasonId, // Keep it for double-safety/legacy
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
      final collection =
          _seasonService.getCollection(FirestoreCollections.donations);
      await collection.doc(documentId).update({
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
