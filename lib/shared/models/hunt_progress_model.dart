import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum HuntStatus {
  inProgress,
  completed,
  abandoned;

  /// Firestore storage value (snake_case to match spec).
  String get storageName => switch (this) {
        HuntStatus.inProgress => 'in_progress',
        HuntStatus.completed => 'completed',
        HuntStatus.abandoned => 'abandoned',
      };

  static HuntStatus fromStorageName(String? name) => switch (name) {
        'completed' => HuntStatus.completed,
        'abandoned' => HuntStatus.abandoned,
        _ => HuntStatus.inProgress,
      };
}

class HuntProgressModel extends Equatable {
  const HuntProgressModel({
    required this.documentId,
    required this.userId,
    required this.huntId,
    required this.status,
    required this.currentCheckpointIndex,
    required this.hintsUsed,
    required this.startedAt,
    this.completedAt,
    this.checkpointTimestamps = const {},
  });

  /// Firestore document ID, formatted as `{userId}_{huntId}`.
  final String documentId;

  final String userId;
  final String huntId;
  final HuntStatus status;
  final int currentCheckpointIndex;
  final int hintsUsed;
  final DateTime startedAt;
  final DateTime? completedAt;

  /// Maps checkpoint ID → the DateTime when that checkpoint was completed.
  final Map<String, DateTime> checkpointTimestamps;

  // ── Derived ───────────────────────────────────────────────────────────────

  bool get isComplete => status == HuntStatus.completed;
  bool get isActive => status == HuntStatus.inProgress;

  /// IDs of all checkpoints that have been completed.
  List<String> get completedCheckpointIds =>
      checkpointTimestamps.keys.toList();

  // ── Firestore ─────────────────────────────────────────────────────────────

  factory HuntProgressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HuntProgressModel.fromJson({'documentId': doc.id, ...data});
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'huntId': huntId,
      'status': status.storageName,
      'currentCheckpointIndex': currentCheckpointIndex,
      'hintsUsed': hintsUsed,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'checkpointTimestamps': checkpointTimestamps
          .map((k, v) => MapEntry(k, Timestamp.fromDate(v))),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ── JSON ──────────────────────────────────────────────────────────────────

  factory HuntProgressModel.fromJson(Map<String, dynamic> json) {
    return HuntProgressModel(
      documentId: json['documentId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      huntId: json['huntId'] as String? ?? '',
      status: HuntStatus.fromStorageName(json['status'] as String?),
      currentCheckpointIndex:
          json['currentCheckpointIndex'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      startedAt: _parseDateTime(json['startedAt']) ?? DateTime.now(),
      completedAt: _parseDateTime(json['completedAt']),
      checkpointTimestamps:
          _parseTimestampMap(json['checkpointTimestamps']),
    );
  }

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'userId': userId,
        'huntId': huntId,
        'status': status.storageName,
        'currentCheckpointIndex': currentCheckpointIndex,
        'hintsUsed': hintsUsed,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'checkpointTimestamps': checkpointTimestamps
            .map((k, v) => MapEntry(k, v.toIso8601String())),
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  HuntProgressModel copyWith({
    HuntStatus? status,
    int? currentCheckpointIndex,
    int? hintsUsed,
    DateTime? completedAt,
    Map<String, DateTime>? checkpointTimestamps,
  }) =>
      HuntProgressModel(
        documentId: documentId,
        userId: userId,
        huntId: huntId,
        status: status ?? this.status,
        currentCheckpointIndex:
            currentCheckpointIndex ?? this.currentCheckpointIndex,
        hintsUsed: hintsUsed ?? this.hintsUsed,
        startedAt: startedAt,
        completedAt: completedAt ?? this.completedAt,
        checkpointTimestamps:
            checkpointTimestamps ?? this.checkpointTimestamps,
      );

  // ── Equatable ─────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
        documentId,
        userId,
        huntId,
        status,
        currentCheckpointIndex,
        hintsUsed,
        startedAt,
        completedAt,
        checkpointTimestamps,
      ];
}

// ── Private helpers ───────────────────────────────────────────────────────────

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Map<String, DateTime> _parseTimestampMap(dynamic value) {
  if (value == null) return const {};
  if (value is! Map) return const {};
  return Map.fromEntries(
    value.entries.map((e) {
      final dt = _parseDateTime(e.value);
      return dt != null ? MapEntry(e.key as String, dt) : null;
    }).whereType<MapEntry<String, DateTime>>(),
  );
}
