import 'package:equatable/equatable.dart';

import '../../../shared/models/checkpoint_model.dart';
import '../../../shared/models/hunt_model.dart';

sealed class HuntCreatorState extends Equatable {
  const HuntCreatorState();

  @override
  List<Object?> get props => [];
}

/// Initial wizard state with default form values.
final class HuntCreatorFormState extends HuntCreatorState {
  const HuntCreatorFormState({
    this.stepIndex = 0,
    this.title = '',
    this.description = '',
    this.city = 'Surat',
    this.gardenName = '',
    this.difficulty = HuntDifficulty.medium,
    this.durationMinutes = 45,
    this.coverImageUrl = '',
    this.isPrivate = false,
    this.checkpoints = const [],
    this.validationError,
  });

  final int stepIndex; // 0 = Details, 1 = Checkpoints, 2 = Review & Publish
  final String title;
  final String description;
  final String city;
  final String gardenName;
  final HuntDifficulty difficulty;
  final int durationMinutes;
  final String coverImageUrl;
  final bool isPrivate;
  final List<CheckpointModel> checkpoints;
  final String? validationError;

  bool get isStep1Valid =>
      title.trim().length >= 5 &&
      description.trim().length >= 20 &&
      city.trim().isNotEmpty &&
      gardenName.trim().isNotEmpty;

  bool get isStep2Valid => checkpoints.length >= 2 && checkpoints.length <= 10;

  bool get canPublish => isStep1Valid && isStep2Valid;

  HuntCreatorFormState copyWith({
    int? stepIndex,
    String? title,
    String? description,
    String? city,
    String? gardenName,
    HuntDifficulty? difficulty,
    int? durationMinutes,
    String? coverImageUrl,
    bool? isPrivate,
    List<CheckpointModel>? checkpoints,
    String? validationError,
  }) {
    return HuntCreatorFormState(
      stepIndex: stepIndex ?? this.stepIndex,
      title: title ?? this.title,
      description: description ?? this.description,
      city: city ?? this.city,
      gardenName: gardenName ?? this.gardenName,
      difficulty: difficulty ?? this.difficulty,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isPrivate: isPrivate ?? this.isPrivate,
      checkpoints: checkpoints ?? this.checkpoints,
      validationError: validationError,
    );
  }

  @override
  List<Object?> get props => [
        stepIndex,
        title,
        description,
        city,
        gardenName,
        difficulty,
        durationMinutes,
        coverImageUrl,
        isPrivate,
        checkpoints,
        validationError,
      ];
}

/// Submitting hunt batch write to Firestore.
final class HuntCreatorSubmitting extends HuntCreatorState {
  const HuntCreatorSubmitting();
}

/// Hunt published successfully!
final class HuntCreatorSuccess extends HuntCreatorState {
  const HuntCreatorSuccess({
    required this.publishedHunt,
    this.accessCode,
  });

  final HuntModel publishedHunt;
  final String? accessCode;

  @override
  List<Object?> get props => [publishedHunt, accessCode];
}

/// Error during submission or validation failure.
final class HuntCreatorError extends HuntCreatorState {
  const HuntCreatorError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
