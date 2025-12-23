import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ramadan_season_model.dart';

/// Service for managing Ramadan seasons in Firestore
class SeasonService {
  static final SeasonService _instance = SeasonService._internal();
  factory SeasonService() => _instance;
  SeasonService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _seasonsCollection = 'ramadan_seasons';

  // Cache the active season for quick access
  RamadanSeasonModel? _activeSeasonCache;
  String? get activeSeasonId => _activeSeasonCache?.id;

  /// Get all seasons ordered by creation date (newest first)
  Stream<List<RamadanSeasonModel>> getSeasonsStream() {
    return _firestore
        .collection(_seasonsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RamadanSeasonModel.fromFirestore(doc))
            .toList());
  }

  /// Get the currently active season
  Future<RamadanSeasonModel?> getActiveSeason() async {
    if (_activeSeasonCache != null) {
      return _activeSeasonCache;
    }

    final snapshot = await _firestore
        .collection(_seasonsCollection)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      _activeSeasonCache =
          RamadanSeasonModel.fromFirestore(snapshot.docs.first);
      return _activeSeasonCache;
    }
    return null;
  }

  /// Stream the active season for real-time updates
  Stream<RamadanSeasonModel?> getActiveSeasonStream() {
    return _firestore
        .collection(_seasonsCollection)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        _activeSeasonCache =
            RamadanSeasonModel.fromFirestore(snapshot.docs.first);
        return _activeSeasonCache;
      }
      _activeSeasonCache = null;
      return null;
    });
  }

  /// Get a specific season by ID
  Future<RamadanSeasonModel?> getSeasonById(String seasonId) async {
    final doc =
        await _firestore.collection(_seasonsCollection).doc(seasonId).get();
    if (doc.exists) {
      return RamadanSeasonModel.fromFirestore(doc);
    }
    return null;
  }

  /// Get all archived seasons (for viewing history)
  Stream<List<RamadanSeasonModel>> getArchivedSeasonsStream() {
    return _firestore
        .collection(_seasonsCollection)
        .where('isArchived', isEqualTo: true)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RamadanSeasonModel.fromFirestore(doc))
            .toList());
  }

  /// Create a new season
  Future<String> createSeason(RamadanSeasonModel season) async {
    // If new season is active, deactivate all other seasons first
    if (season.isActive) {
      await _deactivateAllSeasons();
    }

    final docRef = await _firestore
        .collection(_seasonsCollection)
        .add(season.toFirestore());

    if (season.isActive) {
      _activeSeasonCache = season.copyWith(id: docRef.id);
    }

    return docRef.id;
  }

  /// Update an existing season
  Future<void> updateSeason(RamadanSeasonModel season) async {
    // If activating this season, deactivate others first
    if (season.isActive) {
      await _deactivateAllSeasons();
      _activeSeasonCache = season;
    }

    await _firestore
        .collection(_seasonsCollection)
        .doc(season.id)
        .update(season.toFirestore());
  }

  /// Activate a specific season (deactivates all others)
  Future<void> activateSeason(String seasonId) async {
    await _deactivateAllSeasons();

    await _firestore.collection(_seasonsCollection).doc(seasonId).update({
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update cache
    _activeSeasonCache = await getSeasonById(seasonId);
  }

  /// Archive a season (marks it as completed)
  Future<void> archiveSeason(String seasonId) async {
    final season = await getSeasonById(seasonId);
    if (season == null) return;

    // Calculate final statistics before archiving
    final stats = await _calculateSeasonStatistics(seasonId);

    await _firestore.collection(_seasonsCollection).doc(seasonId).update({
      'isActive': false,
      'isArchived': true,
      'statistics': stats.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (_activeSeasonCache?.id == seasonId) {
      _activeSeasonCache = null;
    }
  }

  /// Deactivate all seasons
  Future<void> _deactivateAllSeasons() async {
    final activeSeasonsQuery = await _firestore
        .collection(_seasonsCollection)
        .where('isActive', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (var doc in activeSeasonsQuery.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    await batch.commit();
    _activeSeasonCache = null;
  }

  /// Calculate statistics for a season
  Future<SeasonStatistics> _calculateSeasonStatistics(String seasonId) async {
    // Get cases count
    final casesSnapshot = await _firestore
        .collection('cases')
        .where('seasonId', isEqualTo: seasonId)
        .get();

    // Get groups count
    final groupsSnapshot = await _firestore
        .collection('caseGroups')
        .where('seasonId', isEqualTo: seasonId)
        .get();

    // Get donations (meals served)
    final donationsSnapshot = await _firestore
        .collection('donations')
        .where('seasonId', isEqualTo: seasonId)
        .get();

    int totalMeals = 0;
    for (var doc in donationsSnapshot.docs) {
      totalMeals += (doc.data()['numberOfIndividuals'] as int?) ?? 0;
    }

    // Get expenses
    final expensesSnapshot = await _firestore
        .collection('expenses')
        .where('seasonId', isEqualTo: seasonId)
        .get();

    double totalExpenses = 0.0;
    for (var doc in expensesSnapshot.docs) {
      totalExpenses += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
    }

    return SeasonStatistics(
      totalCases: casesSnapshot.docs.length,
      totalGroups: groupsSnapshot.docs.length,
      totalMealsServed: totalMeals,
      totalExpenses: totalExpenses,
      totalDays: donationsSnapshot.docs.length,
      lastUpdated: DateTime.now(),
    );
  }

  /// Copy data from one season to another with granular control
  Future<void> copyDataToSeason({
    required String sourceSeasonId,
    required String targetSeasonId,
    bool copyCases = false,
    bool copyGroups = false,
    bool copyDonationSettings = false,
  }) async {
    final batch = _firestore.batch();
    int copiedCasesCount = 0;
    int copiedGroupsCount = 0;

    // 1. Copy cases
    if (copyCases) {
      final casesSnapshot = await _firestore
          .collection('cases')
          .where('seasonId', isEqualTo: sourceSeasonId)
          .get();

      copiedCasesCount = casesSnapshot.docs.length;

      for (var doc in casesSnapshot.docs) {
        final data = doc.data();
        // Reset the checkbox values (استلم) for the new season
        data['seasonId'] = targetSeasonId;
        data['استلم'] = false; // Reset received status
        data['جاهزة'] = false; // Reset ready status
        data['هنا؟'] = false; // Reset present status

        // Remove document ID from data if it exists to let Firestore generate a new one
        data.remove('id');

        final newDocRef = _firestore.collection('cases').doc();
        batch.set(newDocRef, data);
      }
    }

    // 2. Copy case groups
    if (copyGroups) {
      final groupsSnapshot = await _firestore
          .collection('caseGroups')
          .where('seasonId', isEqualTo: sourceSeasonId)
          .get();

      copiedGroupsCount = groupsSnapshot.docs.length;

      for (var doc in groupsSnapshot.docs) {
        final data = doc.data();
        data['seasonId'] = targetSeasonId;
        data.remove('id');

        final newDocRef = _firestore.collection('caseGroups').doc();
        batch.set(newDocRef, data);
      }
    }

    // 3. Copy Donation Settings (Contacts & Images)
    if (copyDonationSettings) {
      try {
        final latestDonationSnapshot = await _firestore
            .collection('donations')
            .where('seasonId', isEqualTo: sourceSeasonId)
            .orderBy('created_at', descending: true)
            .limit(1)
            .get();

        if (latestDonationSnapshot.docs.isNotEmpty) {
          final latestData = latestDonationSnapshot.docs.first.data();

          final newDonationRef = _firestore.collection('donations').doc();

          // Create initial "Draft" donation with copied settings
          final newDonationData = {
            'seasonId': targetSeasonId,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),

            // Copied Settings
            'contacts': latestData['contacts'] ?? [],
            'carouselImages': latestData['carouselImages'] ?? [],
            'mealImageUrl': latestData['mealImageUrl'],

            // Default Values
            'mealTitle': 'إعدادات أول وجبة (مسودة)',
            'mealDescription': 'تم نسخ بيانات التواصل والصور من الموسم السابق.',
            'numberOfIndividuals': 0,
            'cost': 0,
            'name_publication_status': 'public',
            'seasonable': true,
          };

          batch.set(newDonationRef, newDonationData);
        }
      } catch (e) {
        print('Error copying donation settings: $e');
        // Continue without failing the whole batch
      }
    }

    // 4. Update Season Statistics
    if (copyCases || copyGroups) {
      final seasonRef =
          _firestore.collection(_seasonsCollection).doc(targetSeasonId);

      // We overwrite the statistics map with the new counts
      // Assuming this is a fresh import where we want to set the baseline
      final statsUpdate = {
        'statistics': {
          'totalCases': copiedCasesCount,
          'totalGroups': copiedGroupsCount,
          'totalMealsServed': 0,
          'totalExpenses': 0.0,
          'totalDays': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        }
      };

      batch.set(seasonRef, statsUpdate, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Delete a season and all its associated data
  /// DANGEROUS: Use with caution!
  Future<void> deleteSeason(String seasonId) async {
    // Delete in order: donations, expenses, cases, groups, then season
    final collections = ['donations', 'expenses', 'cases', 'caseGroups'];

    for (var collection in collections) {
      final snapshot = await _firestore
          .collection(collection)
          .where('seasonId', isEqualTo: seasonId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    // Finally delete the season document
    await _firestore.collection(_seasonsCollection).doc(seasonId).delete();

    if (_activeSeasonCache?.id == seasonId) {
      _activeSeasonCache = null;
    }
  }

  /// Clear cache (useful when user logs out)
  void clearCache() {
    _activeSeasonCache = null;
  }
}
