import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/network/connectivity_checker.dart';
import '../../core/utils/logger.dart';
import '../models/checkpoint_model.dart';
import '../models/hunt_model.dart';
import '../services/offline_hunt_cache_service.dart';
import 'hunt_repository.dart';

/// A [HuntRepository] decorator that adds offline caching.
///
/// Strategy:
/// - **Online reads:** Fetch from [_remote], then write-through to the local
///   [_cache] so subsequent offline reads are fresh.
/// - **Offline reads:** When [ConnectivityChecker] reports no connectivity, or
///   when the remote fetch fails with a [NetworkFailure], serve data from the
///   local [_cache] instead.
/// - **Write-through, not write-back:** We never queue mutations. The app is
///   read-heavy (browse hunts, follow checkpoints), and mutations flow through
///   [ProgressRepository] which has its own Firestore sync.
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
      // Write-through: cache each hunt on successful fetch.
      if (result.isSuccess) {
        final hunts = (result as Success<List<HuntModel>>).data;
        for (final hunt in hunts) {
          await _cache.cacheHunt(hunt);
        }
      }
      return result;
    }

    // Offline fallback — serve all cached hunts, optionally filtered by city.
    AppLogger.i('Offline: serving cached hunts', tag: 'CachedHuntRepo');
    final cached = await _cache.getCachedHunts();
    return cached.fold(
      onSuccess: (hunts) {
        final filtered = city != null
            ? hunts.where((h) => h.city == city).toList()
            : hunts;
        return Success(filtered);
      },
      onErr: (failure) => Err(failure),
    );
  }

  // ── fetchHunt ───────────────────────────────────────────────────────────────

  @override
  Future<Result<HuntModel>> fetchHunt(String huntId) async {
    if (await _connectivity.isConnected) {
      final result = await _remote.fetchHunt(huntId);
      // Write-through.
      if (result.isSuccess) {
        await _cache.cacheHunt((result as Success<HuntModel>).data);
      }
      return result;
    }

    AppLogger.i('Offline: serving cached hunt $huntId',
        tag: 'CachedHuntRepo');
    return _cache.getCachedHunt(huntId);
  }

  // ── fetchCheckpoints ────────────────────────────────────────────────────────

  @override
  Future<Result<List<CheckpointModel>>> fetchCheckpoints(String huntId) async {
    if (await _connectivity.isConnected) {
      final result = await _remote.fetchCheckpoints(huntId);
      // Write-through.
      if (result.isSuccess) {
        final checkpoints =
            (result as Success<List<CheckpointModel>>).data;
        await _cache.cacheCheckpoints(huntId, checkpoints);
      }
      return result;
    }

    AppLogger.i('Offline: serving cached checkpoints for $huntId',
        tag: 'CachedHuntRepo');
    return _cache.getCachedCheckpoints(huntId);
  }

  // ── getAvailableCities ──────────────────────────────────────────────────────

  @override
  Future<Result<List<String>>> getAvailableCities() async {
    if (await _connectivity.isConnected) {
      return _remote.getAvailableCities();
    }

    // Derive cities from cached hunts.
    AppLogger.i('Offline: deriving cities from cached hunts',
        tag: 'CachedHuntRepo');
    final cached = await _cache.getCachedHunts();
    return cached.fold(
      onSuccess: (hunts) {
        final cities = hunts
            .map((h) => h.city)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        return Success(cities);
      },
      onErr: (failure) => Err(failure),
    );
  }
}
