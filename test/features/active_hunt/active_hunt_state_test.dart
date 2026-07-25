import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/features/active_hunt/bloc/active_hunt_state.dart';
import 'package:huntermania/shared/models/checkpoint_model.dart';
import 'package:huntermania/shared/models/hunt_model.dart';
import 'package:huntermania/shared/models/hunt_progress_model.dart';

void main() {
  // ── Fixtures ────────────────────────────────────────────────────────────────

  CheckpointModel makeCheckpoint({
    int index = 0,
    CheckpointType type = CheckpointType.clue,
    String hint = 'Some hint',
    String? funFact,
  }) =>
      CheckpointModel(
        checkpointId: 'cp_$index',
        huntId: 'hunt_1',
        orderIndex: index,
        clueText: 'Clue $index',
        hintText: hint,
        latitude: 12.0 + index,
        longitude: 77.0 + index,
        type: type,
        unlockRadius: 20,
        funFact: funFact,
      );

  HuntModel makeHunt() => HuntModel(
        huntId: 'hunt_1',
        title: 'Test Hunt',
        description: 'Desc',
        city: 'Mumbai',
        gardenName: 'Test Garden',
        isFree: true,
        difficulty: HuntDifficulty.easy,
        durationMinutes: 60,
        checkpointCount: 3,
        price: 0,
        coverImageUrl: '',
        startLatitude: 12.9716,
        startLongitude: 77.5946,
        createdAt: DateTime(2025),
        isActive: true,
      );

  HuntProgressModel makeProgress({int checkpoint = 0, int hints = 0}) =>
      HuntProgressModel(
        documentId: 'user1_hunt1',
        userId: 'user1',
        huntId: 'hunt_1',
        status: HuntStatus.inProgress,
        currentCheckpointIndex: checkpoint,
        hintsUsed: hints,
        startedAt: DateTime(2025, 5, 1, 10, 0),
      );

  ActiveHuntInProgress makeState({
    int checkpointIndex = 0,
    int totalCheckpoints = 3,
    int hintsUsed = 0,
    bool hintRevealed = false,
    bool isWithinRange = false,
    Duration elapsed = const Duration(minutes: 7, seconds: 42),
    CheckpointType checkpointType = CheckpointType.clue,
    String hint = 'Hint text',
  }) {
    final checkpoints = List.generate(
      totalCheckpoints,
      (i) => makeCheckpoint(
        index: i,
        type: i == checkpointIndex ? checkpointType : CheckpointType.clue,
        hint: i == checkpointIndex ? hint : 'other hint',
      ),
    );

    return ActiveHuntInProgress(
      hunt: makeHunt(),
      checkpoints: checkpoints,
      progress: makeProgress(checkpoint: checkpointIndex, hints: hintsUsed),
      elapsed: elapsed,
      hintRevealed: hintRevealed,
      isWithinRange: isWithinRange,
    );
  }

  // ── progressFraction ────────────────────────────────────────────────────────

  group('progressFraction', () {
    test('returns 0.0 when at the first checkpoint', () {
      final state = makeState(checkpointIndex: 0, totalCheckpoints: 3);
      expect(state.progressFraction, closeTo(0.0, 0.001));
    });

    test('returns 0.33 at checkpoint 1 of 3', () {
      final state = makeState(checkpointIndex: 1, totalCheckpoints: 3);
      expect(state.progressFraction, closeTo(1 / 3, 0.001));
    });

    test('returns 0.66 at checkpoint 2 of 3', () {
      final state = makeState(checkpointIndex: 2, totalCheckpoints: 3);
      expect(state.progressFraction, closeTo(2 / 3, 0.001));
    });

    test('returns 0.0 when checkpoints list is empty', () {
      final state = ActiveHuntInProgress(
        hunt: makeHunt(),
        checkpoints: const [],
        progress: makeProgress(),
        elapsed: Duration.zero,
      );
      expect(state.progressFraction, 0.0);
    });

    test('clamps to 1.0 even when index exceeds list size', () {
      // Defensive: progress index should never exceed length but guard anyway.
      final checkpoints = [makeCheckpoint()];
      final state = ActiveHuntInProgress(
        hunt: makeHunt(),
        checkpoints: checkpoints,
        progress: makeProgress(checkpoint: 0),
        elapsed: Duration.zero,
      );
      expect(state.progressFraction, lessThanOrEqualTo(1.0));
      expect(state.progressFraction, greaterThanOrEqualTo(0.0));
    });
  });

  // ── isLastCheckpoint ────────────────────────────────────────────────────────

  group('isLastCheckpoint', () {
    test('returns false when not on the last checkpoint', () {
      expect(makeState(checkpointIndex: 0, totalCheckpoints: 3).isLastCheckpoint, isFalse);
    });

    test('returns true when on the last checkpoint', () {
      expect(makeState(checkpointIndex: 2, totalCheckpoints: 3).isLastCheckpoint, isTrue);
    });

    test('returns true for a single-checkpoint hunt', () {
      expect(makeState(checkpointIndex: 0, totalCheckpoints: 1).isLastCheckpoint, isTrue);
    });
  });

  // ── canRevealHint ────────────────────────────────────────────────────────────

  group('canRevealHint', () {
    test('returns true when hint exists and not yet revealed', () {
      expect(makeState(hint: 'Hint!', hintRevealed: false).canRevealHint, isTrue);
    });

    test('returns false when hint already revealed', () {
      expect(makeState(hint: 'Hint!', hintRevealed: true).canRevealHint, isFalse);
    });

    test('returns false when hintText is empty', () {
      expect(makeState(hint: '').canRevealHint, isFalse);
    });

    test('returns false when hint limit reached', () {
      // maxHintsPerCheckpoint is 3; with 3 hints used it should block.
      expect(
        makeState(hint: 'Hint!', hintsUsed: 3, hintRevealed: false).canRevealHint,
        isFalse,
      );
    });
  });

  // ── canSubmitAnswer ───────────────────────────────────────────────────────────

  group('canSubmitAnswer', () {
    test('returns true for clue checkpoint when within range', () {
      expect(
        makeState(checkpointType: CheckpointType.clue, isWithinRange: true).canSubmitAnswer,
        isTrue,
      );
    });

    test('returns false for clue checkpoint when out of range', () {
      expect(
        makeState(checkpointType: CheckpointType.clue, isWithinRange: false).canSubmitAnswer,
        isFalse,
      );
    });

    test('returns false for photo checkpoint even when within range', () {
      expect(
        makeState(checkpointType: CheckpointType.photoTask, isWithinRange: true).canSubmitAnswer,
        isFalse,
      );
    });
  });

  // ── formattedElapsed ─────────────────────────────────────────────────────────

  group('formattedElapsed', () {
    test('formats zero elapsed as 00:00', () {
      expect(makeState(elapsed: Duration.zero).formattedElapsed, '00:00');
    });

    test('formats 7 minutes 42 seconds as 07:42', () {
      expect(
        makeState(elapsed: const Duration(minutes: 7, seconds: 42)).formattedElapsed,
        '07:42',
      );
    });

    test('formats exactly 10 minutes as 10:00', () {
      expect(
        makeState(elapsed: const Duration(minutes: 10)).formattedElapsed,
        '10:00',
      );
    });

    test('formats 1 hour 5 minutes 3 seconds as 05:03 (shows mm:ss only)', () {
      // In-hunt timer only shows mm:ss — 65 minutes 3 seconds → 05:03
      expect(
        makeState(elapsed: const Duration(hours: 1, minutes: 5, seconds: 3)).formattedElapsed,
        '05:03',
      );
    });

    test('pads single-digit seconds with leading zero', () {
      expect(
        makeState(elapsed: const Duration(minutes: 1, seconds: 5)).formattedElapsed,
        '01:05',
      );
    });
  });

  // ── remainingHints (existing behaviour regression) ────────────────────────────

  group('remainingHints', () {
    test('returns 1 when hint is available and unrevealed', () {
      expect(makeState(hint: 'A hint').remainingHints, 1);
    });

    test('returns 0 when hint already revealed', () {
      expect(makeState(hint: 'A hint', hintRevealed: true).remainingHints, 0);
    });

    test('returns 0 when hintText is empty', () {
      expect(makeState(hint: '').remainingHints, 0);
    });
  });
}
