part of 'season_cubit.dart';

/// Base state for seasons
abstract class SeasonState extends Equatable {
  const SeasonState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SeasonInitial extends SeasonState {}

/// Loading state
class SeasonLoading extends SeasonState {}

/// No active season found
class SeasonNoActive extends SeasonState {}

/// Single active season loaded
class SeasonLoaded extends SeasonState {
  final RamadanSeasonModel activeSeason;

  const SeasonLoaded({required this.activeSeason});

  @override
  List<Object?> get props => [activeSeason];
}

/// All seasons loaded (for admin list view)
class SeasonsListLoaded extends SeasonState {
  final List<RamadanSeasonModel> seasons;
  final RamadanSeasonModel? activeSeason;

  const SeasonsListLoaded({
    required this.seasons,
    this.activeSeason,
  });

  @override
  List<Object?> get props => [seasons, activeSeason];
}

/// Season created successfully
class SeasonCreated extends SeasonState {
  final String seasonId;
  final String seasonName;

  const SeasonCreated({required this.seasonId, required this.seasonName});

  @override
  List<Object?> get props => [seasonId, seasonName];
}

/// Season activated successfully
class SeasonActivated extends SeasonState {
  final String seasonId;

  const SeasonActivated({required this.seasonId});

  @override
  List<Object?> get props => [seasonId];
}

/// Season archived successfully
class SeasonArchived extends SeasonState {
  final String seasonId;

  const SeasonArchived({required this.seasonId});

  @override
  List<Object?> get props => [seasonId];
}

/// Season deleted successfully
class SeasonDeleted extends SeasonState {
  final String seasonId;

  const SeasonDeleted({required this.seasonId});

  @override
  List<Object?> get props => [seasonId];
}

/// Season updated successfully
class SeasonUpdated extends SeasonState {
  final String seasonId;

  const SeasonUpdated({required this.seasonId});

  @override
  List<Object?> get props => [seasonId];
}

/// Error state
class SeasonError extends SeasonState {
  final String message;

  const SeasonError(this.message);

  @override
  List<Object?> get props => [message];
}
