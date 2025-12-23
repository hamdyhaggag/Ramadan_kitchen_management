import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/models/ramadan_season_model.dart';
import '../data/services/season_service.dart';

part 'season_state.dart';

/// Cubit for managing Ramadan seasons state
class SeasonCubit extends Cubit<SeasonState> {
  final SeasonService _seasonService;

  SeasonCubit({SeasonService? seasonService})
      : _seasonService = seasonService ?? SeasonService(),
        super(SeasonInitial()) {
    _init();
  }

  /// Initialize by loading the active season
  Future<void> _init() async {
    await loadActiveSeason();
  }

  /// Load the currently active season
  Future<void> loadActiveSeason() async {
    emit(SeasonLoading());
    try {
      final activeSeason = await _seasonService.getActiveSeason();
      if (activeSeason != null) {
        emit(SeasonLoaded(activeSeason: activeSeason));
      } else {
        emit(SeasonNoActive());
      }
    } catch (e) {
      emit(SeasonError('فشل تحميل الموسم النشط: $e'));
    }
  }

  /// Get the active season ID for queries
  String? get activeSeasonId => _seasonService.activeSeasonId;

  /// Load all seasons (for admin view)
  Future<void> loadAllSeasons() async {
    emit(SeasonLoading());
    try {
      final seasons = await _seasonService.getSeasonsStream().first;
      final activeSeason = await _seasonService.getActiveSeason();
      emit(SeasonsListLoaded(
        seasons: seasons,
        activeSeason: activeSeason,
      ));
    } catch (e) {
      emit(SeasonError('فشل تحميل المواسم: $e'));
    }
  }

  /// Create a new season
  // Legacy migration removed

  Future<void> createSeason({
    required String name,
    required String hijriYear,
    required String gregorianYear,
    required DateTime startDate,
    required DateTime endDate,
    bool isActive = false,
    bool copyFromPreviousSeason = false,
    bool copyDonationSettings = false,
    String? sourceSeasonId,
  }) async {
    emit(SeasonLoading());
    try {
      final newSeason = RamadanSeasonModel(
        id: '', // Will be set by Firestore
        name: name,
        hijriYear: hijriYear,
        gregorianYear: gregorianYear,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
        createdAt: DateTime.now(),
      );

      final seasonId = await _seasonService.createSeason(newSeason);

      // If requested, copy data from previous season
      if (copyFromPreviousSeason || copyDonationSettings) {
        // Auto-detect source season if not provided
        String? actualSourceId = sourceSeasonId;
        if (actualSourceId == null) {
          final seasons = await _seasonService.getSeasonsStream().first;
          if (seasons.isNotEmpty) {
            // Use the latest created season as source
            actualSourceId = seasons.first.id;
          }
        }

        if (actualSourceId != null) {
          await _seasonService.copyDataToSeason(
            sourceSeasonId: actualSourceId,
            targetSeasonId: seasonId,
            copyCases: copyFromPreviousSeason,
            copyGroups: copyFromPreviousSeason,
            copyDonationSettings: copyDonationSettings,
          );
        }
      }

      emit(SeasonCreated(seasonId: seasonId, seasonName: name));

      // Reload seasons list
      await loadAllSeasons();
    } catch (e) {
      emit(SeasonError('فشل إنشاء الموسم: $e'));
    }
  }

  /// Import specific data from a previous season to an existing season
  Future<void> importDataFromSeason({
    required String targetSeasonId,
    required String sourceSeasonId,
    bool importCases = false,
    bool importGroups = false,
    bool importDonationSettings = false,
  }) async {
    emit(SeasonLoading());
    try {
      // We can use the existing service method, but we might need to split it
      // or call it with specific flags if we refactor the service.
      // For now, let's use the flexible method we created.

      // Note: The service method 'copyCasesAndGroupsToNewSeason' currently copies cases AND groups if called.
      // We should probably refactor the service to be more granular or use flags.
      // However, to save time/risk, we will use the existing method which does loops.
      // But wait, the existing service method does ALL checks inside.
      // Let's assume we update service or -- actually let's update the service to accept flags for cases/groups too.

      await _seasonService.copyDataToSeason(
        sourceSeasonId: sourceSeasonId,
        targetSeasonId: targetSeasonId,
        copyCases: importCases,
        copyGroups: importGroups,
        copyDonationSettings: importDonationSettings,
      );

      emit(SeasonUpdated(seasonId: targetSeasonId));
      await loadAllSeasons();
    } catch (e) {
      emit(SeasonError('فشل استيراد البيانات: $e'));
    }
  }

  /// Activate a season
  Future<void> activateSeason(String seasonId) async {
    emit(SeasonLoading());
    try {
      await _seasonService.activateSeason(seasonId);
      emit(SeasonActivated(seasonId: seasonId));
      await loadAllSeasons();
    } catch (e) {
      emit(SeasonError('فشل تفعيل الموسم: $e'));
    }
  }

  /// Archive a season
  Future<void> archiveSeason(String seasonId) async {
    emit(SeasonLoading());
    try {
      await _seasonService.archiveSeason(seasonId);
      emit(SeasonArchived(seasonId: seasonId));
      await loadAllSeasons();
    } catch (e) {
      emit(SeasonError('فشل أرشفة الموسم: $e'));
    }
  }

  /// Delete a season (with confirmation)
  Future<void> deleteSeason(String seasonId) async {
    emit(SeasonLoading());
    try {
      await _seasonService.deleteSeason(seasonId);
      emit(SeasonDeleted(seasonId: seasonId));
      await loadAllSeasons();
    } catch (e) {
      emit(SeasonError('فشل حذف الموسم: $e'));
    }
  }

  /// Update season details
  Future<void> updateSeason(RamadanSeasonModel season) async {
    emit(SeasonLoading());
    try {
      await _seasonService.updateSeason(season);
      emit(SeasonUpdated(seasonId: season.id));
      await loadAllSeasons();
    } catch (e) {
      emit(SeasonError('فشل تحديث الموسم: $e'));
    }
  }

  /// Get season by ID
  Future<RamadanSeasonModel?> getSeasonById(String seasonId) async {
    return await _seasonService.getSeasonById(seasonId);
  }

  /// Clear cache on logout
  void clearCache() {
    _seasonService.clearCache();
    emit(SeasonInitial());
  }
}
