import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/result.dart';
import '../../../shared/models/hunt_model.dart';
import '../../../shared/repositories/creator_repository.dart';

// ── States ──────────────────────────────────────────────────────────────────

sealed class MyCreatedHuntsState extends Equatable {
  const MyCreatedHuntsState();

  @override
  List<Object?> get props => [];
}

final class MyCreatedHuntsInitial extends MyCreatedHuntsState {
  const MyCreatedHuntsInitial();
}

final class MyCreatedHuntsLoading extends MyCreatedHuntsState {
  const MyCreatedHuntsLoading();
}

final class MyCreatedHuntsLoaded extends MyCreatedHuntsState {
  const MyCreatedHuntsLoaded(this.hunts);
  final List<HuntModel> hunts;

  @override
  List<Object?> get props => [hunts];
}

final class MyCreatedHuntsError extends MyCreatedHuntsState {
  const MyCreatedHuntsError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

// ── Cubit ───────────────────────────────────────────────────────────────────

class MyCreatedHuntsCubit extends Cubit<MyCreatedHuntsState> {
  MyCreatedHuntsCubit({required CreatorRepository creatorRepository})
      : _creatorRepository = creatorRepository,
        super(const MyCreatedHuntsInitial());

  final CreatorRepository _creatorRepository;

  Future<void> loadHunts(String userId) async {
    emit(const MyCreatedHuntsLoading());

    final result = await _creatorRepository.fetchUserCreatedHunts(userId);

    switch (result) {
      case Success(:final data):
        emit(MyCreatedHuntsLoaded(data));
      case Err(:final failure):
        emit(MyCreatedHuntsError(failure.userFriendlyMessage));
    }
  }

  Future<void> deleteHunt({
    required String huntId,
    required String userId,
  }) async {
    final result = await _creatorRepository.deleteCreatedHunt(
      huntId: huntId,
      userId: userId,
    );

    switch (result) {
      case Success():
        // Reload list after successful deletion
        await loadHunts(userId);
      case Err(:final failure):
        emit(MyCreatedHuntsError(failure.userFriendlyMessage));
    }
  }
}
