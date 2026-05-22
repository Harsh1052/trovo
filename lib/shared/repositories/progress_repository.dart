import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/constants/firestore_paths.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../models/hunt_progress_model.dart';

// ── Abstract contract ─────────────────────────────────────────────────────────

abstract class ProgressRepository {
  Future<Result<HuntProgressModel?>> fetchProgress(
      String userId, String huntId);

  Future<Result<HuntProgressModel>> startHunt(String userId, String huntId);

  Future<Result<void>> saveProgress(HuntProgressModel progress);

  Future<Result<List<HuntProgressModel>>> fetchUserProgress(String userId);
}

// ── Firebase implementation ───────────────────────────────────────────────────

class FirebaseProgressRepository implements ProgressRepository {
  FirebaseProgressRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<Result<HuntProgressModel?>> fetchProgress(
      String userId, String huntId) async {
    try {
      final doc = await _firestore
          .doc(FirestorePaths.huntProgressDoc(userId, huntId))
          .get();
      if (!doc.exists) return const Success(null);
      return Success(HuntProgressModel.fromFirestore(doc));
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      return Err(ServerFailure('Failed to fetch progress: $e'));
    }
  }

  @override
  Future<Result<HuntProgressModel>> startHunt(
      String userId, String huntId) async {
    try {
      final docRef =
          _firestore.doc(FirestorePaths.huntProgressDoc(userId, huntId));

      final progress = HuntProgressModel(
        documentId: '${userId}_$huntId',
        userId: userId,
        huntId: huntId,
        status: HuntStatus.inProgress,
        currentCheckpointIndex: 0,
        hintsUsed: 0,
        startedAt: DateTime.now(),
      );

      await docRef.set(progress.toFirestore());
      return Success(progress);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      return Err(ServerFailure('Failed to start hunt: $e'));
    }
  }

  @override
  Future<Result<void>> saveProgress(HuntProgressModel progress) async {
    try {
      await _firestore
          .doc(FirestorePaths.huntProgressDoc(
              progress.userId, progress.huntId))
          .set(progress.toFirestore(), SetOptions(merge: true));
      return const Success(null);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      return Err(ServerFailure('Failed to save progress: $e'));
    }
  }

  @override
  Future<Result<List<HuntProgressModel>>> fetchUserProgress(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.huntProgress)
          .where(FirestorePaths.fieldUserId, isEqualTo: userId)
          .orderBy(FirestorePaths.fieldStartedAt, descending: true)
          .get();
      return Success(
          snapshot.docs.map(HuntProgressModel.fromFirestore).toList());
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      return Err(ServerFailure('Failed to fetch user progress: $e'));
    }
  }
}
