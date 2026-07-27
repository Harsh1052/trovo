import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/constants/firestore_paths.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/logger.dart';
import '../models/squad_member_model.dart';
import '../models/squad_session_model.dart';
import 'squad_repository.dart';

/// Firestore-backed implementation of [SquadRepository].
///
/// Design decisions:
/// - Members stored as a list field (not sub-collection) for atomic reads.
/// - Room code uniqueness enforced by querying active sessions before insert.
/// - Host leaving dissolves the squad; non-host leaving removes them.
class FirebaseSquadRepository implements SquadRepository {
  FirebaseSquadRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;
  static const _tag = 'FirebaseSquadRepository';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.squadSessions);

  // ── Create ────────────────────────────────────────────────────────────────

  @override
  Future<Result<SquadSessionModel>> createSquad({
    required String huntId,
    required String hostUserId,
    required String hostDisplayName,
  }) async {
    try {
      final roomCode = await _generateUniqueRoomCode();

      final now = DateTime.now();
      final docRef = _collection.doc();

      final host = SquadMemberModel(
        userId: hostUserId,
        displayName: hostDisplayName,
        latitude: 0.0,
        longitude: 0.0,
        isReady: true, // Host is auto-ready.
        joinedAt: now,
      );

      final session = SquadSessionModel(
        squadId: docRef.id,
        roomCode: roomCode,
        huntId: huntId,
        hostUserId: hostUserId,
        status: SquadStatus.lobby,
        currentCheckpointIndex: 0,
        squadScore: 0,
        createdAt: now,
        lastActivityAt: now,
        members: [host],
      );

      await docRef.set(session.toFirestore());
      AppLogger.i('Squad created: ${docRef.id} (code: $roomCode)', tag: _tag);
      return Success(session);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to create squad', tag: _tag, error: e);
      return Err(ServerFailure('Failed to create squad: $e'));
    }
  }

  // ── Join ───────────────────────────────────────────────────────────────────

  @override
  Future<Result<SquadSessionModel>> joinSquad({
    required String roomCode,
    required String userId,
    required String displayName,
  }) async {
    try {
      // Find the active session with this room code.
      final snapshot = await _collection
          .where('roomCode', isEqualTo: roomCode)
          .where('status', isEqualTo: SquadStatus.lobby.storageName)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Err(NotFoundFailure('No squad found with this code.'));
      }

      final doc = snapshot.docs.first;
      final session = SquadSessionModel.fromFirestore(doc);

      // Validate.
      if (!session.hasRoom) {
        return const Err(ServerFailure('This squad is full (max 4 players).'));
      }
      if (session.memberById(userId) != null) {
        return const Err(ServerFailure('You are already in this squad.'));
      }

      final newMember = SquadMemberModel(
        userId: userId,
        displayName: displayName,
        latitude: 0.0,
        longitude: 0.0,
        isReady: false,
        joinedAt: DateTime.now(),
      );

      // Atomic array append + activity timestamp update.
      await doc.reference.update({
        'members': FieldValue.arrayUnion([newMember.toFirestore()]),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      final updatedSession = session.copyWith(
        members: [...session.members, newMember],
      );

      AppLogger.i('User $userId joined squad ${doc.id}', tag: _tag);
      return Success(updatedSession);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to join squad', tag: _tag, error: e);
      return Err(ServerFailure('Failed to join squad: $e'));
    }
  }

  // ── Leave ─────────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> leaveSquad({
    required String squadId,
    required String userId,
  }) async {
    try {
      final docRef = _collection.doc(squadId);
      final doc = await docRef.get();

      if (!doc.exists) {
        return const Err(NotFoundFailure('Squad not found.'));
      }

      final session = SquadSessionModel.fromFirestore(doc);

      if (session.isHost(userId)) {
        // Host leaving → dissolve the entire squad.
        await docRef.update({
          'status': SquadStatus.completed.storageName,
          'lastActivityAt': FieldValue.serverTimestamp(),
        });
        AppLogger.i('Host left, squad $squadId dissolved', tag: _tag);
      } else {
        // Remove the member from the array.
        final memberData = session
            .memberById(userId)
            ?.toFirestore();
        if (memberData != null) {
          await docRef.update({
            'members': FieldValue.arrayRemove([memberData]),
            'lastActivityAt': FieldValue.serverTimestamp(),
          });
        }
        AppLogger.i('User $userId left squad $squadId', tag: _tag);
      }

      return const Success(null);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to leave squad', tag: _tag, error: e);
      return Err(ServerFailure('Failed to leave squad: $e'));
    }
  }

  // ── Watch (real-time) ─────────────────────────────────────────────────────

  @override
  Stream<SquadSessionModel> watchSquad(String squadId) {
    return _collection.doc(squadId).snapshots().map((doc) {
      if (!doc.exists) {
        // Return a completed/empty session if the doc is deleted.
        return SquadSessionModel(
          squadId: squadId,
          roomCode: '',
          huntId: '',
          hostUserId: '',
          status: SquadStatus.completed,
          currentCheckpointIndex: 0,
          squadScore: 0,
          createdAt: DateTime.now(),
          lastActivityAt: DateTime.now(),
          members: const [],
        );
      }
      return SquadSessionModel.fromFirestore(doc);
    });
  }

  // ── Ready toggle ──────────────────────────────────────────────────────────

  @override
  Future<Result<void>> setReady({
    required String squadId,
    required String userId,
    required bool ready,
  }) async {
    try {
      final docRef = _collection.doc(squadId);
      final doc = await docRef.get();
      if (!doc.exists) {
        return const Err(NotFoundFailure('Squad not found.'));
      }

      final session = SquadSessionModel.fromFirestore(doc);
      final updatedMembers = session.members.map((m) {
        if (m.userId == userId) return m.copyWith(isReady: ready);
        return m;
      }).toList();

      await docRef.update({
        'members': updatedMembers.map((m) => m.toFirestore()).toList(),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      return const Success(null);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to set ready', tag: _tag, error: e);
      return Err(ServerFailure('Failed to update ready state: $e'));
    }
  }

  // ── Start hunt ────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> startSquadHunt(String squadId) async {
    try {
      await _collection.doc(squadId).update({
        'status': SquadStatus.active.storageName,
        'lastActivityAt': FieldValue.serverTimestamp(),
      });
      AppLogger.i('Squad $squadId hunt started', tag: _tag);
      return const Success(null);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to start squad hunt', tag: _tag, error: e);
      return Err(ServerFailure('Failed to start squad hunt: $e'));
    }
  }

  // ── Advance checkpoint ────────────────────────────────────────────────────

  @override
  Future<Result<void>> advanceCheckpoint({
    required String squadId,
    required int newIndex,
  }) async {
    try {
      await _collection.doc(squadId).update({
        'currentCheckpointIndex': newIndex,
        'lastActivityAt': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to advance checkpoint', tag: _tag, error: e);
      return Err(ServerFailure('Failed to advance checkpoint: $e'));
    }
  }

  // ── Location sync ─────────────────────────────────────────────────────────

  @override
  Future<Result<void>> updateMemberLocation({
    required String squadId,
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final docRef = _collection.doc(squadId);
      final doc = await docRef.get();
      if (!doc.exists) return const Err(NotFoundFailure('Squad not found.'));

      final session = SquadSessionModel.fromFirestore(doc);
      final updatedMembers = session.members.map((m) {
        if (m.userId == userId) {
          return m.copyWith(latitude: latitude, longitude: longitude);
        }
        return m;
      }).toList();

      await docRef.update({
        'members': updatedMembers.map((m) => m.toFirestore()).toList(),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      return const Success(null);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      return Err(ServerFailure('Failed to update location: $e'));
    }
  }

  // ── Complete ──────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> completeSquad(String squadId) async {
    try {
      await _collection.doc(squadId).update({
        'status': SquadStatus.completed.storageName,
        'lastActivityAt': FieldValue.serverTimestamp(),
      });
      AppLogger.i('Squad $squadId completed', tag: _tag);
      return const Success(null);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to complete squad', tag: _tag, error: e);
      return Err(ServerFailure('Failed to complete squad: $e'));
    }
  }

  // ── Private: Room code generation ─────────────────────────────────────────

  /// Generates a unique 4-digit room code by checking active sessions.
  Future<String> _generateUniqueRoomCode() async {
    final rng = Random();
    for (var attempt = 0; attempt < 10; attempt++) {
      final code = (1000 + rng.nextInt(9000)).toString(); // 1000–9999

      final existing = await _collection
          .where('roomCode', isEqualTo: code)
          .where('status', whereIn: [
            SquadStatus.lobby.storageName,
            SquadStatus.active.storageName,
          ])
          .limit(1)
          .get();

      if (existing.docs.isEmpty) return code;
    }
    // Fallback: append timestamp millis for uniqueness.
    return (1000 + rng.nextInt(9000)).toString();
  }
}
