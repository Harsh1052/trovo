import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a single participant in a squad session.
class SquadMemberModel extends Equatable {
  const SquadMemberModel({
    required this.userId,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.isReady,
    required this.joinedAt,
  });

  final String userId;
  final String displayName;
  final double latitude;
  final double longitude;

  /// Whether this member has toggled "Ready" in the lobby.
  final bool isReady;

  final DateTime joinedAt;

  // ── JSON ──────────────────────────────────────────────────────────────────

  factory SquadMemberModel.fromJson(Map<String, dynamic> json) {
    return SquadMemberModel(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isReady: json['isReady'] as bool? ?? false,
      joinedAt: _parseDateTime(json['joinedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'latitude': latitude,
        'longitude': longitude,
        'isReady': isReady,
        'joinedAt': joinedAt.toIso8601String(),
      };

  /// Firestore-ready map (converts [DateTime] → [Timestamp]).
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'displayName': displayName,
        'latitude': latitude,
        'longitude': longitude,
        'isReady': isReady,
        'joinedAt': Timestamp.fromDate(joinedAt),
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  SquadMemberModel copyWith({
    String? displayName,
    double? latitude,
    double? longitude,
    bool? isReady,
  }) =>
      SquadMemberModel(
        userId: userId,
        displayName: displayName ?? this.displayName,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        isReady: isReady ?? this.isReady,
        joinedAt: joinedAt,
      );

  // ── Equatable ─────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
        userId,
        displayName,
        latitude,
        longitude,
        isReady,
        joinedAt,
      ];
}

// ── Private helpers ───────────────────────────────────────────────────────────

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}
