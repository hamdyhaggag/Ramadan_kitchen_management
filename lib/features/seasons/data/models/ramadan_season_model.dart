import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a Ramadan season/year
/// Each season contains its own data (cases, groups, donations, expenses)
class RamadanSeasonModel {
  final String id;
  final String name; // e.g., "رمضان 1447 هـ - 2026"
  final String hijriYear; // e.g., "1447"
  final String gregorianYear; // e.g., "2026"
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive; // Only one season can be active at a time
  final bool isArchived; // Marked as completed/archived
  final bool isMigratedToV2; // If the data is moved to sub-collections
  final DateTime createdAt;
  final DateTime? updatedAt;
  final SeasonStatistics? statistics; // Cached statistics for quick access

  RamadanSeasonModel({
    required this.id,
    required this.name,
    required this.hijriYear,
    required this.gregorianYear,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
    this.isArchived = false,
    this.isMigratedToV2 = false,
    required this.createdAt,
    this.updatedAt,
    this.statistics,
  });

  factory RamadanSeasonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RamadanSeasonModel(
      id: doc.id,
      name: data['name'] ?? '',
      hijriYear: data['hijriYear'] ?? '',
      gregorianYear: data['gregorianYear'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? false,
      isArchived: data['isArchived'] ?? false,
      isMigratedToV2: data['isMigratedToV2'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      statistics: data['statistics'] != null
          ? SeasonStatistics.fromMap(data['statistics'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'hijriYear': hijriYear,
      'gregorianYear': gregorianYear,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'isArchived': isArchived,
      'isMigratedToV2': isMigratedToV2,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'statistics': statistics?.toMap(),
    };
  }

  RamadanSeasonModel copyWith({
    String? id,
    String? name,
    String? hijriYear,
    String? gregorianYear,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isArchived,
    bool? isMigratedToV2,
    DateTime? createdAt,
    DateTime? updatedAt,
    SeasonStatistics? statistics,
  }) {
    return RamadanSeasonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      hijriYear: hijriYear ?? this.hijriYear,
      gregorianYear: gregorianYear ?? this.gregorianYear,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      isMigratedToV2: isMigratedToV2 ?? this.isMigratedToV2,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statistics: statistics ?? this.statistics,
    );
  }

  /// Check if the season is currently ongoing
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Get the duration of the season in days
  int get durationInDays => endDate.difference(startDate).inDays;

  /// Get a formatted date range string
  String get dateRangeFormatted {
    return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Cached statistics for a season (updated periodically)
class SeasonStatistics {
  final int totalCases;
  final int totalGroups;
  final int totalMealsServed;
  final double totalExpenses;
  final int totalDays;
  final DateTime? lastUpdated;

  SeasonStatistics({
    this.totalCases = 0,
    this.totalGroups = 0,
    this.totalMealsServed = 0,
    this.totalExpenses = 0.0,
    this.totalDays = 0,
    this.lastUpdated,
  });

  factory SeasonStatistics.fromMap(Map<String, dynamic> map) {
    return SeasonStatistics(
      totalCases: map['totalCases'] ?? 0,
      totalGroups: map['totalGroups'] ?? 0,
      totalMealsServed: map['totalMealsServed'] ?? 0,
      totalExpenses: (map['totalExpenses'] ?? 0.0).toDouble(),
      totalDays: map['totalDays'] ?? 0,
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalCases': totalCases,
      'totalGroups': totalGroups,
      'totalMealsServed': totalMealsServed,
      'totalExpenses': totalExpenses,
      'totalDays': totalDays,
      'lastUpdated':
          lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  SeasonStatistics copyWith({
    int? totalCases,
    int? totalGroups,
    int? totalMealsServed,
    double? totalExpenses,
    int? totalDays,
    DateTime? lastUpdated,
  }) {
    return SeasonStatistics(
      totalCases: totalCases ?? this.totalCases,
      totalGroups: totalGroups ?? this.totalGroups,
      totalMealsServed: totalMealsServed ?? this.totalMealsServed,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalDays: totalDays ?? this.totalDays,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
