import 'package:equatable/equatable.dart';

import '../../../shared/models/guardian_record_model.dart';
import '../../../shared/models/league_member_model.dart';
import '../../../shared/models/user_rank_model.dart';

sealed class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => [];
}

final class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

final class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

final class LeaderboardLoaded extends LeaderboardState {
  const LeaderboardLoaded({
    required this.tabIndex,
    required this.guardians,
    required this.leagueStandings,
    required this.userRank,
  });

  final int tabIndex; // 0 = Guardians, 1 = Weekly League
  final List<GuardianRecordModel> guardians;
  final List<LeagueMemberModel> leagueStandings;
  final UserRankModel userRank;

  LeaderboardLoaded copyWith({
    int? tabIndex,
    List<GuardianRecordModel>? guardians,
    List<LeagueMemberModel>? leagueStandings,
    UserRankModel? userRank,
  }) {
    return LeaderboardLoaded(
      tabIndex: tabIndex ?? this.tabIndex,
      guardians: guardians ?? this.guardians,
      leagueStandings: leagueStandings ?? this.leagueStandings,
      userRank: userRank ?? this.userRank,
    );
  }

  @override
  List<Object?> get props => [
        tabIndex,
        guardians,
        leagueStandings,
        userRank,
      ];
}

final class LeaderboardError extends LeaderboardState {
  const LeaderboardError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
