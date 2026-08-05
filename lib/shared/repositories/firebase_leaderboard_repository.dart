import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/logger.dart';
import '../models/guardian_record_model.dart';
import '../models/league_member_model.dart';
import '../models/user_rank_model.dart';
import 'leaderboard_repository.dart';

class FirebaseLeaderboardRepository implements LeaderboardRepository {
  FirebaseLeaderboardRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;
  static const _tag = 'FirebaseLeaderboardRepository';

  CollectionReference<Map<String, dynamic>> get _guardiansCollection =>
      _firestore.collection('guardians');

  @override
  Future<Result<GuardianRecordModel?>> fetchHuntGuardian(String huntId) async {
    try {
      final doc = await _guardiansCollection.doc(huntId).get();
      if (!doc.exists) return const Success(null);
      return Success(GuardianRecordModel.fromFirestore(doc));
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to fetch hunt guardian', tag: _tag, error: e);
      return Err(ServerFailure('Failed to load guardian status: $e'));
    }
  }

  @override
  Future<Result<List<GuardianRecordModel>>> fetchCityGuardians(String city) async {
    try {
      final snapshot = await _guardiansCollection.get();
      final list = snapshot.docs.map(GuardianRecordModel.fromFirestore).toList();
      return Success(list);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to fetch city guardians', tag: _tag, error: e);
      return Err(ServerFailure('Failed to load guardians: $e'));
    }
  }

  @override
  Future<Result<bool>> submitHuntCompletionTime({
    required String huntId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required int completionTimeSeconds,
  }) async {
    try {
      final docRef = _guardiansCollection.doc(huntId);
      final doc = await docRef.get();

      bool isNewRecord = false;

      if (!doc.exists) {
        isNewRecord = true;
      } else {
        final currentGuardian = GuardianRecordModel.fromFirestore(doc);
        if (completionTimeSeconds < currentGuardian.bestTimeSeconds) {
          isNewRecord = true;
        }
      }

      if (isNewRecord) {
        final newGuardian = GuardianRecordModel(
          huntId: huntId,
          guardianUserId: userId,
          guardianName: userName,
          guardianPhotoUrl: userPhotoUrl,
          bestTimeSeconds: completionTimeSeconds,
          setAt: DateTime.now(),
        );

        await docRef.set(newGuardian.toFirestore());
        AppLogger.i('New Guardian claimed for hunt $huntId by $userId!', tag: _tag);
      }

      return Success(isNewRecord);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to submit completion time', tag: _tag, error: e);
      return Err(ServerFailure('Failed to update record: $e'));
    }
  }

  @override
  Future<Result<List<LeagueMemberModel>>> fetchWeeklyLeagueStandings(String userId) async {
    try {
      // Mock / Seed 20-Player League standings for fast response
      final mockStandings = [
        LeagueMemberModel(
          userId: 'user_1',
          displayName: 'Aarav Patel 👑',
          weeklyXp: 1450,
          rankPosition: 1,
          leagueTier: 'Emerald',
        ),
        LeagueMemberModel(
          userId: 'user_2',
          displayName: 'Riya Sharma ⚡',
          weeklyXp: 1200,
          rankPosition: 2,
          leagueTier: 'Emerald',
        ),
        LeagueMemberModel(
          userId: userId,
          displayName: 'You (Hunter) 🎯',
          weeklyXp: 950,
          rankPosition: 3,
          leagueTier: 'Emerald',
        ),
        LeagueMemberModel(
          userId: 'user_4',
          displayName: 'Dev Shah',
          weeklyXp: 820,
          rankPosition: 4,
          leagueTier: 'Emerald',
        ),
        LeagueMemberModel(
          userId: 'user_5',
          displayName: 'Karan Mehta',
          weeklyXp: 750,
          rankPosition: 5,
          leagueTier: 'Emerald',
        ),
        LeagueMemberModel(
          userId: 'user_6',
          displayName: 'Priya Joshi',
          weeklyXp: 610,
          rankPosition: 6,
          leagueTier: 'Emerald',
        ),
      ];

      return Success(mockStandings);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to fetch league standings', tag: _tag, error: e);
      return Err(ServerFailure('Failed to load league standings: $e'));
    }
  }

  @override
  Future<Result<UserRankModel>> fetchUserRankStats(String userId) async {
    try {
      final stats = UserRankModel(
        userId: userId,
        totalXp: 1250,
        huntsCompleted: 3,
        guardianshipsHeld: 1,
      );
      return Success(stats);
    } on AppException catch (e) {
      return Err(e.toFailure());
    } catch (e) {
      AppLogger.e('Failed to fetch rank stats', tag: _tag, error: e);
      return Err(ServerFailure('Failed to load rank stats: $e'));
    }
  }
}
