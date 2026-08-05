import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents the current "Landmark Guardian" (fastest record holder) for a hunt.
class GuardianRecordModel extends Equatable {
  const GuardianRecordModel({
    required this.huntId,
    required this.guardianUserId,
    required this.guardianName,
    this.guardianPhotoUrl,
    required this.bestTimeSeconds,
    required this.setAt,
  });

  final String huntId;
  final String guardianUserId;
  final String guardianName;
  final String? guardianPhotoUrl;
  final int bestTimeSeconds;
  final DateTime setAt;

  /// Formatted completion time (e.g. "12m 45s").
  String get formattedTime {
    final m = bestTimeSeconds ~/ 60;
    final s = bestTimeSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  factory GuardianRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GuardianRecordModel.fromJson({'huntId': doc.id, ...data});
  }

  Map<String, dynamic> toFirestore() {
    return {
      'guardianUserId': guardianUserId,
      'guardianName': guardianName,
      'guardianPhotoUrl': guardianPhotoUrl,
      'bestTimeSeconds': bestTimeSeconds,
      'setAt': Timestamp.fromDate(setAt),
    };
  }

  factory GuardianRecordModel.fromJson(Map<String, dynamic> json) {
    return GuardianRecordModel(
      huntId: json['huntId'] as String? ?? '',
      guardianUserId: json['guardianUserId'] as String? ?? '',
      guardianName: json['guardianName'] as String? ?? 'Unknown Hunter',
      guardianPhotoUrl: json['guardianPhotoUrl'] as String?,
      bestTimeSeconds: json['bestTimeSeconds'] as int? ?? 0,
      setAt: _parseDateTime(json['setAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'huntId': huntId,
        'guardianUserId': guardianUserId,
        'guardianName': guardianName,
        'guardianPhotoUrl': guardianPhotoUrl,
        'bestTimeSeconds': bestTimeSeconds,
        'setAt': setAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        huntId,
        guardianUserId,
        guardianName,
        guardianPhotoUrl,
        bestTimeSeconds,
        setAt,
      ];
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}
