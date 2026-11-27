import 'package:cloud_firestore/cloud_firestore.dart';

class WeightLogModel {
  const WeightLogModel({
    required this.weightId,
    required this.weightKg,
    required this.recordedAt,
    required this.dateKey,
    this.note,
    this.createdAt,
  });

  final String weightId;
  final double weightKg;
  final DateTime recordedAt;
  final String dateKey;
  final String? note;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'weightKg': weightKg,
    'recordedAt': Timestamp.fromDate(recordedAt),
    'dateKey': dateKey,
    'note': note,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };

  factory WeightLogModel.fromMap(String weightId, Map<String, dynamic> map) =>
      WeightLogModel(
        weightId: weightId,
        weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0,
        recordedAt: (map['recordedAt'] as Timestamp).toDate(),
        dateKey: map['dateKey'] as String? ?? '',
        note: map['note'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}
