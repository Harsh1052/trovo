import 'package:equatable/equatable.dart';

sealed class ActiveHuntEvent extends Equatable {
  const ActiveHuntEvent();

  @override
  List<Object?> get props => [];
}

/// Start a new hunt — fetches checkpoints, creates the progress doc, then
/// runs the 3-2-1 countdown before entering [ActiveHuntInProgress].
final class ActiveHuntStarted extends ActiveHuntEvent {
  const ActiveHuntStarted({required this.huntId, required this.userId});

  final String huntId;
  final String userId;

  @override
  List<Object?> get props => [huntId, userId];
}

/// Resume a hunt that was previously started but not finished.
final class ActiveHuntResumed extends ActiveHuntEvent {
  const ActiveHuntResumed({required this.huntId, required this.userId});

  final String huntId;
  final String userId;

  @override
  List<Object?> get props => [huntId, userId];
}

/// User submitted a text answer for the current clue checkpoint.
final class ActiveHuntCheckpointAnswerSubmitted extends ActiveHuntEvent {
  const ActiveHuntCheckpointAnswerSubmitted(this.answer);

  final String answer;

  @override
  List<Object?> get props => [answer];
}

/// User submitted a photo for the current photo-task checkpoint.
/// No answer validation required — GPS proximity check only.
final class ActiveHuntPhotoSubmitted extends ActiveHuntEvent {
  const ActiveHuntPhotoSubmitted();
}

/// User requested a hint for the current checkpoint.
final class ActiveHuntHintRequested extends ActiveHuntEvent {
  const ActiveHuntHintRequested();
}

/// New GPS position received from the location stream.
final class ActiveHuntLocationUpdated extends ActiveHuntEvent {
  const ActiveHuntLocationUpdated({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Toggle between the clue view and the map view.
final class ActiveHuntMapToggled extends ActiveHuntEvent {
  const ActiveHuntMapToggled();
}

/// User chose to quit the hunt.
final class ActiveHuntAbandoned extends ActiveHuntEvent {
  const ActiveHuntAbandoned();
}

/// Internal: fired every second by the periodic timer.
final class ActiveHuntTimerTicked extends ActiveHuntEvent {
  const ActiveHuntTimerTicked();
}

/// User tapped "Allow Location" or "Open Settings" on the permission-denied
/// screen. Re-checks permission and resumes the hunt if granted.
final class ActiveHuntLocationRetried extends ActiveHuntEvent {
  const ActiveHuntLocationRetried();
}

