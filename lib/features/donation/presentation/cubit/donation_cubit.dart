import 'dart:async';
import 'package:flutter/foundation.dart';
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
      final snapshot = await _firestore
          .collection('donations')
          .orderBy('created_at', descending: true)
          .get();
      List<Map<String, dynamic>> donations = [];
      if (snapshot.docs.isEmpty) {
        final docRef = await _firestore.collection('donations').add({
          'mealImageUrl': 'https://example.com/default-image.jpg',
          'mealTitle': 'إفطار اليوم',
          'mealDescription': 'ساعد في توفير وجبات إفطار يومياَ للأسر المحتاجة',
          'contacts': [],
          'created_at': FieldValue.serverTimestamp(),
          'numberOfIndividuals': _calculateTotalIndividuals(),
        });
        final newDoc = await docRef.get();
        var data = newDoc.data()!;
        data['id'] = newDoc.id;
        donations.add(data);
      } else {
        donations = snapshot.docs.map((doc) {
          return {...doc.data(), 'id': doc.id};
        }).toList();
      }
      if (kDebugMode) {
        print('Donations loaded: ${donations.length}');
      }
      emit(DonationLoaded(donations: donations));
    } catch (e) {
      if (kDebugMode) {
        print('Error loading donations: $e');
      }
      emit(DonationError('Failed to load data: $e'));
    }
  }

  Future<void> getDonations() async {
    await _loadInitialData();
  }

  Future<void> createNewDonation(Map<String, dynamic> data) async {
    try {
      final totalIndividuals = _calculateTotalIndividuals();
      await _firestore.collection('donations').add({
        ...data,
        'numberOfIndividuals': totalIndividuals,
        'created_at': FieldValue.serverTimestamp(),
      });
      _loadInitialData();
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
