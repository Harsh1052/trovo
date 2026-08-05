import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/result.dart';
import '../../../shared/models/checkpoint_model.dart';
import '../../../shared/models/hunt_model.dart';
import '../../../shared/repositories/creator_repository.dart';
import 'hunt_creator_event.dart';
import 'hunt_creator_state.dart';

class HuntCreatorBloc extends Bloc<HuntCreatorEvent, HuntCreatorState> {
  HuntCreatorBloc({required CreatorRepository creatorRepository})
      : _creatorRepository = creatorRepository,
        super(const HuntCreatorFormState()) {
    on<HuntCreatorStepChanged>(_onStepChanged);
    on<HuntCreatorDetailsUpdated>(_onDetailsUpdated);
    on<HuntCreatorCheckpointAdded>(_onCheckpointAdded);
    on<HuntCreatorCheckpointUpdated>(_onCheckpointUpdated);
    on<HuntCreatorCheckpointRemoved>(_onCheckpointRemoved);
    on<HuntCreatorCheckpointsReordered>(_onCheckpointsReordered);
    on<HuntCreatorSubmitted>(_onSubmitted);
  }

  final CreatorRepository _creatorRepository;

  void _onStepChanged(
    HuntCreatorStepChanged event,
    Emitter<HuntCreatorState> emit,
  ) {
    if (state is HuntCreatorFormState) {
      final current = state as HuntCreatorFormState;
      emit(current.copyWith(stepIndex: event.stepIndex, validationError: null));
    }
  }

  void _onDetailsUpdated(
    HuntCreatorDetailsUpdated event,
    Emitter<HuntCreatorState> emit,
  ) {
    if (state is HuntCreatorFormState) {
      final current = state as HuntCreatorFormState;
      emit(current.copyWith(
        title: event.title,
        description: event.description,
        city: event.city,
        gardenName: event.gardenName,
        difficulty: event.difficulty,
        durationMinutes: event.durationMinutes,
        coverImageUrl: event.coverImageUrl,
        isPrivate: event.isPrivate,
        validationError: null,
      ));
    }
  }

  void _onCheckpointAdded(
    HuntCreatorCheckpointAdded event,
    Emitter<HuntCreatorState> emit,
  ) {
    if (state is HuntCreatorFormState) {
      final current = state as HuntCreatorFormState;
      final updatedList = List<CheckpointModel>.from(current.checkpoints)
        ..add(event.checkpoint);
      emit(current.copyWith(checkpoints: updatedList, validationError: null));
    }
  }

  void _onCheckpointUpdated(
    HuntCreatorCheckpointUpdated event,
    Emitter<HuntCreatorState> emit,
  ) {
    if (state is HuntCreatorFormState) {
      final current = state as HuntCreatorFormState;
      final updatedList = List<CheckpointModel>.from(current.checkpoints);
      if (event.index >= 0 && event.index < updatedList.length) {
        updatedList[event.index] = event.checkpoint;
        emit(current.copyWith(checkpoints: updatedList, validationError: null));
      }
    }
  }

  void _onCheckpointRemoved(
    HuntCreatorCheckpointRemoved event,
    Emitter<HuntCreatorState> emit,
  ) {
    if (state is HuntCreatorFormState) {
      final current = state as HuntCreatorFormState;
      final updatedList = List<CheckpointModel>.from(current.checkpoints);
      if (event.index >= 0 && event.index < updatedList.length) {
        updatedList.removeAt(event.index);
        emit(current.copyWith(checkpoints: updatedList, validationError: null));
      }
    }
  }

  void _onCheckpointsReordered(
    HuntCreatorCheckpointsReordered event,
    Emitter<HuntCreatorState> emit,
  ) {
    if (state is HuntCreatorFormState) {
      final current = state as HuntCreatorFormState;
      final updatedList = List<CheckpointModel>.from(current.checkpoints);
      var newIndex = event.newIndex;
      if (oldIndexIsBeforeNewIndex(event.oldIndex, newIndex)) {
        newIndex -= 1;
      }
      final item = updatedList.removeAt(event.oldIndex);
      updatedList.insert(newIndex, item);
      emit(current.copyWith(checkpoints: updatedList, validationError: null));
    }
  }

  Future<void> _onSubmitted(
    HuntCreatorSubmitted event,
    Emitter<HuntCreatorState> emit,
  ) async {
    if (state is! HuntCreatorFormState) return;
    final form = state as HuntCreatorFormState;

    if (!form.isStep1Valid) {
      emit(form.copyWith(
        validationError: 'Please complete all required story details in Step 1.',
      ));
      return;
    }

    if (!form.isStep2Valid) {
      emit(form.copyWith(
        validationError: 'Please add between 2 and 10 checkpoints in Step 2.',
      ));
      return;
    }

    emit(const HuntCreatorSubmitting());

    final draftHunt = HuntModel(
      huntId: '', // Set by repository
      title: form.title.trim(),
      description: form.description.trim(),
      city: form.city.trim(),
      gardenName: form.gardenName.trim(),
      difficulty: form.difficulty,
      durationMinutes: form.durationMinutes,
      checkpointCount: form.checkpoints.length,
      isFree: true,
      price: 0,
      coverImageUrl: form.coverImageUrl.trim(),
      startLatitude: form.checkpoints.first.latitude,
      startLongitude: form.checkpoints.first.longitude,
      isActive: true,
      createdAt: DateTime.now(),
      creatorUserId: event.creatorUserId,
      creatorName: event.creatorName,
      isPrivate: form.isPrivate,
    );

    final result = await _creatorRepository.createHunt(
      hunt: draftHunt,
      checkpoints: form.checkpoints,
    );

    switch (result) {
      case Success(:final data):
        emit(HuntCreatorSuccess(
          publishedHunt: data,
          accessCode: data.accessCode,
        ));
      case Err(:final failure):
        emit(HuntCreatorError(failure.userFriendlyMessage));
    }
  }

  bool oldIndexIsBeforeNewIndex(int oldIndex, int newIndex) =>
      oldIndex < newIndex;
}
