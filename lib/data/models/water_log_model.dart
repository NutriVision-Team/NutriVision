import 'package:cloud_firestore/cloud_firestore.dart';

class WaterLogModel {
  const WaterLogModel({
    required this.waterId,
    required this.amountMl,
    required this.consumedAt,
    required this.dateKey,
    this.createdAt,
  });

  final String waterId;
  final double amountMl;
  final DateTime consumedAt;
  final String dateKey;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'amountMl': amountMl,
    'consumedAt': Timestamp.fromDate(consumedAt),
    'dateKey': dateKey,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };

  factory WaterLogModel.fromMap(String waterId, Map<String, dynamic> map) =>
      WaterLogModel(
        waterId: waterId,
        amountMl: (map['amountMl'] as num?)?.toDouble() ?? 0,
        consumedAt: (map['consumedAt'] as Timestamp).toDate(),
        dateKey: map['dateKey'] as String? ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}
