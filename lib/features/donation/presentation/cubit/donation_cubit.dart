import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/logic/cases_cubit.dart';

import '../../../manage_cases/logic/cases_state.dart';

part 'donation_state.dart';

class DonationCubit extends Cubit<DonationState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CasesCubit _casesCubit;
  StreamSubscription? _casesSubscription;

  DonationCubit(this._casesCubit) : super(DonationInitial()) {
    _casesSubscription = _casesCubit.stream.listen((_) => _loadInitialData());
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final snapshot = await _firestore.collection('donations').limit(1).get();

      Map<String, dynamic> donationData = {};
      String documentId = '';

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        donationData = doc.data();
        documentId = doc.id;
      } else {
        final docRef = await _firestore.collection('donations').add({
          'mealImageUrl': 'https://example.com/default-image.jpg',
          'mealTitle': 'إفطار اليوم',
          'mealDescription': 'ساعد في توفير وجبات إفطار يومياَ للأسر المحتاجة',
          'contacts': [],
          'created_at': FieldValue.serverTimestamp(),
        });
        documentId = docRef.id;
        final newDoc = await docRef.get();
        donationData = newDoc.data() ?? {};
      }

      final totalIndividuals = _calculateTotalIndividuals();
      donationData['numberOfIndividuals'] = totalIndividuals;

      emit(DonationLoaded(
        donationData: donationData,
        documentId: documentId,
      ));
    } catch (e) {
      emit(DonationError('Failed to load data: $e'));
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
      _loadInitialData();
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
