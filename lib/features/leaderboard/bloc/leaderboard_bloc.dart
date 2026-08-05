import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/result.dart';
import '../../../shared/models/guardian_record_model.dart';
import '../../../shared/models/league_member_model.dart';
import '../../../shared/models/user_rank_model.dart';
import '../../../shared/repositories/leaderboard_repository.dart';
import 'leaderboard_event.dart';
import 'leaderboard_state.dart';

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  LeaderboardBloc({required LeaderboardRepository leaderboardRepository})
      : _leaderboardRepository = leaderboardRepository,
        super(const LeaderboardInitial()) {
    on<LeaderboardLoadRequested>(_onLoadRequested);
    on<LeaderboardTabChanged>(_onTabChanged);
  }

  final LeaderboardRepository _leaderboardRepository;

  Future<void> _onLoadRequested(
    LeaderboardLoadRequested event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());

    final guardiansResult =
        await _leaderboardRepository.fetchCityGuardians(event.city);
    final standingsResult =
        await _leaderboardRepository.fetchWeeklyLeagueStandings(event.userId);
    final userRankResult =
        await _leaderboardRepository.fetchUserRankStats(event.userId);

    if (guardiansResult is Err || standingsResult is Err || userRankResult is Err) {
      emit(const LeaderboardError('Failed to load leaderboard data.'));
      return;
    }

    final guardians = (guardiansResult as Success<List<GuardianRecordModel>>).data;
    final standings = (standingsResult as Success<List<LeagueMemberModel>>).data;
    final rank = (userRankResult as Success<UserRankModel>).data;

    emit(
      LeaderboardLoaded(
        tabIndex: 0,
        guardians: guardians,
        leagueStandings: standings,
        userRank: rank,
      ),
    );
  }

  void _onTabChanged(
    LeaderboardTabChanged event,
    Emitter<LeaderboardState> emit,
  ) {
    if (state is LeaderboardLoaded) {
      final current = state as LeaderboardLoaded;
      emit(current.copyWith(tabIndex: event.tabIndex));
    }
  }
}
