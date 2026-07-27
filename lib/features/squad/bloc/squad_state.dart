import 'package:equatable/equatable.dart';

import '../../../shared/models/squad_session_model.dart';

/// States for [SquadBloc].
sealed class SquadState extends Equatable {
  const SquadState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action.
final class SquadInitial extends SquadState {
  const SquadInitial();
}

/// Loading while creating or joining a squad.
final class SquadLoading extends SquadState {
  const SquadLoading();
}

/// The squad is in the lobby, waiting for members to ready up.
final class SquadLobby extends SquadState {
  const SquadLobby({
    required this.session,
    required this.currentUserId,
  });

  final SquadSessionModel session;

  /// The currently authenticated user's ID, used to determine host vs member.
  final String currentUserId;

  /// Whether the current user is the host of this squad.
  bool get isHost => session.isHost(currentUserId);

  /// Whether all members are ready (host can start).
  bool get canStart => session.allMembersReady && session.memberCount >= 2;

  /// Current user's ready state.
  bool get isCurrentUserReady =>
      session.memberById(currentUserId)?.isReady ?? false;

  @override
  List<Object?> get props => [session, currentUserId];
}

/// The hunt has started — redirect the player to the active hunt flow.
final class SquadHuntActive extends SquadState {
  const SquadHuntActive({
    required this.session,
    required this.currentUserId,
  });

  final SquadSessionModel session;
  final String currentUserId;

  @override
  List<Object?> get props => [session, currentUserId];
}

/// An error occurred during a squad operation.
final class SquadError extends SquadState {
  const SquadError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// The squad was dissolved (host left or session expired).
final class SquadDisbanded extends SquadState {
  const SquadDisbanded({this.message = 'The squad has been disbanded.'});

  final String message;

  @override
  List<Object?> get props => [message];
}
