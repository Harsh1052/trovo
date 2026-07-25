import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/core/error/result.dart';
import 'package:huntermania/shared/models/checkpoint_model.dart';
import 'package:huntermania/shared/models/hunt_model.dart';
import 'package:huntermania/shared/services/offline_hunt_cache_service.dart';

void main() {
  late OfflineHuntCacheService service;
  late Directory tempDir;

  final sampleHunt = HuntModel(
    huntId: 'hunt_001',
    title: 'Garden Mystery',
    description: 'A fun treasure hunt in the botanical garden.',
    city: 'Ahmedabad',
    gardenName: 'Botanical Garden',
    difficulty: HuntDifficulty.medium,
    durationMinutes: 45,
    checkpointCount: 5,
    isFree: true,
    price: 0,
    coverImageUrl: 'https://example.com/cover.jpg',
    startLatitude: 23.0225,
    startLongitude: 72.5714,
    isActive: true,
    createdAt: DateTime(2025, 6, 1),
  );

  final sampleCheckpoints = [
    const CheckpointModel(
      checkpointId: 'cp_001',
      huntId: 'hunt_001',
      orderIndex: 0,
      clueText: 'Find the old banyan tree.',
      hintText: 'Look near the pond.',
      latitude: 23.0226,
      longitude: 72.5715,
      type: CheckpointType.clue,
      answer: 'banyan',
    ),
    const CheckpointModel(
      checkpointId: 'cp_002',
      huntId: 'hunt_001',
      orderIndex: 1,
      clueText: 'Take a photo of the fountain.',
      hintText: '',
      latitude: 23.0227,
      longitude: 72.5716,
      type: CheckpointType.photoTask,
    ),
  ];

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('offline_cache_test_');
    service = OfflineHuntCacheService.testInstance(tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ── cacheHunt & getCachedHunt ─────────────────────────────────────────────

  group('cacheHunt & getCachedHunt', () {
    test('caches and retrieves a hunt successfully', () async {
      final cacheResult = await service.cacheHunt(sampleHunt);
      expect(cacheResult.isSuccess, isTrue);

      final getResult = await service.getCachedHunt('hunt_001');
      expect(getResult.isSuccess, isTrue);

      final cached = (getResult as Success<HuntModel>).data;
      expect(cached.huntId, sampleHunt.huntId);
      expect(cached.title, sampleHunt.title);
      expect(cached.city, sampleHunt.city);
      expect(cached.checkpointCount, sampleHunt.checkpointCount);
    });

    test('returns CacheFailure when hunt is not cached', () async {
      final result = await service.getCachedHunt('non_existent');
      expect(result.isFailure, isTrue);
    });

    test('overwrites previous version on re-cache', () async {
      await service.cacheHunt(sampleHunt);
      final updated = sampleHunt.copyWith(title: 'Updated Title');
      await service.cacheHunt(updated);

      final result = await service.getCachedHunt('hunt_001');
      final cached = (result as Success<HuntModel>).data;
      expect(cached.title, 'Updated Title');
    });
  });

  // ── cacheCheckpoints & getCachedCheckpoints ───────────────────────────────

  group('cacheCheckpoints & getCachedCheckpoints', () {
    test('caches and retrieves checkpoints successfully', () async {
      final cacheResult =
          await service.cacheCheckpoints('hunt_001', sampleCheckpoints);
      expect(cacheResult.isSuccess, isTrue);

      final getResult = await service.getCachedCheckpoints('hunt_001');
      expect(getResult.isSuccess, isTrue);

      final cached = (getResult as Success<List<CheckpointModel>>).data;
      expect(cached.length, 2);
      expect(cached[0].checkpointId, 'cp_001');
      expect(cached[0].type, CheckpointType.clue);
      expect(cached[1].checkpointId, 'cp_002');
      expect(cached[1].type, CheckpointType.photoTask);
    });

    test('returns CacheFailure when checkpoints are not cached', () async {
      final result = await service.getCachedCheckpoints('non_existent');
      expect(result.isFailure, isTrue);
    });

    test('preserves checkpoint order after round-trip', () async {
      await service.cacheCheckpoints('hunt_001', sampleCheckpoints);
      final result = await service.getCachedCheckpoints('hunt_001');
      final cached = (result as Success<List<CheckpointModel>>).data;
      expect(cached[0].orderIndex, 0);
      expect(cached[1].orderIndex, 1);
    });
  });

  // ── isHuntCached ──────────────────────────────────────────────────────────

  group('isHuntCached', () {
    test('returns false when nothing is cached', () async {
      expect(await service.isHuntCached('hunt_001'), isFalse);
    });

    test('returns false when only hunt is cached (no checkpoints)', () async {
      await service.cacheHunt(sampleHunt);
      expect(await service.isHuntCached('hunt_001'), isFalse);
    });

    test('returns false when only checkpoints are cached (no hunt)', () async {
      await service.cacheCheckpoints('hunt_001', sampleCheckpoints);
      expect(await service.isHuntCached('hunt_001'), isFalse);
    });

    test('returns true when both hunt and checkpoints are cached', () async {
      await service.cacheHunt(sampleHunt);
      await service.cacheCheckpoints('hunt_001', sampleCheckpoints);
      expect(await service.isHuntCached('hunt_001'), isTrue);
    });
  });

  // ── getCachedHunts ────────────────────────────────────────────────────────

  group('getCachedHunts', () {
    test('returns empty list when no hunts are cached', () async {
      final result = await service.getCachedHunts();
      final hunts = (result as Success<List<HuntModel>>).data;
      expect(hunts, isEmpty);
    });

    test('returns all cached hunts sorted by title', () async {
      await service.cacheHunt(sampleHunt);
      final huntB = HuntModel(
        huntId: 'hunt_002',
        title: 'Ancient Ruins',
        description: 'Explore ancient ruins.',
        city: 'Vadodara',
        gardenName: 'Ruins Park',
        difficulty: HuntDifficulty.hard,
        durationMinutes: 90,
        checkpointCount: 8,
        isFree: false,
        price: 499,
        coverImageUrl: '',
        startLatitude: 22.3072,
        startLongitude: 73.1812,
        isActive: true,
        createdAt: DateTime(2025, 5, 1),
      );
      await service.cacheHunt(huntB);

      final result = await service.getCachedHunts();
      final hunts = (result as Success<List<HuntModel>>).data;
      expect(hunts.length, 2);
      // 'Ancient Ruins' < 'Garden Mystery' alphabetically
      expect(hunts[0].huntId, 'hunt_002');
      expect(hunts[1].huntId, 'hunt_001');
    });

    test('skips corrupt JSON files gracefully', () async {
      await service.cacheHunt(sampleHunt);
      // Write a corrupt file.
      final huntsDir = Directory('${tempDir.path}/hunts');
      final corrupt = File('${huntsDir.path}/corrupt.json');
      await corrupt.writeAsString('NOT_VALID_JSON{{{');

      final result = await service.getCachedHunts();
      final hunts = (result as Success<List<HuntModel>>).data;
      // Only the valid hunt should be returned.
      expect(hunts.length, 1);
      expect(hunts[0].huntId, 'hunt_001');
    });
  });

  // ── removeCachedHunt ──────────────────────────────────────────────────────

  group('removeCachedHunt', () {
    test('removes cached hunt and checkpoints for a huntId', () async {
      await service.cacheHunt(sampleHunt);
      await service.cacheCheckpoints('hunt_001', sampleCheckpoints);
      expect(await service.isHuntCached('hunt_001'), isTrue);

      final removeResult = await service.removeCachedHunt('hunt_001');
      expect(removeResult.isSuccess, isTrue);

      expect(await service.isHuntCached('hunt_001'), isFalse);
      expect((await service.getCachedHunt('hunt_001')).isFailure, isTrue);
      expect(
        (await service.getCachedCheckpoints('hunt_001')).isFailure,
        isTrue,
      );
    });

    test('succeeds even when huntId was never cached', () async {
      final result = await service.removeCachedHunt('ghost_hunt');
      expect(result.isSuccess, isTrue);
    });
  });

  // ── clearCache ────────────────────────────────────────────────────────────

  group('clearCache', () {
    test('removes all cached data', () async {
      await service.cacheHunt(sampleHunt);
      await service.cacheCheckpoints('hunt_001', sampleCheckpoints);

      final clearResult = await service.clearCache();
      expect(clearResult.isSuccess, isTrue);

      // After clearing, the hunt should no longer be cached.
      expect(await service.isHuntCached('hunt_001'), isFalse);
    });

    test('succeeds when cache is already empty', () async {
      final result = await service.clearCache();
      expect(result.isSuccess, isTrue);
    });
  });
}
