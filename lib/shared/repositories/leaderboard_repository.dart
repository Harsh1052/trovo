import '../../core/error/result.dart';
import '../models/guardian_record_model.dart';
import '../models/league_member_model.dart';
import '../models/user_rank_model.dart';

abstract class LeaderboardRepository {
  /// Fetches current Guardian for a specific [huntId].
  Future<Result<GuardianRecordModel?>> fetchHuntGuardian(String huntId);

  /// Fetches all Guardians in a city (e.g. Surat).
  Future<Result<List<GuardianRecordModel>>> fetchCityGuardians(String city);

  /// Evaluates and claims Guardian status if player [completionTimeSeconds] is faster than existing record.
  Future<Result<bool>> submitHuntCompletionTime({
    required String huntId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required int completionTimeSeconds,
  });

  /// Fetches 20-Player Weekly League cohort standings for a user.
  Future<Result<List<LeagueMemberModel>>> fetchWeeklyLeagueStandings(String userId);

  /// Fetches Hunter XP Rank stats for a user.
  Future<Result<UserRankModel>> fetchUserRankStats(String userId);
}
