import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/features/home/bloc/home_state.dart';
import 'package:huntermania/shared/models/hunt_model.dart';

void main() {
  HuntModel makeHunt({required String id, required bool isFree, String city = 'Mumbai'}) =>
      HuntModel(
        huntId: id,
        title: 'Hunt $id',
        description: 'Desc',
        city: city,
        gardenName: 'Test Garden',
        isFree: isFree,
        difficulty: HuntDifficulty.easy,
        durationMinutes: 45,
        checkpointCount: 4,
        price: isFree ? 0 : 499,
        coverImageUrl: '',
        startLatitude: 12.9716,
        startLongitude: 77.5946,
        createdAt: DateTime(2025),
        isActive: true,
      );

  final freeHunt = makeHunt(id: 'h1', isFree: true);
  final paidHunt = makeHunt(id: 'h2', isFree: false);
  final paidHunt2 = makeHunt(id: 'h3', isFree: false, city: 'Pune');

  HomeLoaded makeLoaded({
    List<HuntModel>? hunts,
    HuntModel? featuredHunt,
    String selectedCity = '',
    List<String> cities = const ['Mumbai', 'Pune'],
  }) =>
      HomeLoaded(
        hunts: hunts ?? [freeHunt, paidHunt],
        featuredHunt: featuredHunt ?? freeHunt,
        selectedCity: selectedCity,
        availableCities: cities,
      );

  // ── freeHunts / paidHunts ──────────────────────────────────────────────────

  group('freeHunts', () {
    test('returns only free hunts', () {
      final state = makeLoaded(hunts: [freeHunt, paidHunt]);
      expect(state.freeHunts, [freeHunt]);
    });

    test('returns empty when no free hunts', () {
      final state = makeLoaded(hunts: [paidHunt, paidHunt2]);
      expect(state.freeHunts, isEmpty);
    });
  });

  group('paidHunts', () {
    test('returns only paid hunts', () {
      final state = makeLoaded(hunts: [freeHunt, paidHunt]);
      expect(state.paidHunts, [paidHunt]);
    });

    test('returns empty when all hunts are free', () {
      final state = makeLoaded(hunts: [freeHunt]);
      expect(state.paidHunts, isEmpty);
    });
  });

  // ── cityLabel ──────────────────────────────────────────────────────────────

  group('cityLabel', () {
    test('returns "All Cities" when selectedCity is empty', () {
      expect(makeLoaded(selectedCity: '').cityLabel, 'All Cities');
    });

    test('returns the city name when a city is selected', () {
      expect(makeLoaded(selectedCity: 'Mumbai').cityLabel, 'Mumbai');
    });
  });

  // ── hasHunts ───────────────────────────────────────────────────────────────

  group('hasHunts', () {
    test('returns true when hunts list is non-empty', () {
      expect(makeLoaded(hunts: [freeHunt]).hasHunts, isTrue);
    });

    test('returns false when hunts list is empty', () {
      expect(makeLoaded(hunts: []).hasHunts, isFalse);
    });
  });

  // ── hasFeaturedHunt ────────────────────────────────────────────────────────

  group('hasFeaturedHunt', () {
    test('returns true when featuredHunt is not null', () {
      expect(makeLoaded(featuredHunt: freeHunt).hasFeaturedHunt, isTrue);
    });

    test('returns false when featuredHunt is null', () {
      final state = HomeLoaded(
        hunts: [paidHunt],
        featuredHunt: null,
        selectedCity: '',
        availableCities: const ['Mumbai'],
      );
      expect(state.hasFeaturedHunt, isFalse);
    });
  });

  // ── hasMultipleCities ──────────────────────────────────────────────────────

  group('hasMultipleCities', () {
    test('returns true when there are 2+ cities', () {
      expect(makeLoaded(cities: ['Mumbai', 'Pune']).hasMultipleCities, isTrue);
    });

    test('returns false when there is only one city', () {
      expect(makeLoaded(cities: ['Mumbai']).hasMultipleCities, isFalse);
    });

    test('returns false when cities list is empty', () {
      expect(makeLoaded(cities: []).hasMultipleCities, isFalse);
    });
  });

  // ── totalCount ─────────────────────────────────────────────────────────────

  group('totalCount', () {
    test('returns the number of hunts in the list', () {
      expect(makeLoaded(hunts: [freeHunt, paidHunt, paidHunt2]).totalCount, 3);
    });

    test('returns 0 for an empty hunt list', () {
      expect(makeLoaded(hunts: []).totalCount, 0);
    });
  });

  // ── copyWith ───────────────────────────────────────────────────────────────

  group('copyWith', () {
    test('returns equal state when no overrides provided', () {
      final state = makeLoaded();
      expect(state.copyWith(), equals(state));
    });

    test('updates selectedCity without changing hunts', () {
      final state = makeLoaded(selectedCity: 'Mumbai');
      final updated = state.copyWith(selectedCity: 'Pune');
      expect(updated.selectedCity, 'Pune');
      expect(updated.hunts, state.hunts);
    });

    test('updates hunts independently', () {
      final state = makeLoaded(hunts: [freeHunt]);
      final updated = state.copyWith(hunts: [freeHunt, paidHunt]);
      expect(updated.hunts.length, 2);
      expect(updated.selectedCity, state.selectedCity);
    });
  });
}
