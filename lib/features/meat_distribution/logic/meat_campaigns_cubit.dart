import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/meat_campaign_model.dart';
import 'meat_campaigns_state.dart';

class MeatCampaignsCubit extends Cubit<MeatCampaignsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscription;

  MeatCampaignsCubit() : super(MeatCampaignsLoading()) {
    _loadCampaigns();
  }

  void _loadCampaigns() {
    _subscription = _firestore
        .collection('meat_campaigns')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      final campaigns = snapshot.docs
          .map((doc) => MeatCampaign.fromMap(doc.id, doc.data()))
          .toList();
      emit(MeatCampaignsLoaded(campaigns));
    }, onError: (e) {
      emit(MeatCampaignsError('حدث خطأ أثناء تحميل المواسم: $e'));
    });
  }

  Future<void> addCampaign(MeatCampaign campaign) async {
    try {
      await _firestore.collection('meat_campaigns').add(campaign.toMap());
    } catch (e) {
      // Failed to add
    }
  }

  Future<void> updateDistributedWeight(String id, double distributedWeight) async {
    try {
      await _firestore.collection('meat_campaigns').doc(id).update({
        'totalDistributed': distributedWeight,
      });
    } catch (e) {
      // Failed to update
    }
  }

  Future<void> updateCampaign(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('meat_campaigns').doc(id).update(data);
    } catch (e) {
      // Failed to update
    }
  }

  Future<void> deleteCampaign(String id) async {
    try {
      // Delete all allocations sub-collection first
      final allocations = await _firestore
          .collection('meat_campaigns')
          .doc(id)
          .collection('allocations')
          .get();
      for (final doc in allocations.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('meat_campaigns').doc(id).delete();
    } catch(e){
      // Failed to delete
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
