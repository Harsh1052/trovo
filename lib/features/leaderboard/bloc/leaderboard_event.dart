import 'package:equatable/equatable.dart';

sealed class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object?> get props => [];
}

final class LeaderboardLoadRequested extends LeaderboardEvent {
  const LeaderboardLoadRequested({
    required this.userId,
    this.city = 'Surat',
  });

  final String userId;
  final String city;

  @override
  List<Object?> get props => [userId, city];
}

final class LeaderboardTabChanged extends LeaderboardEvent {
  const LeaderboardTabChanged(this.tabIndex);
  final int tabIndex; // 0 = Guardians, 1 = Weekly League

  @override
  List<Object?> get props => [tabIndex];
}
