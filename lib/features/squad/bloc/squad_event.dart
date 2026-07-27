import 'package:equatable/equatable.dart';

/// Events for [SquadBloc].
sealed class SquadEvent extends Equatable {
  const SquadEvent();

  @override
  List<Object?> get props => [];
}

/// Host creates a new squad room for a specific hunt.
final class SquadCreateRequested extends SquadEvent {
  const SquadCreateRequested({
    required this.huntId,
    required this.hostUserId,
    required this.hostDisplayName,
  });

  final String huntId;
  final String hostUserId;
  final String hostDisplayName;

  @override
  List<Object?> get props => [huntId, hostUserId, hostDisplayName];
}

/// A player joins an existing squad via room code.
final class SquadJoinRequested extends SquadEvent {
  const SquadJoinRequested({
    required this.roomCode,
    required this.userId,
    required this.displayName,
  });

  final String roomCode;
  final String userId;
  final String displayName;

  @override
  List<Object?> get props => [roomCode, userId, displayName];
}

/// Internal: real-time Firestore snapshot pushed a new session state.
final class SquadSessionUpdated extends SquadEvent {
  const SquadSessionUpdated(this.session);
  final dynamic session; // SquadSessionModel — typed in BLoC

  @override
  List<Object?> get props => [session];
}

/// Lobby: member toggles their ready state.
final class SquadReadyToggled extends SquadEvent {
  const SquadReadyToggled({
    required this.userId,
    required this.ready,
  });

  final String userId;
  final bool ready;

  @override
  List<Object?> get props => [userId, ready];
}

/// Host-only: start the hunt once all members are ready.
final class SquadHuntStarted extends SquadEvent {
  const SquadHuntStarted();
}

/// Member leaves the squad.
final class SquadLeft extends SquadEvent {
  const SquadLeft({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Throttled GPS coordinate sync.
final class SquadLocationSynced extends SquadEvent {
  const SquadLocationSynced({
    required this.userId,
    required this.latitude,
    required this.longitude,
  });

  final String userId;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [userId, latitude, longitude];
}
