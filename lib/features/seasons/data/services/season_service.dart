import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
    if (_activeSeasonCache != null) return _activeSeasonCache;

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
    if (doc.exists) return RamadanSeasonModel.fromFirestore(doc);
    return null;
  }

  /// Get all archived seasons
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
    if (season.isActive) await _deactivateAllSeasons();
    final docRef = await _firestore
        .collection(_seasonsCollection)
        .add(season.toFirestore());
    if (season.isActive) _activeSeasonCache = season.copyWith(id: docRef.id);
    return docRef.id;
  }

  /// Update an existing season
  Future<void> updateSeason(RamadanSeasonModel season) async {
    if (season.isActive) {
      await _deactivateAllSeasons();
      _activeSeasonCache = season;
    }
    await _firestore
        .collection(_seasonsCollection)
        .doc(season.id)
        .update(season.toFirestore());
  }

  /// Activate a specific season
  Future<void> activateSeason(String seasonId) async {
    await _deactivateAllSeasons();
    await _firestore.collection(_seasonsCollection).doc(seasonId).update({
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _activeSeasonCache = await getSeasonById(seasonId);
  }

  /// Archive a season
  Future<void> archiveSeason(String seasonId) async {
    // Recalculate stats before archiving to ensure accuracy
    await recalculateSeasonStatistics(seasonId);

    await _firestore.collection(_seasonsCollection).doc(seasonId).update({
      'isActive': false,
      'isArchived': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (_activeSeasonCache?.id == seasonId) _activeSeasonCache = null;
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

  /// Delete a season and its associated data
  Future<void> deleteSeason(String seasonId) async {
    final collections = ['donations', 'expenses', 'cases', 'caseGroups'];
    for (var collection in collections) {
      final snapshot = await _firestore
          .collection(collection)
          .where('seasonId', isEqualTo: seasonId)
          .get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) batch.delete(doc.reference);
      await batch.commit();
    }
    await _firestore.collection(_seasonsCollection).doc(seasonId).delete();
  }

  /// Copy data between seasons
  Future<void> copyDataToSeason({
    required String sourceSeasonId,
    required String targetSeasonId,
    bool copyCases = false,
    bool copyGroups = false,
    bool copyDonationSettings = false,
  }) async {
    final batch = _firestore.batch();
    if (copyCases) {
      final snapshot = await _firestore
          .collection('cases')
          .where('seasonId', isEqualTo: sourceSeasonId)
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['seasonId'] = targetSeasonId;
        data['استلم'] = false;
        data['جاهزة'] = false;
        data['هنا؟'] = false;
        batch.set(_firestore.collection('cases').doc(), data);
      }
    }
    if (copyGroups) {
      final snapshot = await _firestore
          .collection('caseGroups')
          .where('seasonId', isEqualTo: sourceSeasonId)
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['seasonId'] = targetSeasonId;
        batch.set(_firestore.collection('caseGroups').doc(), data);
      }
    }

    if (copyDonationSettings) {
      try {
        final snapshot = await _firestore
            .collection('donations')
            .where('seasonId', isEqualTo: sourceSeasonId)
            .orderBy('created_at', descending: true)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          final oldData = snapshot.docs.first.data();
          final newData = {
            'seasonId': targetSeasonId,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
            'contacts': oldData['contacts'] ?? [],
            'carouselImages': oldData['carouselImages'] ?? [],
            'mealImageUrl': oldData['mealImageUrl'],
            'numberOfIndividuals': 0,
            'cost': 0,
            'seasonable': true,
          };
          batch.set(_firestore.collection('donations').doc(), newData);
        }
      } catch (e) {
        debugPrint('Error copying donation settings: $e');
      }
    }
    await batch.commit();
  }

  void clearCache() => _activeSeasonCache = null;

  /// IMPORT & RESTORE LOGIC (With Double De-duplication)
  Future<int> importLegacyData(String targetSeasonId,
      {Function(int current, int total)? onProgress}) async {
    debugPrint('MIGRATION: Starting fetch with double de-duplication...');
    if (onProgress != null) onProgress(0, -1);

    const String knownOldSeasonId = 'bYepWHg3z70Ssa4jahKi';
    final results = await Future.wait([
      _firestore
          .collection('cases')
          .where('seasonId', isEqualTo: knownOldSeasonId)
          .get(),
      _firestore
          .collection('caseGroups')
          .where('seasonId', isEqualTo: knownOldSeasonId)
          .get(),
      _firestore
          .collection('cases')
          .where('seasonId', isEqualTo: targetSeasonId)
          .get(),
      _firestore
          .collection('caseGroups')
          .where('seasonId', isEqualTo: targetSeasonId)
          .get(),
    ]);

    final oldCases = results[0];
    final oldGroups = results[1];
    final targetCasesDocs = results[2].docs;
    final targetGroupsDocs = results[3].docs;

    // List of allowed groups (Whitelist)
    final whitelist = [
      'الشنط الفردية',
      'المجموعة الأولى',
      'المجموعة الثانية',
      'المجموعة الثالثة ( أ )',
      'المجموعة الثالثة (ب)',
      'المجموعة الرابعة',
      'المجموعة الخامسة',
      'المجموعة السادسة',
      'المجموعة السابعة',
      'المجموعة الثامنة',
      'المجموعة التاسعة',
    ];

    String normalize(String s) {
      return s
          .replaceAll(RegExp(r'["' ']|bYep[a-zA-Z0-9]+|zU7[a-zA-Z0-9]+'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll('أ', 'ا')
          .replaceAll('إ', 'ا')
          .replaceAll('آ', 'ا')
          .trim()
          .toLowerCase();
    }

    final normalizedWhitelist = whitelist.map((e) => normalize(e)).toList();

    // Aggressive name cleaner to extract REAL group names (e.g. "الشنط الفردية")
    String extractName(Map<String, dynamic> data, String docId) {
      final fields = ['name', 'اسم المجموعة', 'label', 'title'];
      for (var f in fields) {
        final val = data[f]?.toString() ?? "";
        if (RegExp(r'[\u0600-\u06FF]').hasMatch(val)) return val;
      }
      for (var val in data.values) {
        final s = val.toString();
        if (RegExp(r'[\u0600-\u06FF]').hasMatch(s)) return s;
      }
      return docId;
    }

    // Helper to get consistent case key
    String getCaseKey(Map<String, dynamic> d) {
      final name =
          (d['اسم الحالة'] ?? d['الاسم'] ?? "").toString().trim().toLowerCase();
      final num = (d['رقم الحالة'] ?? d['رقم_الحالة'] ?? "").toString().trim();
      return num.isNotEmpty ? 'num_$num' : 'name_$name';
    }

    // Helper to get consistent group key
    String getGroupKey(Map<String, dynamic> d, String docId) {
      return normalize(extractName(d, docId));
    }

    // 1. Map target already has
    final Set<String> targetCaseKeys =
        targetCasesDocs.map((doc) => getCaseKey(doc.data())).toSet();
    final Set<String> targetGroupKeys =
        targetGroupsDocs.map((doc) => getGroupKey(doc.data(), doc.id)).toSet();

    // 2. Filter old cases
    final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>
        uniqueSourceCases = {};
    for (var doc in oldCases.docs) {
      final key = getCaseKey(doc.data());
      if (key == 'num_' || key == 'name_') continue;
      if (targetCaseKeys.contains(key)) continue;
      if (uniqueSourceCases.containsKey(key)) continue;
      uniqueSourceCases[key] = doc;
    }

    // 3. Filter old groups (Strict Whitelist)
    final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>
        uniqueSourceGroups = {};
    for (var doc in oldGroups.docs) {
      final String rawName = extractName(doc.data(), doc.id);
      final String normName = normalize(rawName);

      if (!normalizedWhitelist.contains(normName))
        continue; // SKIP if not in whitelist
      if (targetGroupKeys.contains(normName)) continue;
      if (uniqueSourceGroups.containsKey(normName)) continue;

      uniqueSourceGroups[normName] = doc;
    }

    final sourceCases = uniqueSourceCases.values.toList();
    final sourceGroups = uniqueSourceGroups.values.toList();
    int totalToImport = sourceCases.length + sourceGroups.length;
    debugPrint(
        'MIGRATION: Unique to import - Cases: ${sourceCases.length}, Groups: ${sourceGroups.length}');

    if (onProgress != null) onProgress(0, totalToImport);

    WriteBatch batch = _firestore.batch();
    int importedCount = 0;
    int batchCount = 0;

    for (var doc in sourceCases) {
      final data = doc.data();
      data['seasonId'] = targetSeasonId;
      data['استلم'] = false;
      data['جاهزة'] = false;
      data['هنا؟'] = false;
      batch.set(_firestore.collection('cases').doc(), data);
      importedCount++;
      batchCount++;
      if (batchCount >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        batchCount = 0;
      }
      if (onProgress != null && importedCount % 50 == 0)
        onProgress(importedCount, totalToImport);
    }

    for (var doc in sourceGroups) {
      final data = Map<String, dynamic>.from(doc.data());
      // Identify the group by its clean name from whitelist
      final String arabName = extractName(data, doc.id);
      data['name'] = arabName;
      data['seasonId'] = targetSeasonId;

      batch.set(_firestore.collection('caseGroups').doc(), data);
      importedCount++;
      batchCount++;
      if (batchCount >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        batchCount = 0;
      }
      if (onProgress != null && importedCount % 50 == 0)
        onProgress(importedCount, totalToImport);
    }

    if (batchCount > 0) await batch.commit();

    // Update Stats & Purge Both
    await recalculateSeasonStatistics(targetSeasonId);
    await purgeDuplicates(targetSeasonId); // Clean UP target
    await purgeDuplicates(knownOldSeasonId); // Clean UP source

    return importedCount;
  }

  /// THE FINAL PURGE - STRICT WHITELIST (Keep only 11 groups)
  Future<int> purgeDuplicates(String seasonId) async {
    debugPrint(
        'PURGE: Starting STRICT Whitelist cleanup for season $seasonId...');

    // 1. Define the Only Groups Allowed
    final whitelist = [
      'الشنط الفردية',
      'المجموعة الأولى',
      'المجموعة الثانية',
      'المجموعة الثالثة ( أ )',
      'المجموعة الثالثة (ب)',
      'المجموعة الرابعة',
      'المجموعة الخامسة',
      'المجموعة السادسة',
      'المجموعة السابعة',
      'المجموعة الثامنة',
      'المجموعة التاسعة',
    ];

    // Normalizer to handle spaces, brackets, etc.
    String normalize(String s) {
      return s
          .replaceAll(RegExp(r'["' ']|bYep[a-zA-Z0-9]+|zU7[a-zA-Z0-9]+'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll('أ', 'ا')
          .replaceAll('إ', 'ا')
          .replaceAll('آ', 'ا')
          .trim();
    }

    final normalizedWhitelist =
        whitelist.map((e) => normalize(e).toLowerCase()).toList();

    // Helper to extract the REAL Arabic name from anything
    String extractArabicName(Map<String, dynamic> data, String docId) {
      final fields = ['name', 'اسم المجموعة', 'label', 'title'];
      for (var f in fields) {
        final val = data[f]?.toString() ?? "";
        if (RegExp(r'[\u0600-\u06FF]').hasMatch(val)) return val;
      }
      for (var val in data.values) {
        final s = val.toString();
        if (RegExp(r'[\u0600-\u06FF]').hasMatch(s)) return s;
      }
      if (RegExp(r'[\u0600-\u06FF]').hasMatch(docId)) return docId;
      return "";
    }

    // 1. Purge Cases (Standard De-duplication)
    final casesSnapshot = await _firestore
        .collection('cases')
        .where('seasonId', isEqualTo: seasonId)
        .get();
    final Map<String, List<DocumentSnapshot>> caseIdentityMap = {};
    for (var doc in casesSnapshot.docs) {
      final d = doc.data();
      final name =
          (d['اسم الحالة'] ?? d['الاسم'] ?? "").toString().trim().toLowerCase();
      final num = (d['رقم الحالة'] ?? d['رقم_الحالة'] ?? "").toString().trim();
      String key =
          num.isNotEmpty ? 'num_$num' : (name.isNotEmpty ? 'name_$name' : "");
      if (key.isNotEmpty) caseIdentityMap.putIfAbsent(key, () => []).add(doc);
    }

    // 2. Fetch All Groups
    final groupsSnapshot = await _firestore
        .collection('caseGroups')
        .where('seasonId', isEqualTo: seasonId)
        .get();

    // Map of: Whitelist Name Index -> List of Documents matching it
    final Map<int, List<DocumentSnapshot>> validGroups = {};
    final List<DocumentSnapshot> junkGroups = [];

    for (var doc in groupsSnapshot.docs) {
      final data = doc.data();
      final rawName = extractArabicName(data, doc.id);
      final normName = normalize(rawName).toLowerCase();

      int index = normalizedWhitelist.indexOf(normName);
      if (index != -1) {
        validGroups.putIfAbsent(index, () => []).add(doc);
      } else {
        // Doesn't match any whitelisted Arabic group
        junkGroups.add(doc);
      }
    }

    int deletedCount = 0;
    WriteBatch batch = _firestore.batch();
    int batchCount = 0;

    // A. Delete Standard Case Duplicates
    for (var docs in caseIdentityMap.values) {
      if (docs.length > 1) {
        for (int i = 1; i < docs.length; i++) {
          batch.delete(docs[i].reference);
          deletedCount++;
          batchCount++;
          if (batchCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }
        }
      }
    }

    // B. Merge and Purge WHITESLISTED Groups
    for (int i = 0; i < whitelist.length; i++) {
      final name = whitelist[i];
      final docs = validGroups[i] ?? [];

      final Set<int> allCases = {};
      for (var doc in docs) {
        final d = doc.data() as Map<String, dynamic>;
        final list = d['caseNumbers'] as List?;
        for (var n in list ?? []) if (n is num) allCases.add(n.toInt());
      }

      if (docs.isNotEmpty) {
        // Update the existing first group
        batch.update(docs.first.reference, {
          'name': name,
          'caseNumbers': allCases.toList()..sort(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        // Delete extras
        for (int j = 1; j < docs.length; j++) {
          batch.delete(docs[j].reference);
          deletedCount++;
          batchCount++;
          if (batchCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }
        }
      } else {
        // CRITICAL: If a whitelisted group is MISSING in this season, create it!
        // This fixes seasons where groups were accidentally wiped or never existed.
        batch.set(_firestore.collection('caseGroups').doc(), {
          'name': name,
          'seasonId': seasonId,
          'caseNumbers': [], // Manager can fill this or we can auto-link later
          'created_at': FieldValue.serverTimestamp(),
        });
        batchCount++;
        if (batchCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }
    }

    // C. Delete ALL JUNK Groups (Not in Whitelist)
    for (var doc in junkGroups) {
      batch.delete(doc.reference);
      deletedCount++;
      batchCount++;
      if (batchCount >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) await batch.commit();
    await recalculateSeasonStatistics(seasonId);
    debugPrint('PURGE: Completed. Deleted $deletedCount junk/duplicate items.');
    return deletedCount;
  }

  /// RE-CALCULATE Statistics (Real-time count)
  Future<void> recalculateSeasonStatistics(String seasonId) async {
    debugPrint('STATS: Recalculating for season $seasonId...');

    final results = await Future.wait([
      _firestore
          .collection('cases')
          .where('seasonId', isEqualTo: seasonId)
          .get(),
      _firestore
          .collection('caseGroups')
          .where('seasonId', isEqualTo: seasonId)
          .get(),
      _firestore
          .collection('donations')
          .where('seasonId', isEqualTo: seasonId)
          .get(),
      _firestore
          .collection('expenses')
          .where('seasonId', isEqualTo: seasonId)
          .get(),
    ]);

    final casesCount = results[0].docs.length;
    final groupsCount = results[1].docs.length;

    int totalMeals = 0;
    for (var doc in results[2].docs) {
      totalMeals += (doc.data()['numberOfIndividuals'] as int?) ?? 0;
    }

    double totalExpenses = 0.0;
    for (var doc in results[3].docs) {
      totalExpenses += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
    }

    await _firestore.collection(_seasonsCollection).doc(seasonId).update({
      'statistics.totalCases': casesCount,
      'statistics.totalGroups': groupsCount,
      'statistics.totalMealsServed': totalMeals,
      'statistics.totalExpenses': totalExpenses,
      'statistics.totalDays': results[2].docs.length,
      'statistics.lastUpdated': FieldValue.serverTimestamp(),
    });

    debugPrint(
        'STATS: Sync complete. Cases: $casesCount, Groups: $groupsCount');
  }
}
