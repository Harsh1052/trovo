import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/logger.dart';
import '../models/checkpoint_model.dart';
import '../models/hunt_model.dart';

/// Manages local JSON persistence for offline hunt data and checkpoints.
///
/// Hunt data is stored as individual JSON files under the app's documents
/// directory:
/// ```
/// <documents>/offline_hunts/
///   ├── hunts/
///   │   ├── <huntId>.json
///   │   └── ...
///   └── checkpoints/
///       ├── <huntId>.json   (list of checkpoints for the hunt)
///       └── ...
/// ```
class OfflineHuntCacheService {
  OfflineHuntCacheService();

  /// Test-only constructor that uses a pre-resolved directory instead of
  /// [getApplicationDocumentsDirectory]. Production code should use the
  /// default constructor.
  OfflineHuntCacheService.testInstance(Directory cacheRoot)
      : _cacheRoot = cacheRoot;
  static const _rootDir = 'offline_hunts';
  static const _huntsDir = 'hunts';
  static const _checkpointsDir = 'checkpoints';

  Directory? _cacheRoot;

  /// Lazily resolves the root cache directory.
  Future<Directory> get _root async {
    if (_cacheRoot != null) return _cacheRoot!;
    final docs = await getApplicationDocumentsDirectory();
    _cacheRoot = Directory('${docs.path}/$_rootDir');
    if (!_cacheRoot!.existsSync()) {
      await _cacheRoot!.create(recursive: true);
    }
    return _cacheRoot!;
  }

  Future<Directory> _huntsDirectory() async {
    final root = await _root;
    final dir = Directory('${root.path}/$_huntsDir');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _checkpointsDirectory() async {
    final root = await _root;
    final dir = Directory('${root.path}/$_checkpointsDir');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  // ── Cache a hunt ──────────────────────────────────────────────────────────

  /// Writes [hunt] to the local cache, overwriting any previous version.
  Future<Result<void>> cacheHunt(HuntModel hunt) async {
    try {
      final dir = await _huntsDirectory();
      final file = File('${dir.path}/${hunt.huntId}.json');
      await file.writeAsString(jsonEncode(hunt.toJson()));
      return const Success(null);
    } catch (e) {
      AppLogger.w('Failed to cache hunt ${hunt.huntId}: $e');
      return Err(CacheFailure('Failed to cache hunt: $e'));
    }
  }

  // ── Retrieve a cached hunt ────────────────────────────────────────────────

  /// Returns the cached [HuntModel] for [huntId], or a [CacheFailure] if the
  /// hunt is not in the local cache.
  Future<Result<HuntModel>> getCachedHunt(String huntId) async {
    try {
      final dir = await _huntsDirectory();
      final file = File('${dir.path}/$huntId.json');
      if (!file.existsSync()) {
        return const Err(CacheFailure('Hunt not cached.'));
      }
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return Success(HuntModel.fromJson(json));
    } catch (e) {
      AppLogger.w('Failed to read cached hunt $huntId: $e');
      return Err(CacheFailure('Failed to read cached hunt: $e'));
    }
  }

  // ── Cache checkpoints ─────────────────────────────────────────────────────

  /// Writes [checkpoints] for [huntId] to the local cache.
  Future<Result<void>> cacheCheckpoints(
    String huntId,
    List<CheckpointModel> checkpoints,
  ) async {
    try {
      final dir = await _checkpointsDirectory();
      final file = File('${dir.path}/$huntId.json');
      final jsonList = checkpoints.map((c) => c.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
      return const Success(null);
    } catch (e) {
      AppLogger.w('Failed to cache checkpoints for $huntId: $e');
      return Err(CacheFailure('Failed to cache checkpoints: $e'));
    }
  }

  // ── Retrieve cached checkpoints ───────────────────────────────────────────

  /// Returns the cached checkpoints for [huntId], or a [CacheFailure] if
  /// they are not in the local cache.
  Future<Result<List<CheckpointModel>>> getCachedCheckpoints(
    String huntId,
  ) async {
    try {
      final dir = await _checkpointsDirectory();
      final file = File('${dir.path}/$huntId.json');
      if (!file.existsSync()) {
        return const Err(CacheFailure('Checkpoints not cached.'));
      }
      final jsonList = jsonDecode(await file.readAsString()) as List<dynamic>;
      final checkpoints = jsonList
          .map((e) => CheckpointModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(checkpoints);
    } catch (e) {
      AppLogger.w('Failed to read cached checkpoints for $huntId: $e');
      return Err(CacheFailure('Failed to read cached checkpoints: $e'));
    }
  }

  // ── Query ─────────────────────────────────────────────────────────────────

  /// Returns true if the hunt and its checkpoints are both cached locally.
  Future<bool> isHuntCached(String huntId) async {
    final huntsDir = await _huntsDirectory();
    final checkpointsDir = await _checkpointsDirectory();
    final huntFile = File('${huntsDir.path}/$huntId.json');
    final checkpointsFile = File('${checkpointsDir.path}/$huntId.json');
    return huntFile.existsSync() && checkpointsFile.existsSync();
  }

  /// Returns all locally cached [HuntModel]s, sorted by title.
  Future<Result<List<HuntModel>>> getCachedHunts() async {
    try {
      final dir = await _huntsDirectory();
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'));

      final hunts = <HuntModel>[];
      for (final file in files) {
        try {
          final json =
              jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          hunts.add(HuntModel.fromJson(json));
        } catch (_) {
          // Skip corrupt files silently.
        }
      }

      hunts.sort((a, b) => a.title.compareTo(b.title));
      return Success(hunts);
    } catch (e) {
      AppLogger.w('Failed to list cached hunts: $e');
      return Err(CacheFailure('Failed to list cached hunts: $e'));
    }
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  /// Removes all cached hunt and checkpoint data.
  Future<Result<void>> clearCache() async {
    try {
      final root = await _root;
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
      return const Success(null);
    } catch (e) {
      AppLogger.w('Failed to clear cache: $e');
      return Err(CacheFailure('Failed to clear cache: $e'));
    }
  }

  /// Removes the cached data for a single [huntId].
  Future<Result<void>> removeCachedHunt(String huntId) async {
    try {
      final huntsDir = await _huntsDirectory();
      final checkpointsDir = await _checkpointsDirectory();

      final huntFile = File('${huntsDir.path}/$huntId.json');
      final checkpointsFile = File('${checkpointsDir.path}/$huntId.json');

      if (huntFile.existsSync()) await huntFile.delete();
      if (checkpointsFile.existsSync()) await checkpointsFile.delete();

      return const Success(null);
    } catch (e) {
      AppLogger.w('Failed to remove cached hunt $huntId: $e');
      return Err(CacheFailure('Failed to remove cached hunt: $e'));
    }
  }
}
