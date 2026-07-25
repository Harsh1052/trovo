import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/shared/models/hunt_progress_model.dart';

void main() {
  final now = DateTime(2025, 5, 1, 10, 0);
  final completed = DateTime(2025, 5, 1, 11, 30); // 90 min later

  final baseProgress = HuntProgressModel(
    documentId: 'user1_hunt1',
    userId: 'user1',
    huntId: 'hunt1',
    status: HuntStatus.inProgress,
    currentCheckpointIndex: 2,
    hintsUsed: 1,
    startedAt: now,
    checkpointTimestamps: {
      'cp_0': now.add(const Duration(minutes: 10)),
      'cp_1': now.add(const Duration(minutes: 25)),
    },
  );

  // ── HuntStatus ─────────────────────────────────────────────────────────────

  group('HuntStatus', () {
    group('storageName', () {
      test('inProgress → in_progress', () {
        expect(HuntStatus.inProgress.storageName, 'in_progress');
      });
      test('completed → completed', () {
        expect(HuntStatus.completed.storageName, 'completed');
      });
      test('abandoned → abandoned', () {
        expect(HuntStatus.abandoned.storageName, 'abandoned');
      });
    });

    group('fromStorageName', () {
      test('parses completed', () {
        expect(HuntStatus.fromStorageName('completed'), HuntStatus.completed);
      });
      test('parses abandoned', () {
        expect(HuntStatus.fromStorageName('abandoned'), HuntStatus.abandoned);
      });
      test('defaults unknown values to inProgress', () {
        expect(HuntStatus.fromStorageName('unknown'), HuntStatus.inProgress);
      });
      test('defaults null to inProgress', () {
        expect(HuntStatus.fromStorageName(null), HuntStatus.inProgress);
      });
    });
  });

  // ── fromJson / toJson ──────────────────────────────────────────────────────

  group('fromJson', () {
    final json = {
      'documentId': 'user1_hunt1',
      'userId': 'user1',
      'huntId': 'hunt1',
      'status': 'in_progress',
      'currentCheckpointIndex': 2,
      'hintsUsed': 1,
      'startedAt': now.toIso8601String(),
      'completedAt': null,
      'checkpointTimestamps': {
        'cp_0': now.add(const Duration(minutes: 10)).toIso8601String(),
        'cp_1': now.add(const Duration(minutes: 25)).toIso8601String(),
      },
    };

    test('parses all fields correctly', () {
      final model = HuntProgressModel.fromJson(json);
      expect(model.documentId, 'user1_hunt1');
      expect(model.userId, 'user1');
      expect(model.huntId, 'hunt1');
      expect(model.status, HuntStatus.inProgress);
      expect(model.currentCheckpointIndex, 2);
      expect(model.hintsUsed, 1);
      expect(model.completedAt, isNull);
      expect(model.checkpointTimestamps.length, 2);
    });

    test('defaults empty json gracefully', () {
      final model = HuntProgressModel.fromJson({});
      expect(model.documentId, '');
      expect(model.hintsUsed, 0);
      expect(model.status, HuntStatus.inProgress);
      expect(model.checkpointTimestamps, isEmpty);
    });
  });

  group('toJson round-trip', () {
    test('serialises and deserialises without data loss', () {
      final json = baseProgress.toJson();
      final restored = HuntProgressModel.fromJson(json);
      expect(restored, equals(baseProgress));
    });
  });

  // ── isComplete / isActive ──────────────────────────────────────────────────

  group('isComplete / isActive', () {
    test('inProgress: isActive true, isComplete false', () {
      expect(baseProgress.isActive, isTrue);
      expect(baseProgress.isComplete, isFalse);
    });

    test('completed: isActive false, isComplete true', () {
      final model = baseProgress.copyWith(status: HuntStatus.completed);
      expect(model.isActive, isFalse);
      expect(model.isComplete, isTrue);
    });

    test('abandoned: both false', () {
      final model = baseProgress.copyWith(status: HuntStatus.abandoned);
      expect(model.isActive, isFalse);
      expect(model.isComplete, isFalse);
    });
  });

  // ── elapsedDuration ───────────────────────────────────────────────────────

  group('elapsedDuration', () {
    test('returns difference from startedAt to completedAt when finished', () {
      final model = baseProgress.copyWith(
        status: HuntStatus.completed,
        completedAt: completed,
      );
      expect(model.elapsedDuration, const Duration(minutes: 90));
    });

    test('returns time from startedAt to now when still in progress', () {
      // Exact value is indeterminate (depends on clock); just verify it is positive.
      expect(baseProgress.elapsedDuration.inSeconds, greaterThanOrEqualTo(0));
    });
  });

  // ── scorePercentage ───────────────────────────────────────────────────────

  group('scorePercentage', () {
    test('returns 0.0 when totalCheckpoints is 0', () {
      expect(baseProgress.scorePercentage(0), 0.0);
    });

    test('returns 0.0 when no checkpoints are completed', () {
      final empty = baseProgress.copyWith(checkpointTimestamps: {});
      expect(empty.scorePercentage(5), 0.0);
    });

    test('returns correct fraction: 2 of 5 = 0.4', () {
      expect(baseProgress.scorePercentage(5), closeTo(0.4, 0.001));
    });

    test('clamps to 1.0 when completed checkpoints exceed total', () {
      expect(baseProgress.scorePercentage(1), 1.0);
    });

    test('returns 1.0 for a fully completed hunt', () {
      final full = baseProgress.copyWith(
        status: HuntStatus.completed,
        checkpointTimestamps: {
          'cp_0': now,
          'cp_1': now,
          'cp_2': now,
        },
      );
      expect(full.scorePercentage(3), closeTo(1.0, 0.001));
    });
  });

  // ── completedCheckpointIds ────────────────────────────────────────────────

  group('completedCheckpointIds', () {
    test('returns list of keys from checkpointTimestamps', () {
      final ids = baseProgress.completedCheckpointIds;
      expect(ids, containsAll(['cp_0', 'cp_1']));
      expect(ids.length, 2);
    });

    test('returns empty list when no checkpoints completed', () {
      final empty = baseProgress.copyWith(checkpointTimestamps: {});
      expect(empty.completedCheckpointIds, isEmpty);
    });
  });

  // ── copyWith ─────────────────────────────────────────────────────────────

  group('copyWith', () {
    test('returns equal model when no overrides passed', () {
      expect(baseProgress.copyWith(), equals(baseProgress));
    });

    test('updates hintsUsed without changing other fields', () {
      final updated = baseProgress.copyWith(hintsUsed: 3);
      expect(updated.hintsUsed, 3);
      expect(updated.userId, baseProgress.userId);
      expect(updated.huntId, baseProgress.huntId);
    });

    test('updates status independently', () {
      final updated = baseProgress.copyWith(status: HuntStatus.abandoned);
      expect(updated.status, HuntStatus.abandoned);
      expect(updated.currentCheckpointIndex, baseProgress.currentCheckpointIndex);
    });
  });
}
