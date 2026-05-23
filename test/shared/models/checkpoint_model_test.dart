import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/shared/models/checkpoint_model.dart';

void main() {
  group('CheckpointModel', () {
    final baseJson = {
      'checkpointId': 'cp_001',
      'huntId': 'hunt_abc',
      'orderIndex': 0,
      'clueText': 'Find the oldest tree in the garden.',
      'hintText': 'Look near the eastern gate.',
      'latitude': 12.9716,
      'longitude': 77.5946,
      'type': 'clue',
      'answer': 'banyan',
      'unlockRadius': 15,
      'funFact': 'This tree is over 200 years old!',
    };

    final baseModel = CheckpointModel(
      checkpointId: 'cp_001',
      huntId: 'hunt_abc',
      orderIndex: 0,
      clueText: 'Find the oldest tree in the garden.',
      hintText: 'Look near the eastern gate.',
      latitude: 12.9716,
      longitude: 77.5946,
      type: CheckpointType.clue,
      answer: 'banyan',
      unlockRadius: 15,
      funFact: 'This tree is over 200 years old!',
    );

    // ── fromJson ──────────────────────────────────────────────────────────────

    group('fromJson', () {
      test('parses all fields correctly', () {
        final model = CheckpointModel.fromJson(baseJson);
        expect(model.checkpointId, 'cp_001');
        expect(model.huntId, 'hunt_abc');
        expect(model.orderIndex, 0);
        expect(model.clueText, 'Find the oldest tree in the garden.');
        expect(model.hintText, 'Look near the eastern gate.');
        expect(model.latitude, 12.9716);
        expect(model.longitude, 77.5946);
        expect(model.type, CheckpointType.clue);
        expect(model.answer, 'banyan');
        expect(model.unlockRadius, 15);
        expect(model.funFact, 'This tree is over 200 years old!');
      });

      test('parses photo_task type correctly', () {
        final json = {...baseJson, 'type': 'photo_task', 'answer': null};
        final model = CheckpointModel.fromJson(json);
        expect(model.type, CheckpointType.photoTask);
        expect(model.answer, isNull);
      });

      test('defaults to clue type for unknown type string', () {
        final json = {...baseJson, 'type': 'unknown_type'};
        final model = CheckpointModel.fromJson(json);
        expect(model.type, CheckpointType.clue);
      });

      test('defaults unlockRadius to 20 when missing', () {
        final json = Map<String, dynamic>.from(baseJson)..remove('unlockRadius');
        final model = CheckpointModel.fromJson(json);
        expect(model.unlockRadius, 20);
      });

      test('allows null funFact', () {
        final json = Map<String, dynamic>.from(baseJson)..remove('funFact');
        final model = CheckpointModel.fromJson(json);
        expect(model.funFact, isNull);
      });

      test('defaults all string fields to empty string when null', () {
        final model = CheckpointModel.fromJson({});
        expect(model.checkpointId, '');
        expect(model.huntId, '');
        expect(model.clueText, '');
        expect(model.hintText, '');
      });
    });

    // ── toJson ────────────────────────────────────────────────────────────────

    group('toJson', () {
      test('serialises all fields correctly', () {
        final json = baseModel.toJson();
        expect(json['checkpointId'], 'cp_001');
        expect(json['huntId'], 'hunt_abc');
        expect(json['orderIndex'], 0);
        expect(json['latitude'], 12.9716);
        expect(json['longitude'], 77.5946);
        expect(json['type'], 'clue');
        expect(json['answer'], 'banyan');
        expect(json['unlockRadius'], 15);
        expect(json['funFact'], 'This tree is over 200 years old!');
      });

      test('serialises photoTask type as "photo_task"', () {
        final model = baseModel.copyWith(type: CheckpointType.photoTask);
        expect(model.toJson()['type'], 'photo_task');
      });
    });

    // ── round-trip ────────────────────────────────────────────────────────────

    test('fromJson → toJson round-trip preserves all values', () {
      final model = CheckpointModel.fromJson(baseJson);
      final json = model.toJson();
      final model2 = CheckpointModel.fromJson(json);
      expect(model2, equals(model));
    });

    // ── copyWith ──────────────────────────────────────────────────────────────

    group('copyWith', () {
      test('returns identical model when no overrides passed', () {
        expect(baseModel.copyWith(), equals(baseModel));
      });

      test('updates clueText without affecting other fields', () {
        final updated = baseModel.copyWith(clueText: 'New clue');
        expect(updated.clueText, 'New clue');
        expect(updated.huntId, baseModel.huntId);
        expect(updated.checkpointId, baseModel.checkpointId);
      });

      test('updates unlockRadius independently', () {
        final updated = baseModel.copyWith(unlockRadius: 50);
        expect(updated.unlockRadius, 50);
        expect(updated.orderIndex, baseModel.orderIndex);
      });
    });

    // ── CheckpointType ────────────────────────────────────────────────────────

    group('CheckpointType', () {
      test('storageName returns correct values', () {
        expect(CheckpointType.clue.storageName, 'clue');
        expect(CheckpointType.photoTask.storageName, 'photo_task');
      });

      test('fromStorageName parses all known values', () {
        expect(CheckpointType.fromStorageName('clue'), CheckpointType.clue);
        expect(CheckpointType.fromStorageName('photo_task'), CheckpointType.photoTask);
      });

      test('fromStorageName falls back to clue for null and unknown', () {
        expect(CheckpointType.fromStorageName(null), CheckpointType.clue);
        expect(CheckpointType.fromStorageName('garbage'), CheckpointType.clue);
      });
    });
  });
}
