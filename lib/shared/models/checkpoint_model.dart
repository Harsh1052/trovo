import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum CheckpointType {
  /// Player must solve a clue and submit a text answer.
  clue,

  /// Player must take a photo at the location.
  photoTask;

  /// Firestore storage value (matches the spec's `photo_task` snake_case).
  String get storageName => switch (this) {
        CheckpointType.clue => 'clue',
        CheckpointType.photoTask => 'photo_task',
      };

  static CheckpointType fromStorageName(String? name) => switch (name) {
        'photo_task' => CheckpointType.photoTask,
        'clue' => CheckpointType.clue,
        _ => CheckpointType.clue,
      };
}

class CheckpointModel extends Equatable {
  const CheckpointModel({
    required this.checkpointId,
    required this.huntId,
    required this.orderIndex,
    required this.clueText,
    required this.hintText,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.answer,
    this.unlockRadius = 20,
    this.funFact,
    this.imageUrl,
    this.targetText,
  });

  final String checkpointId;
  final String huntId;

  /// Position in the hunt sequence (0-based).
  final int orderIndex;

  /// The clue/riddle the player must solve.
  final String clueText;

  /// A single hint revealed on request. Empty string if no hint configured.
  final String hintText;

  final double latitude;
  final double longitude;
  final CheckpointType type;

  /// Expected answer for [CheckpointType.clue]. Null for photo tasks.
  final String? answer;

  /// GPS radius in metres within which the checkpoint can be unlocked.
  final int unlockRadius;

  /// Optional fun fact shown after the checkpoint is completed.
  final String? funFact;

  /// Optional 3D graphic / illustration asset for this checkpoint.
  final String? imageUrl;

  /// Optional target text/letter expected in photo verification tasks (e.g. 'A', 'SARTHANA').
  final String? targetText;

  // ── Computed helpers ───────────────────────────────────────────────────

  /// True when this checkpoint requires a photo submission.
  bool get isPhotoTask => type == CheckpointType.photoTask;

  /// True when this checkpoint requires a text answer.
  bool get isClue => type == CheckpointType.clue;

  /// True when a hint is configured for this checkpoint.
  bool get hasHint => hintText.isNotEmpty;

  /// True when a fun fact is available to show post-completion.
  bool get hasFunFact => funFact != null && funFact!.isNotEmpty;

  /// Human-readable label for the checkpoint type, e.g. for accessibility
  /// or filter chips: "Clue" / "Photo Task".
  String get displayLabel => switch (type) {
        CheckpointType.clue => 'Clue',
        CheckpointType.photoTask => 'Photo Task',
      };

  // ── Firestore ─────────────────────────────────────────────────────────────

  factory CheckpointModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CheckpointModel.fromJson({'checkpointId': doc.id, ...data});
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    return json..remove('checkpointId');
  }

  // ── JSON ──────────────────────────────────────────────────────────────────

  factory CheckpointModel.fromJson(Map<String, dynamic> json) {
    return CheckpointModel(
      checkpointId: json['checkpointId'] as String? ?? '',
      huntId: json['huntId'] as String? ?? '',
      orderIndex: json['orderIndex'] as int? ?? 0,
      clueText: json['clueText'] as String? ?? '',
      hintText: json['hintText'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      type: CheckpointType.fromStorageName(json['type'] as String?),
      answer: json['answer'] as String?,
      unlockRadius: json['unlockRadius'] as int? ?? 20,
      funFact: json['funFact'] as String?,
      imageUrl: json['imageUrl'] as String?,
      targetText: json['targetText'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'checkpointId': checkpointId,
        'huntId': huntId,
        'orderIndex': orderIndex,
        'clueText': clueText,
        'hintText': hintText,
        'latitude': latitude,
        'longitude': longitude,
        'type': type.storageName,
        'answer': answer,
        'unlockRadius': unlockRadius,
        'funFact': funFact,
        'imageUrl': imageUrl,
        'targetText': targetText,
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  CheckpointModel copyWith({
    String? clueText,
    String? hintText,
    double? latitude,
    double? longitude,
    CheckpointType? type,
    String? answer,
    int? unlockRadius,
    String? funFact,
    String? imageUrl,
    String? targetText,
  }) =>
      CheckpointModel(
        checkpointId: checkpointId,
        huntId: huntId,
        orderIndex: orderIndex,
        clueText: clueText ?? this.clueText,
        hintText: hintText ?? this.hintText,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        type: type ?? this.type,
        answer: answer ?? this.answer,
        unlockRadius: unlockRadius ?? this.unlockRadius,
        funFact: funFact ?? this.funFact,
        imageUrl: imageUrl ?? this.imageUrl,
        targetText: targetText ?? this.targetText,
      );

  // ── Equatable ─────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
        checkpointId,
        huntId,
        orderIndex,
        clueText,
        hintText,
        latitude,
        longitude,
        type,
        answer,
        unlockRadius,
        funFact,
        imageUrl,
        targetText,
      ];
}
