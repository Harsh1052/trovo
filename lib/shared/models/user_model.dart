import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  const UserModel({
    required this.uid,
    required this.displayName,
    required this.createdAt,
    required this.lastActiveAt,
    this.email,
    this.photoUrl,
    this.completedHunts = const [],
    this.purchasedHunts = const [],
  });

  final String uid;

  /// Display name is required; falls back to empty string if missing in
  /// Firestore so the UI never receives null.
  final String displayName;

  final String? email;
  final String? photoUrl;
  final List<String> completedHunts;
  final List<String> purchasedHunts;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  // ── Firestore ─────────────────────────────────────────────────────────────

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromJson({'uid': doc.id, ...data});
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    return {
      ...json,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ── JSON (plain Dart / testing) ───────────────────────────────────────────

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      completedHunts: _parseStringList(json['completedHunts']),
      purchasedHunts: _parseStringList(json['purchasedHunts']),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      lastActiveAt: _parseDateTime(json['lastActiveAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'completedHunts': completedHunts,
        'purchasedHunts': purchasedHunts,
        'createdAt': createdAt.toIso8601String(),
        'lastActiveAt': lastActiveAt.toIso8601String(),
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    List<String>? completedHunts,
    List<String>? purchasedHunts,
    DateTime? lastActiveAt,
  }) =>
      UserModel(
        uid: uid,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        completedHunts: completedHunts ?? this.completedHunts,
        purchasedHunts: purchasedHunts ?? this.purchasedHunts,
        createdAt: createdAt,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      );

  // ── Equatable ─────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
        uid,
        displayName,
        email,
        photoUrl,
        completedHunts,
        purchasedHunts,
        createdAt,
        lastActiveAt,
      ];
}

// ── Private helpers ───────────────────────────────────────────────────────────

List<String> _parseStringList(dynamic value) {
  if (value == null) return const [];
  if (value is List) return List<String>.from(value);
  return const [];
}

/// Handles both Firestore [Timestamp] and ISO-8601 [String] values.
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}
