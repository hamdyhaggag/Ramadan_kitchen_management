import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class to migrate existing data to support seasons
/// Run this ONCE after creating the first season
class MigrationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate all existing data to a specific season
  /// Call this once with the seasonId of the season you want to assign existing data to
  static Future<Map<String, int>> migrateExistingDataToSeason(
      String seasonId) async {
    int casesCount = 0;
    int groupsCount = 0;
    int donationsCount = 0;
    int expensesCount = 0;

    try {
      // Migrate cases
      final casesSnapshot = await _firestore.collection('cases').get();
      for (var doc in casesSnapshot.docs) {
        if (doc.data()['seasonId'] == null) {
          await doc.reference.update({'seasonId': seasonId});
          casesCount++;
        }
      }

      // Migrate caseGroups
      final groupsSnapshot = await _firestore.collection('caseGroups').get();
      for (var doc in groupsSnapshot.docs) {
        if (doc.data()['seasonId'] == null) {
          await doc.reference.update({'seasonId': seasonId});
          groupsCount++;
        }
      }

      // Migrate donations
      final donationsSnapshot = await _firestore.collection('donations').get();
      for (var doc in donationsSnapshot.docs) {
        if (doc.data()['seasonId'] == null) {
          await doc.reference.update({'seasonId': seasonId});
          donationsCount++;
        }
      }

      // Migrate expenses
      final expensesSnapshot = await _firestore.collection('expenses').get();
      for (var doc in expensesSnapshot.docs) {
        if (doc.data()['seasonId'] == null) {
          await doc.reference.update({'seasonId': seasonId});
          expensesCount++;
        }
      }

      print('✅ Migration complete!');
      print('   Cases: $casesCount');
      print('   Groups: $groupsCount');
      print('   Donations: $donationsCount');
      print('   Expenses: $expensesCount');

      return {
        'cases': casesCount,
        'groups': groupsCount,
        'donations': donationsCount,
        'expenses': expensesCount,
      };
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Check how many documents need migration
  static Future<Map<String, int>> checkMigrationStatus() async {
    int casesNeedMigration = 0;
    int groupsNeedMigration = 0;
    int donationsNeedMigration = 0;
    int expensesNeedMigration = 0;

    final casesSnapshot = await _firestore.collection('cases').get();
    for (var doc in casesSnapshot.docs) {
      if (doc.data()['seasonId'] == null) casesNeedMigration++;
    }

    final groupsSnapshot = await _firestore.collection('caseGroups').get();
    for (var doc in groupsSnapshot.docs) {
      if (doc.data()['seasonId'] == null) groupsNeedMigration++;
    }

    final donationsSnapshot = await _firestore.collection('donations').get();
    for (var doc in donationsSnapshot.docs) {
      if (doc.data()['seasonId'] == null) donationsNeedMigration++;
    }

    final expensesSnapshot = await _firestore.collection('expenses').get();
    for (var doc in expensesSnapshot.docs) {
      if (doc.data()['seasonId'] == null) expensesNeedMigration++;
    }

    return {
      'cases': casesNeedMigration,
      'groups': groupsNeedMigration,
      'donations': donationsNeedMigration,
      'expenses': expensesNeedMigration,
    };
  }
}
