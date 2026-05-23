import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/shared/models/hunt_model.dart';

void main() {
  group('HuntModel', () {
    final baseJson = {
      'huntId': 'hunt_001',
      'title': 'Secret Garden Mystery',
      'description': 'Uncover the secrets hidden within the ancient garden.',
      'city': 'Bengaluru',
      'gardenName': 'Lalbagh Botanical Garden',
      'difficulty': 'medium',
      'durationMinutes': 90,
      'checkpointCount': 8,
      'isFree': false,
      'price': 199,
      'coverImageUrl': 'https://example.com/cover.jpg',
      'startLatitude': 12.9507,
      'startLongitude': 77.5848,
      'isActive': true,
      'createdAt': '2025-04-05T10:00:00.000',
    };

    final baseModel = HuntModel(
      huntId: 'hunt_001',
      title: 'Secret Garden Mystery',
      description: 'Uncover the secrets hidden within the ancient garden.',
      city: 'Bengaluru',
      gardenName: 'Lalbagh Botanical Garden',
      difficulty: HuntDifficulty.medium,
      durationMinutes: 90,
      checkpointCount: 8,
      isFree: false,
      price: 199,
      coverImageUrl: 'https://example.com/cover.jpg',
      startLatitude: 12.9507,
      startLongitude: 77.5848,
      isActive: true,
      createdAt: DateTime(2025, 4, 5, 10),
    );

    // ── fromJson ──────────────────────────────────────────────────────────────

    group('fromJson', () {
      test('parses all fields correctly', () {
        final model = HuntModel.fromJson(baseJson);
        expect(model.huntId, 'hunt_001');
        expect(model.title, 'Secret Garden Mystery');
        expect(model.city, 'Bengaluru');
        expect(model.gardenName, 'Lalbagh Botanical Garden');
        expect(model.difficulty, HuntDifficulty.medium);
        expect(model.durationMinutes, 90);
        expect(model.checkpointCount, 8);
        expect(model.isFree, false);
        expect(model.price, 199);
        expect(model.coverImageUrl, 'https://example.com/cover.jpg');
        expect(model.startLatitude, 12.9507);
        expect(model.startLongitude, 77.5848);
        expect(model.isActive, true);
      });

      test('parses easy difficulty', () {
        final json = {...baseJson, 'difficulty': 'easy'};
        expect(HuntModel.fromJson(json).difficulty, HuntDifficulty.easy);
      });

      test('parses hard difficulty', () {
        final json = {...baseJson, 'difficulty': 'hard'};
        expect(HuntModel.fromJson(json).difficulty, HuntDifficulty.hard);
      });

      test('defaults to medium for unknown difficulty string', () {
        final json = {...baseJson, 'difficulty': 'super_hard'};
        expect(HuntModel.fromJson(json).difficulty, HuntDifficulty.medium);
      });

      test('defaults isFree to true when missing', () {
        final json = Map<String, dynamic>.from(baseJson)..remove('isFree');
        expect(HuntModel.fromJson(json).isFree, true);
      });

      test('defaults price to 0 when missing', () {
        final json = Map<String, dynamic>.from(baseJson)..remove('price');
        expect(HuntModel.fromJson(json).price, 0);
      });

      test('defaults durationMinutes to 60 when missing', () {
        final json = Map<String, dynamic>.from(baseJson)..remove('durationMinutes');
        expect(HuntModel.fromJson(json).durationMinutes, 60);
      });

      test('defaults isActive to false when missing', () {
        final json = Map<String, dynamic>.from(baseJson)..remove('isActive');
        expect(HuntModel.fromJson(json).isActive, false);
      });

      test('parses createdAt from ISO-8601 string', () {
        final model = HuntModel.fromJson(baseJson);
        expect(model.createdAt, DateTime(2025, 4, 5, 10));
      });

      test('defaults all string fields to empty when null or missing', () {
        final model = HuntModel.fromJson({});
        expect(model.huntId, '');
        expect(model.title, '');
        expect(model.description, '');
        expect(model.city, '');
        expect(model.gardenName, '');
        expect(model.coverImageUrl, '');
      });
    });

    // ── toJson ────────────────────────────────────────────────────────────────

    group('toJson', () {
      test('serialises all fields correctly', () {
        final json = baseModel.toJson();
        expect(json['huntId'], 'hunt_001');
        expect(json['title'], 'Secret Garden Mystery');
        expect(json['difficulty'], 'medium');
        expect(json['durationMinutes'], 90);
        expect(json['checkpointCount'], 8);
        expect(json['isFree'], false);
        expect(json['price'], 199);
        expect(json['startLatitude'], 12.9507);
        expect(json['startLongitude'], 77.5848);
        expect(json['isActive'], true);
        expect(json['createdAt'], isA<String>());
      });

      test('serialises HuntDifficulty as lowercase name', () {
        for (final diff in HuntDifficulty.values) {
          final json = baseModel.copyWith(difficulty: diff).toJson();
          expect(json['difficulty'], diff.name);
        }
      });
    });

    // ── round-trip ────────────────────────────────────────────────────────────

    test('fromJson → toJson round-trip preserves all values', () {
      final model = HuntModel.fromJson(baseJson);
      final json = model.toJson();
      final model2 = HuntModel.fromJson(json);
      expect(model2, equals(model));
    });

    // ── copyWith ──────────────────────────────────────────────────────────────

    group('copyWith', () {
      test('returns equal model when no overrides passed', () {
        expect(baseModel.copyWith(), equals(baseModel));
      });

      test('updates title without affecting other fields', () {
        final updated = baseModel.copyWith(title: 'New Title');
        expect(updated.title, 'New Title');
        expect(updated.huntId, baseModel.huntId);
        expect(updated.city, baseModel.city);
      });

      test('updates difficulty independently', () {
        final updated = baseModel.copyWith(difficulty: HuntDifficulty.hard);
        expect(updated.difficulty, HuntDifficulty.hard);
        expect(updated.durationMinutes, baseModel.durationMinutes);
      });

      test('preserves createdAt since it is immutable in copyWith', () {
        final updated = baseModel.copyWith(title: 'Changed');
        expect(updated.createdAt, baseModel.createdAt);
      });
    });

    // ── HuntDifficulty ────────────────────────────────────────────────────────

    group('HuntDifficulty', () {
      test('has exactly 3 values', () {
        expect(HuntDifficulty.values.length, 3);
      });

      test('name matches lowercase string for all values', () {
        expect(HuntDifficulty.easy.name, 'easy');
        expect(HuntDifficulty.medium.name, 'medium');
        expect(HuntDifficulty.hard.name, 'hard');
      });
    });
  });
}
