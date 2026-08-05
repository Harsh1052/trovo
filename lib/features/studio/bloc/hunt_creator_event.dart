import 'package:equatable/equatable.dart';

import '../../../shared/models/checkpoint_model.dart';
import '../../../shared/models/hunt_model.dart';

sealed class HuntCreatorEvent extends Equatable {
  const HuntCreatorEvent();

  @override
  List<Object?> get props => [];
}

/// Creator changed wizard step (0 = Details, 1 = Checkpoints, 2 = Review).
final class HuntCreatorStepChanged extends HuntCreatorEvent {
  const HuntCreatorStepChanged(this.stepIndex);
  final int stepIndex;

  @override
  List<Object?> get props => [stepIndex];
}

/// Creator updated Step 1 (hunt details metadata).
final class HuntCreatorDetailsUpdated extends HuntCreatorEvent {
  const HuntCreatorDetailsUpdated({
    required this.title,
    required this.description,
    required this.city,
    required this.gardenName,
    required this.difficulty,
    required this.durationMinutes,
    required this.coverImageUrl,
    required this.isPrivate,
  });

  final String title;
  final String description;
  final String city;
  final String gardenName;
  final HuntDifficulty difficulty;
  final int durationMinutes;
  final String coverImageUrl;
  final bool isPrivate;

  @override
  List<Object?> get props => [
        title,
        description,
        city,
        gardenName,
        difficulty,
        durationMinutes,
        coverImageUrl,
        isPrivate,
      ];
}

/// Creator added a new checkpoint stop.
final class HuntCreatorCheckpointAdded extends HuntCreatorEvent {
  const HuntCreatorCheckpointAdded(this.checkpoint);
  final CheckpointModel checkpoint;

  @override
  List<Object?> get props => [checkpoint];
}

/// Creator updated an existing checkpoint stop.
final class HuntCreatorCheckpointUpdated extends HuntCreatorEvent {
  const HuntCreatorCheckpointUpdated({
    required this.index,
    required this.checkpoint,
  });

  final int index;
  final CheckpointModel checkpoint;

  @override
  List<Object?> get props => [index, checkpoint];
}

/// Creator removed a checkpoint stop.
final class HuntCreatorCheckpointRemoved extends HuntCreatorEvent {
  const HuntCreatorCheckpointRemoved(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

/// Creator reordered checkpoint stops.
final class HuntCreatorCheckpointsReordered extends HuntCreatorEvent {
  const HuntCreatorCheckpointsReordered({
    required this.oldIndex,
    required this.newIndex,
  });

  final int oldIndex;
  final int newIndex;

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

/// Creator submitted the final form to publish the hunt.
final class HuntCreatorSubmitted extends HuntCreatorEvent {
  const HuntCreatorSubmitted({
    required this.creatorUserId,
    required this.creatorName,
  });

  final String creatorUserId;
  final String creatorName;

  @override
  List<Object?> get props => [creatorUserId, creatorName];
}
