import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/shared/models/user_model.dart';

void main() {
  final now = DateTime(2025, 6, 1, 9, 0);

  final baseUser = UserModel(
    uid: 'user_abc',
    displayName: 'Jane Doe',
    email: 'jane@example.com',
    photoUrl: 'https://example.com/photo.jpg',
    completedHunts: const ['hunt_1', 'hunt_2'],
    purchasedHunts: const ['hunt_3'],
    createdAt: now,
    lastActiveAt: now,
  );

  // ── fromJson ────────────────────────────────────────────────────────────────

  group('fromJson', () {
    final json = {
      'uid': 'user_abc',
      'displayName': 'Jane Doe',
      'email': 'jane@example.com',
      'photoUrl': 'https://example.com/photo.jpg',
      'completedHunts': ['hunt_1', 'hunt_2'],
      'purchasedHunts': ['hunt_3'],
      'createdAt': now.toIso8601String(),
      'lastActiveAt': now.toIso8601String(),
    };

    test('parses all fields correctly', () {
      final model = UserModel.fromJson(json);
      expect(model.uid, 'user_abc');
      expect(model.displayName, 'Jane Doe');
      expect(model.email, 'jane@example.com');
      expect(model.photoUrl, 'https://example.com/photo.jpg');
      expect(model.completedHunts, ['hunt_1', 'hunt_2']);
      expect(model.purchasedHunts, ['hunt_3']);
    });

    test('defaults displayName to empty string when missing', () {
      final model = UserModel.fromJson({'uid': 'x'});
      expect(model.displayName, '');
    });

    test('defaults completedHunts and purchasedHunts to empty lists', () {
      final model = UserModel.fromJson({});
      expect(model.completedHunts, isEmpty);
      expect(model.purchasedHunts, isEmpty);
    });

    test('email and photoUrl are null when missing', () {
      final model = UserModel.fromJson({'uid': 'x'});
      expect(model.email, isNull);
      expect(model.photoUrl, isNull);
    });

    test('handles non-list values for completedHunts gracefully', () {
      final model = UserModel.fromJson({'completedHunts': 'not_a_list'});
      expect(model.completedHunts, isEmpty);
    });
  });

  // ── toJson round-trip ───────────────────────────────────────────────────────

  group('toJson round-trip', () {
    test('serialises and deserialises without data loss', () {
      final json = baseUser.toJson();
      final restored = UserModel.fromJson(json);
      expect(restored, equals(baseUser));
    });

    test('toJson includes uid field', () {
      final json = baseUser.toJson();
      expect(json['uid'], 'user_abc');
    });
  });

  // ── isGuest ────────────────────────────────────────────────────────────────

  group('isGuest', () {
    test('returns false when email is set', () {
      expect(baseUser.isGuest, isFalse);
    });

    test('returns true when email is null', () {
      final guest = baseUser.copyWith(email: null);
      // copyWith does not support setting null back; test via fromJson instead.
      final model = UserModel.fromJson({'uid': 'g1', 'displayName': 'Guest'});
      expect(model.isGuest, isTrue);
    });

    test('returns true when email is empty string', () {
      // Build directly to force empty email.
      final model = UserModel(
        uid: 'g2',
        displayName: 'Guest',
        email: '   ',
        createdAt: now,
        lastActiveAt: now,
      );
      expect(model.isGuest, isTrue);
    });
  });

  // ── hasPhoto ────────────────────────────────────────────────────────────────

  group('hasPhoto', () {
    test('returns true when photoUrl is set', () {
      expect(baseUser.hasPhoto, isTrue);
    });

    test('returns false when photoUrl is null', () {
      final model = baseUser.copyWith(photoUrl: null);
      // copyWith does not clear; test via direct construction.
      final noPhoto = UserModel(
        uid: 'p1',
        displayName: 'No Photo',
        createdAt: now,
        lastActiveAt: now,
      );
      expect(noPhoto.hasPhoto, isFalse);
    });

    test('returns false when photoUrl is empty string', () {
      final model = UserModel(
        uid: 'p2',
        displayName: 'Empty Photo',
        photoUrl: '',
        createdAt: now,
        lastActiveAt: now,
      );
      expect(model.hasPhoto, isFalse);
    });
  });

  // ── initials ────────────────────────────────────────────────────────────────

  group('initials', () {
    String initialsFor(String name) => UserModel(
          uid: 'x',
          displayName: name,
          createdAt: now,
          lastActiveAt: now,
        ).initials;

    test('two-word name returns two uppercase letters', () {
      expect(initialsFor('Jane Doe'), 'JD');
    });

    test('single name returns first letter uppercase', () {
      expect(initialsFor('Alice'), 'A');
    });

    test('three-word name uses first and last word', () {
      expect(initialsFor('John Michael Smith'), 'JS');
    });

    test('empty displayName returns question mark', () {
      expect(initialsFor(''), '?');
    });

    test('whitespace-only displayName returns question mark', () {
      expect(initialsFor('   '), '?');
    });

    test('lowercased name is returned as uppercase initials', () {
      expect(initialsFor('john doe'), 'JD');
    });
  });

  // ── hasCompletedHunt ────────────────────────────────────────────────────────

  group('hasCompletedHunt', () {
    test('returns true for a hunt in completedHunts', () {
      expect(baseUser.hasCompletedHunt('hunt_1'), isTrue);
    });

    test('returns false for a hunt not in completedHunts', () {
      expect(baseUser.hasCompletedHunt('hunt_99'), isFalse);
    });

    test('returns false when completedHunts is empty', () {
      final model = UserModel(
          uid: 'u', displayName: 'X', createdAt: now, lastActiveAt: now);
      expect(model.hasCompletedHunt('hunt_1'), isFalse);
    });
  });

  // ── hasPurchasedHunt ────────────────────────────────────────────────────────

  group('hasPurchasedHunt', () {
    test('returns true for a hunt in purchasedHunts', () {
      expect(baseUser.hasPurchasedHunt('hunt_3'), isTrue);
    });

    test('returns false for a hunt not in purchasedHunts', () {
      expect(baseUser.hasPurchasedHunt('hunt_1'), isFalse);
    });
  });

  // ── hasAccessTo ────────────────────────────────────────────────────────────

  group('hasAccessTo', () {
    test('returns true when hunt is in completedHunts', () {
      expect(baseUser.hasAccessTo('hunt_1'), isTrue);
    });

    test('returns true when hunt is in purchasedHunts', () {
      expect(baseUser.hasAccessTo('hunt_3'), isTrue);
    });

    test('returns false when hunt is in neither list', () {
      expect(baseUser.hasAccessTo('hunt_99'), isFalse);
    });
  });

  // ── copyWith ────────────────────────────────────────────────────────────────

  group('copyWith', () {
    test('returns equal model when no overrides passed', () {
      expect(baseUser.copyWith(), equals(baseUser));
    });

    test('updates displayName without affecting uid', () {
      final updated = baseUser.copyWith(displayName: 'New Name');
      expect(updated.displayName, 'New Name');
      expect(updated.uid, baseUser.uid);
    });

    test('updates completedHunts independently', () {
      final updated =
          baseUser.copyWith(completedHunts: ['hunt_5', 'hunt_6']);
      expect(updated.completedHunts, ['hunt_5', 'hunt_6']);
      expect(updated.purchasedHunts, baseUser.purchasedHunts);
    });

    test('preserves createdAt since it is immutable in copyWith', () {
      final updated = baseUser.copyWith(displayName: 'Changed');
      expect(updated.createdAt, baseUser.createdAt);
    });
  });
}
