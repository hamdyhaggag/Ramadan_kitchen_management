import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'donation_state.dart';

class DonationCubit extends Cubit<DonationState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DonationCubit() : super(DonationInitial()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final snapshot = await _firestore.collection('donations').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        emit(DonationLoaded(
          donationData: doc.data(),
          documentId: doc.id,
        ));
      } else {
        final docRef = await _firestore.collection('donations').add({
          'mealImageUrl': 'https://example.com/default-image.jpg',
          'mealTitle': 'إفطار اليوم',
          'mealDescription': 'ساعد في توفير وجبات إفطار يومياَ للأسر المحتاجة',
          'contacts': [],
          'created_at': FieldValue.serverTimestamp(),
        });

        emit(DonationLoaded(
          donationData: {},
          documentId: docRef.id,
        ));
      }
    } catch (e) {
      emit(DonationError('Failed to load data: $e'));
    }
  }

  Future<void> fetchDonationData() async {
    await _loadInitialData();
  }

  Future<void> updateDonation({
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (documentId.isEmpty) {
        final newDocRef = await _firestore.collection('donations').add({
          ...data,
          'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
          'created_at': FieldValue.serverTimestamp(),
        });
        final newDoc = await newDocRef.get();
        emit(DonationLoaded(
          donationData: newDoc.data() ?? {},
          documentId: newDocRef.id,
        ));
      } else {
        await _firestore.collection('donations').doc(documentId).update({
          ...data,
          'updated_at': FieldValue.serverTimestamp(),
        });
        final updatedDoc =
            await _firestore.collection('donations').doc(documentId).get();
        emit(DonationLoaded(
          donationData: updatedDoc.data() ?? {},
          documentId: documentId,
        ));
      }
    } catch (e) {
      emit(DonationError('Failed to update donation: $e'));
    }
  }
}
