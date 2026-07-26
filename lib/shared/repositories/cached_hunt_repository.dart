import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/network/connectivity_checker.dart';
import '../../core/utils/logger.dart';
import '../models/checkpoint_model.dart';
import '../models/hunt_model.dart';
import '../services/offline_hunt_cache_service.dart';
import 'hunt_repository.dart';

import '../data/seed_hunts.dart';

/// A [HuntRepository] decorator that adds offline caching and seed fallbacks.
class CachedHuntRepository implements HuntRepository {
  CachedHuntRepository({
    required HuntRepository remote,
    required OfflineHuntCacheService cache,
    required ConnectivityChecker connectivity,
  })  : _remote = remote,
        _cache = cache,
        _connectivity = connectivity;

  final HuntRepository _remote;
  final OfflineHuntCacheService _cache;
  final ConnectivityChecker _connectivity;

  // ── fetchHunts ──────────────────────────────────────────────────────────────

  @override
  Future<Result<List<HuntModel>>> fetchHunts({
    String? city,
    DocumentSnapshot? lastDoc,
  }) async {
    if (await _connectivity.isConnected) {
      final result = await _remote.fetchHunts(city: city, lastDoc: lastDoc);
      if (result.isSuccess) {
        final hunts = (result as Success<List<HuntModel>>).data;
        if (hunts.isNotEmpty) {
          for (final hunt in hunts) {
            await _cache.cacheHunt(hunt);
          }
          return result;
        }
      }
    }

    // Serving cached or fallback seed hunts
    AppLogger.i('Serving cached/seed hunts', tag: 'CachedHuntRepo');
    final cached = await _cache.getCachedHunts();
    final huntsList = cached.dataOrNull ?? const <HuntModel>[];
    
    final combined = <HuntModel>{...huntsList, ...SeedHunts.hunts}.toList();
    for (final h in combined) {
      await _cache.cacheHunt(h);
    }

    final filtered = city != null && city.isNotEmpty
        ? combined.where((h) => h.city == city).toList()
        : combined;
    return Success(filtered);
  }

  // ── fetchHunt ───────────────────────────────────────────────────────────────

  @override
  Future<Result<HuntModel>> fetchHunt(String huntId) async {
    if (await _connectivity.isConnected) {
      final result = await _remote.fetchHunt(huntId);
      if (result.isSuccess) {
        await _cache.cacheHunt((result as Success<HuntModel>).data);
        return result;
      }
    }

    AppLogger.i('Serving cached/seed hunt $huntId', tag: 'CachedHuntRepo');
    final cached = await _cache.getCachedHunt(huntId);
    if (cached.isSuccess) return cached;

    final seedMatch = SeedHunts.hunts.where((h) => h.huntId == huntId).firstOrNull;
    if (seedMatch != null) {
      await _cache.cacheHunt(seedMatch);
      return Success(seedMatch);
    }
    return const Err(NotFoundFailure('Hunt not found.'));
  }

  // ── fetchCheckpoints ────────────────────────────────────────────────────────

  @override
  Future<Result<List<CheckpointModel>>> fetchCheckpoints(String huntId) async {
    if (await _connectivity.isConnected) {
      final result = await _remote.fetchCheckpoints(huntId);
      if (result.isSuccess) {
        final checkpoints = (result as Success<List<CheckpointModel>>).data;
        if (checkpoints.isNotEmpty) {
          await _cache.cacheCheckpoints(huntId, checkpoints);
          return result;
        }
      }
    }

    AppLogger.i('Serving cached/seed checkpoints for $huntId', tag: 'CachedHuntRepo');
    final seedCheckpoints = SeedHunts.checkpoints[huntId];
    final cached = await _cache.getCachedCheckpoints(huntId);
    if (cached case Success(:final data) when data.isNotEmpty) {
      final cachedList = data;
      if (seedCheckpoints != null && seedCheckpoints.isNotEmpty) {
        final needsRefresh = cachedList.length != seedCheckpoints.length ||
            cachedList.any((c) => c.isClue && (c.answer == null || c.answer!.isEmpty));
        if (needsRefresh) {
          AppLogger.i('Refreshing stale cached checkpoints with seed data for $huntId', tag: 'CachedHuntRepo');
          await _cache.cacheCheckpoints(huntId, seedCheckpoints);
          return Success(seedCheckpoints);
        }
      }
      return cached;
    }

    if (seedCheckpoints != null && seedCheckpoints.isNotEmpty) {
      await _cache.cacheCheckpoints(huntId, seedCheckpoints);
      return Success(seedCheckpoints);
    }
    return const Success([]);
  }

  // ── getAvailableCities ──────────────────────────────────────────────────────

  @override
  Future<Result<List<String>>> getAvailableCities() async {
    if (await _connectivity.isConnected) {
      final result = await _remote.getAvailableCities();
      if (result.isSuccess && (result as Success<List<String>>).data.isNotEmpty) {
        return result;
      }
    }

    AppLogger.i('Deriving cities from cached/seed hunts', tag: 'CachedHuntRepo');
    final huntsResult = await fetchHunts();
    final hunts = huntsResult.dataOrNull ?? SeedHunts.hunts;
    final cities = hunts
        .map((h) => h.city)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return Success(cities);
  }
}
