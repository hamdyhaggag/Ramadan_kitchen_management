import 'package:cloud_firestore/cloud_firestore.dart';

class MeatCampaign {
  final String id;
  final String title; // اسم المناسبة
  final String animalType; // نوع الذبيحة (بقرة، عجل، خروف)
  final double weightBefore; // الوزن القائم
  final double weightAfter; // الوزن الصافي (المتاح للتوزيع)
  final double totalDistributed; // ما تم توزيعه حتى الآن
  final DateTime date; // تاريخ النسخة
  final double sharePerPerson; // الحصة الافتراضية لكل فرد (كجم)

  MeatCampaign({
    required this.id,
    required this.title,
    required this.animalType,
    required this.weightBefore,
    required this.weightAfter,
    required this.totalDistributed,
    required this.date,
    this.sharePerPerson = 0.5,
  });

  factory MeatCampaign.fromMap(String id, Map<String, dynamic> map) {
    return MeatCampaign(
      id: id,
      title: map['title'] ?? '',
      animalType: map['animalType'] ?? '',
      weightBefore: (map['weightBefore'] ?? 0.0).toDouble(),
      weightAfter: (map['weightAfter'] ?? 0.0).toDouble(),
      totalDistributed: (map['totalDistributed'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sharePerPerson: (map['sharePerPerson'] ?? 0.5).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'animalType': animalType,
      'weightBefore': weightBefore,
      'weightAfter': weightAfter,
      'totalDistributed': totalDistributed,
      'date': Timestamp.fromDate(date),
      'sharePerPerson': sharePerPerson,
    };
  }
}
