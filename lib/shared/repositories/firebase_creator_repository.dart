import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/constants/firestore_paths.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/gps_utils.dart';
import '../../core/utils/logger.dart';
import '../models/checkpoint_model.dart';
import '../models/hunt_model.dart';
import 'creator_repository.dart';

/// Concrete Firestore implementation of [CreatorRepository].
///
/// Ensures loophole-proof data integrity via atomic batch writes, GPS distance checks,
/// and unique 6-character private access codes.
class FirebaseCreatorRepository implements CreatorRepository {
  FirebaseCreatorRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;
  static const _tag = 'FirebaseCreatorRepository';

  CollectionReference<Map<String, dynamic>> get _huntsCollection =>
      _firestore.collection(FirestorePaths.hunts);

  @override
  Future<Result<HuntModel>> createHunt({
    required HuntModel hunt,
    required List<CheckpointModel> checkpoints,
  }) async {
    try {
      // ── 1. Validation Checks ────────────────────────────────────────────────
      if (checkpoints.length < 2) {
        return const Err(
          ServerFailure('A hunt must have at least 2 checkpoints.'),
        );
      }
      if (checkpoints.length > 10) {
        return const Err(
          ServerFailure('UGC hunts are capped at 10 checkpoints max.'),
        );
      }

      // ── 2. GPS Geometry Distance Guard (>= 30m apart) ──────────────────────
      for (var i = 0; i < checkpoints.length; i++) {
        for (var j = i + 1; j < checkpoints.length; j++) {
          final dist = GpsUtils.distanceInMetres(
            checkpoints[i].latitude,
            checkpoints[i].longitude,
            checkpoints[j].latitude,
            checkpoints[j].longitude,
          );
          if (dist < 30.0) {
            return Err(
              ServerFailure(
                'Checkpoints #${i + 1} and #${j + 1} are only ${dist.toInt()}m apart. '
                'Checkpoints must be at least 30 meters apart to prevent GPS trigger overlap!',
              ),
            );
          }
        }
      }

      // ── 3. Access Code Generation (if Private) ──────────────────────────────
      String? accessCode;
      if (hunt.isPrivate) {
        accessCode = await _generateUniqueAccessCode();
      }

      final docRef = _huntsCollection.doc();
      final now = DateTime.now();

      final publishedHunt = hunt.copyWith(
        huntId: docRef.id,
        checkpointCount: checkpoints.length,
        startLatitude: checkpoints.first.latitude,
        startLongitude: checkpoints.first.longitude,
        isActive: true,
        accessCode: accessCode,
        createdAt: now,
      );

      // ── 4. Atomic Firestore Batch Write ─────────────────────────────────────
      final batch = _firestore.batch();

      // Write hunt metadata document
      batch.set(docRef, publishedHunt.toFirestore());

      // Write checkpoint sub-collection documents
      final cpCollectionRef =
          _firestore.collection(FirestorePaths.checkpointsCollection(docRef.id));

      for (var i = 0; i < checkpoints.length; i++) {
        final cp = checkpoints[i];
        final cpDocRef = cpCollectionRef.doc();
        final finalCp = cp.copyWith(
          checkpointId: cpDocRef.id,
          huntId: docRef.id,
          orderIndex: i,
        );
        batch.set(cpDocRef, finalCp.toFirestore());
      }

      await batch.commit();

      AppLogger.i(
        'UGC Hunt created: ${docRef.id} (Private code: $accessCode)',
        tag: _tag,
      );

      return Success(publishedHunt);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to create UGC hunt', tag: _tag, error: e);
      return Err(ServerFailure('Failed to publish custom hunt: $e'));
    }
  }

  @override
  Future<Result<List<HuntModel>>> fetchUserCreatedHunts(String userId) async {
    try {
      final snapshot = await _huntsCollection
          .where('creatorUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final hunts = snapshot.docs.map(HuntModel.fromFirestore).toList();
      return Success(hunts);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to fetch user created hunts', tag: _tag, error: e);
      return Err(ServerFailure('Failed to load your created hunts: $e'));
    }
  }

  @override
  Future<Result<HuntModel>> fetchHuntByAccessCode(String accessCode) async {
    try {
      final cleanCode = accessCode.trim().toUpperCase();
      final snapshot = await _huntsCollection
          .where('accessCode', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return Err(NotFoundFailure('No hunt found with code "$cleanCode".'));
      }

      return Success(HuntModel.fromFirestore(snapshot.docs.first));
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to fetch hunt by code', tag: _tag, error: e);
      return Err(ServerFailure('Failed to find hunt: $e'));
    }
  }

  @override
  Future<Result<void>> deleteCreatedHunt({
    required String huntId,
    required String userId,
  }) async {
    try {
      final docRef = _huntsCollection.doc(huntId);
      final doc = await docRef.get();
      if (!doc.exists) return const Err(NotFoundFailure('Hunt not found.'));

      final hunt = HuntModel.fromFirestore(doc);
      if (hunt.creatorUserId != userId) {
        return const Err(
          PermissionFailure('You do not have permission to delete this hunt.'),
        );
      }

      // Delete checkpoints sub-collection & hunt document
      final checkpoints = await _firestore
          .collection(FirestorePaths.checkpointsCollection(huntId))
          .get();

      final batch = _firestore.batch();
      for (final cpDoc in checkpoints.docs) {
        batch.delete(cpDoc.reference);
      }
      batch.delete(docRef);

      await batch.commit();

      AppLogger.i('UGC Hunt $huntId deleted by $userId', tag: _tag);
      return const Success(null);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to delete created hunt', tag: _tag, error: e);
      return Err(ServerFailure('Failed to delete hunt: $e'));
    }
  }

  // ── Private: Access Code Generator ──────────────────────────────────────────

  Future<String> _generateUniqueAccessCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude confusing 0/O, 1/I
    final rng = Random();

    for (var attempt = 0; attempt < 10; attempt++) {
      final code = String.fromCharCodes(
        Iterable.generate(
          6,
          (_) => chars.codeUnitAt(rng.nextInt(chars.length)),
        ),
      );

      final snapshot = await _huntsCollection
          .where('accessCode', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return code;
    }

    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(rng.nextInt(chars.length)),
      ),
    );
  }
}
