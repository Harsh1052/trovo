import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'squad_member_model.dart';

/// Lifecycle of a squad session.
enum SquadStatus {
  lobby,
  active,
  completed;

  /// Firestore storage value (snake_case to match spec).
  String get storageName => switch (this) {
        SquadStatus.lobby => 'lobby',
        SquadStatus.active => 'active',
        SquadStatus.completed => 'completed',
      };

  static SquadStatus fromStorageName(String? name) => switch (name) {
        'active' => SquadStatus.active,
        'completed' => SquadStatus.completed,
        _ => SquadStatus.lobby,
      };
}

/// Represents a live multiplayer squad session stored in Firestore.
///
/// Members are stored as a list inside the document (not a sub-collection)
/// so that a single `.snapshots()` listener provides the full squad state.
class SquadSessionModel extends Equatable {
  const SquadSessionModel({
    required this.squadId,
    required this.roomCode,
    required this.huntId,
    required this.hostUserId,
    required this.status,
    required this.currentCheckpointIndex,
    required this.squadScore,
    required this.createdAt,
    required this.lastActivityAt,
    required this.members,
  });

  /// Firestore document ID (e.g. auto-generated or "SQ-4892").
  final String squadId;

  /// 4-digit numeric join code.
  final String roomCode;

  /// Which hunt this squad is playing.
  final String huntId;

  /// UID of the room creator / captain.
  final String hostUserId;

  final SquadStatus status;

  /// Shared squad progress — index of the current checkpoint.
  final int currentCheckpointIndex;

  /// Cumulative squad score (for leaderboard / future use).
  final int squadScore;

  final DateTime createdAt;

  /// Updated on every meaningful squad action; used for TTL cleanup.
  final DateTime lastActivityAt;

  /// All participants, including the host.
  final List<SquadMemberModel> members;

  // ── Computed helpers ───────────────────────────────────────────────────────

  /// Maximum number of players allowed in a single squad.
  static const int maxMembers = 4;

  /// True when the squad is in the lobby awaiting all members to ready up.
  bool get isLobby => status == SquadStatus.lobby;

  /// True when the squad is actively playing.
  bool get isActive => status == SquadStatus.active;

  /// True when the session has ended.
  bool get isCompleted => status == SquadStatus.completed;

  /// Whether the squad still has room for new members.
  bool get hasRoom => members.length < maxMembers;

  /// Whether every member has toggled "ready".
  bool get allMembersReady =>
      members.isNotEmpty && members.every((m) => m.isReady);

  /// Number of current members.
  int get memberCount => members.length;

  /// Find a member by user ID (returns null if not found).
  SquadMemberModel? memberById(String userId) {
    final idx = members.indexWhere((m) => m.userId == userId);
    return idx >= 0 ? members[idx] : null;
  }

  /// Whether the given user is the host of this squad.
  bool isHost(String userId) => hostUserId == userId;

  /// True if the session has been inactive for over [hours].
  bool isExpired({int hours = 4}) =>
      DateTime.now().difference(lastActivityAt).inHours >= hours;

  // ── Firestore ─────────────────────────────────────────────────────────────

  factory SquadSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SquadSessionModel.fromJson({'squadId': doc.id, ...data});
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomCode': roomCode,
      'huntId': huntId,
      'hostUserId': hostUserId,
      'status': status.storageName,
      'currentCheckpointIndex': currentCheckpointIndex,
      'squadScore': squadScore,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivityAt': Timestamp.fromDate(lastActivityAt),
      'members': members.map((m) => m.toFirestore()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ── JSON ──────────────────────────────────────────────────────────────────

  factory SquadSessionModel.fromJson(Map<String, dynamic> json) {
    return SquadSessionModel(
      squadId: json['squadId'] as String? ?? '',
      roomCode: json['roomCode'] as String? ?? '',
      huntId: json['huntId'] as String? ?? '',
      hostUserId: json['hostUserId'] as String? ?? '',
      status: SquadStatus.fromStorageName(json['status'] as String?),
      currentCheckpointIndex:
          json['currentCheckpointIndex'] as int? ?? 0,
      squadScore: json['squadScore'] as int? ?? 0,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      lastActivityAt:
          _parseDateTime(json['lastActivityAt']) ?? DateTime.now(),
      members: _parseMembersList(json['members']),
    );
  }

  Map<String, dynamic> toJson() => {
        'squadId': squadId,
        'roomCode': roomCode,
        'huntId': huntId,
        'hostUserId': hostUserId,
        'status': status.storageName,
        'currentCheckpointIndex': currentCheckpointIndex,
        'squadScore': squadScore,
        'createdAt': createdAt.toIso8601String(),
        'lastActivityAt': lastActivityAt.toIso8601String(),
        'members': members.map((m) => m.toJson()).toList(),
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  SquadSessionModel copyWith({
    SquadStatus? status,
    int? currentCheckpointIndex,
    int? squadScore,
    DateTime? lastActivityAt,
    List<SquadMemberModel>? members,
  }) =>
      SquadSessionModel(
        squadId: squadId,
        roomCode: roomCode,
        huntId: huntId,
        hostUserId: hostUserId,
        status: status ?? this.status,
        currentCheckpointIndex:
            currentCheckpointIndex ?? this.currentCheckpointIndex,
        squadScore: squadScore ?? this.squadScore,
        createdAt: createdAt,
        lastActivityAt: lastActivityAt ?? this.lastActivityAt,
        members: members ?? this.members,
      );

  // ── Equatable ─────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
        squadId,
        roomCode,
        huntId,
        hostUserId,
        status,
        currentCheckpointIndex,
        squadScore,
        createdAt,
        lastActivityAt,
        members,
      ];
}

// ── Private helpers ───────────────────────────────────────────────────────────

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<SquadMemberModel> _parseMembersList(dynamic value) {
  if (value == null) return const [];
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(SquadMemberModel.fromJson)
      .toList();
}
