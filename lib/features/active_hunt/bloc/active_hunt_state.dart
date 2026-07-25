import 'package:equatable/equatable.dart';

import '../../../config/constants/app_constants.dart';
import '../../../shared/models/checkpoint_model.dart';
import '../../../shared/models/hunt_model.dart';
import '../../../shared/models/hunt_progress_model.dart';

// Sentinel used in copyWith to distinguish "omitted" from explicit null.
const _keep = Object();

sealed class ActiveHuntState extends Equatable {
  const ActiveHuntState();

  @override
  List<Object?> get props => [];
}

final class ActiveHuntInitial extends ActiveHuntState {
  const ActiveHuntInitial();
}

final class ActiveHuntLoading extends ActiveHuntState {
  const ActiveHuntLoading();
}

final class ActiveHuntCountdown extends ActiveHuntState {
  const ActiveHuntCountdown({required this.hunt, required this.secondsLeft});

  final HuntModel hunt;
  final int secondsLeft;

  @override
  List<Object?> get props => [hunt, secondsLeft];
}

final class ActiveHuntInProgress extends ActiveHuntState {
  const ActiveHuntInProgress({
    required this.hunt,
    required this.checkpoints,
    required this.progress,
    required this.elapsed,
    this.currentLat,
    this.currentLng,
    this.distanceToCheckpoint,
    this.isWithinRange = false,
    this.hintRevealed = false,
    this.isAnswerWrong = false,
    this.showMap = false,
    this.feedbackMessage,
  });

  final HuntModel hunt;
  final List<CheckpointModel> checkpoints;

  /// Full progress document — used for Firestore persistence.
  final HuntProgressModel progress;

  /// Time elapsed since the hunt started (incremented by the internal timer).
  final Duration elapsed;

  final double? currentLat;
  final double? currentLng;

  /// Metres between the player and the current checkpoint. Null until the
  /// first GPS fix arrives.
  final double? distanceToCheckpoint;

  /// Whether the player is within the checkpoint's unlock radius.
  final bool isWithinRange;

  /// Whether the hint for the current checkpoint is currently visible.
  final bool hintRevealed;

  /// True for ~600 ms after a wrong answer — used to animate the input.
  final bool isAnswerWrong;

  /// Whether the map overlay is shown instead of the clue view.
  final bool showMap;

  /// Ephemeral feedback message (wrong answer, too far away, no hints left).
  /// Cleared by the BLoC after a short delay.
  final String? feedbackMessage;

  // ── Computed ──────────────────────────────────────────────────────────────

  int get currentCheckpointIndex => progress.currentCheckpointIndex;

  CheckpointModel get currentCheckpoint =>
      checkpoints[currentCheckpointIndex];

  int get hintsUsed => progress.hintsUsed;

  int get maxHints => AppConstants.maxHintsPerCheckpoint;

  /// How many hints the player can still reveal for the current checkpoint.
  /// 1 if a hint exists, hasn't been revealed yet, and the global limit
  /// hasn't been reached. 0 otherwise.
  int get remainingHints {
    if (currentCheckpoint.hintText.isEmpty) return 0;
    if (hintRevealed) return 0;
    if (hintsUsed >= maxHints) return 0;
    return 1;
  }

  /// 0.0 – 1.0 fraction of checkpoints completed. Safe when total is 0.
  double get progressFraction {
    if (checkpoints.isEmpty) return 0.0;
    return (currentCheckpointIndex / checkpoints.length).clamp(0.0, 1.0);
  }

  /// Whether the player is on the very last checkpoint.
  bool get isLastCheckpoint =>
      currentCheckpointIndex == checkpoints.length - 1;

  /// Whether the hint button should be shown and active.
  bool get canRevealHint => remainingHints > 0;

  /// True when the current checkpoint requires a text answer AND
  /// the player is within the unlock radius (ready to type).
  bool get canSubmitAnswer =>
      currentCheckpoint.isClue && isWithinRange;

  /// Elapsed time formatted as "mm:ss" for the in-hunt timer display.
  String get formattedElapsed {
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  ActiveHuntInProgress copyWith({
    Duration? elapsed,
    double? currentLat,
    double? currentLng,
    double? distanceToCheckpoint,
    bool? isWithinRange,
    bool? hintRevealed,
    bool? isAnswerWrong,
    bool? showMap,
    HuntProgressModel? progress,
    // Pass null explicitly to clear; omit to keep the current value.
    Object? feedbackMessage = _keep,
  }) =>
      ActiveHuntInProgress(
        hunt: hunt,
        checkpoints: checkpoints,
        progress: progress ?? this.progress,
        elapsed: elapsed ?? this.elapsed,
        currentLat: currentLat ?? this.currentLat,
        currentLng: currentLng ?? this.currentLng,
        distanceToCheckpoint:
            distanceToCheckpoint ?? this.distanceToCheckpoint,
        isWithinRange: isWithinRange ?? this.isWithinRange,
        hintRevealed: hintRevealed ?? this.hintRevealed,
        isAnswerWrong: isAnswerWrong ?? this.isAnswerWrong,
        showMap: showMap ?? this.showMap,
        feedbackMessage: identical(feedbackMessage, _keep)
            ? this.feedbackMessage
            : feedbackMessage as String?,
      );

  @override
  List<Object?> get props => [
        hunt,
        checkpoints,
        progress,
        elapsed,
        currentLat,
        currentLng,
        distanceToCheckpoint,
        isWithinRange,
        hintRevealed,
        isAnswerWrong,
        showMap,
        feedbackMessage,
      ];
}

/// Celebration state emitted when a checkpoint is unlocked.
/// Auto-transitions back to [ActiveHuntInProgress] after 2 seconds.
final class ActiveHuntCheckpointUnlocked extends ActiveHuntState {
  const ActiveHuntCheckpointUnlocked({
    required this.checkpointIndex,
    required this.totalCheckpoints,
    this.nextCheckpoint,
  });

  final int checkpointIndex;
  final int totalCheckpoints;

  /// The next checkpoint the player must find. Null when the unlocked
  /// checkpoint was the final one (hunt is about to complete).
  final CheckpointModel? nextCheckpoint;

  @override
  List<Object?> get props => [checkpointIndex, totalCheckpoints, nextCheckpoint];
}

final class ActiveHuntCompleted extends ActiveHuntState {
  const ActiveHuntCompleted({
    required this.progress,
    required this.totalTime,
    required this.hintsUsed,
  });

  final HuntProgressModel progress;
  final Duration totalTime;
  final int hintsUsed;

  @override
  List<Object?> get props => [progress, totalTime, hintsUsed];
}

final class ActiveHuntError extends ActiveHuntState {
  const ActiveHuntError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Location permission was denied by the user.
///
/// [isPermanentlyDenied] distinguishes between a regular "Deny" and Android's
/// "Don't ask again" / iOS "Never". The UI uses this to show either the system
/// dialog trigger or a deep link to app settings.
final class ActiveHuntLocationDenied extends ActiveHuntState {
  const ActiveHuntLocationDenied({
    required this.huntId,
    required this.userId,
    this.isPermanentlyDenied = false,
  });

  final String huntId;
  final String userId;
  final bool isPermanentlyDenied;

  @override
  List<Object?> get props => [huntId, userId, isPermanentlyDenied];
}

