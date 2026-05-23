import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/constants/app_constants.dart';
import '../../config/constants/firestore_paths.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../models/checkpoint_model.dart';
import '../models/hunt_model.dart';

// ── Abstract contract ─────────────────────────────────────────────────────────

abstract class HuntRepository {
  Future<Result<List<HuntModel>>> fetchHunts({
    String? city,
    DocumentSnapshot? lastDoc,
  });

  Future<Result<HuntModel>> fetchHunt(String huntId);

  Future<Result<List<CheckpointModel>>> fetchCheckpoints(String huntId);

  /// Returns distinct city names from all active hunts, sorted alphabetically.
  Future<Result<List<String>>> getAvailableCities();
}

// ── Firebase implementation ───────────────────────────────────────────────────

class FirebaseHuntRepository implements HuntRepository {
  FirebaseHuntRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<Result<List<HuntModel>>> fetchHunts({
    String? city,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query query = _firestore
          .collection(FirestorePaths.hunts)
          .where(FirestorePaths.fieldIsActive, isEqualTo: true)
          .orderBy(FirestorePaths.fieldCreatedAt, descending: true)
          .limit(AppConstants.huntPageSize);

      if (city != null) {
        query = query.where(FirestorePaths.fieldCity, isEqualTo: city);
      }
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return Success(snapshot.docs.map(HuntModel.fromFirestore).toList());
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      return Err(ServerFailure('Failed to fetch hunts: $e'));
    }
  }

  @override
  Future<Result<HuntModel>> fetchHunt(String huntId) async {
    try {
      final doc =
          await _firestore.doc(FirestorePaths.huntDoc(huntId)).get();
      if (!doc.exists) {
        return const Err(NotFoundFailure('Hunt not found.'));
      }
      return Success(HuntModel.fromFirestore(doc));
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      return Err(ServerFailure('Failed to fetch hunt: $e'));
    }
  }

  @override
  Future<Result<List<CheckpointModel>>> fetchCheckpoints(String huntId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.checkpointsCollection(huntId))
          .orderBy('orderIndex')
          .get();
      return Success(
          snapshot.docs.map(CheckpointModel.fromFirestore).toList());
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      return Err(ServerFailure('Failed to fetch checkpoints: $e'));
    }
  }

  /// Fetches all active hunt documents and extracts the distinct set of cities.
  ///
  /// Firestore has no native DISTINCT query, so we read up to 500 documents
  /// and deduplicate in memory — acceptable for an MVP hunt catalogue.
  @override
  Future<Result<List<String>>> getAvailableCities() async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.hunts)
          .where(FirestorePaths.fieldIsActive, isEqualTo: true)
          .limit(500)
          .get();
      final cities = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return data[FirestorePaths.fieldCity] as String? ?? '';
          })
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      return Success(cities);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      return Err(ServerFailure('Failed to fetch cities: $e'));
    }
  }
}
