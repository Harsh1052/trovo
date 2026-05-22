import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/result.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/hunt_model.dart';
import '../../../shared/models/hunt_progress_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/repositories/auth_repository.dart';
import '../../../shared/repositories/hunt_repository.dart';
import '../../../shared/repositories/progress_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required AuthRepository authRepository,
    required ProgressRepository progressRepository,
    required HuntRepository huntRepository,
  })  : _authRepository = authRepository,
        _progressRepository = progressRepository,
        _huntRepository = huntRepository,
        super(const ProfileInitial());

  final AuthRepository _authRepository;
  final ProgressRepository _progressRepository;
  final HuntRepository _huntRepository;
  static const _tag = 'ProfileCubit';

  Future<void> load() async {
    emit(const ProfileLoading());

    final userResult = await _authRepository.fetchCurrentUser();
    if (userResult case Err(:final failure)) {
      AppLogger.e('Profile: fetch user failed', tag: _tag, error: failure.message);
      emit(ProfileError(failure.userFriendlyMessage));
      return;
    }

    final user = (userResult as Success).data;
    if (user == null) {
      emit(const ProfileError('Not signed in.'));
      return;
    }

    final progressResult =
        await _progressRepository.fetchUserProgress(user.uid);
    if (progressResult case Err(:final failure)) {
      AppLogger.e('Profile: fetch progress failed', tag: _tag, error: failure.message);
      emit(ProfileError(failure.userFriendlyMessage));
      return;
    }

    final completed = (progressResult as Success)
        .data
        .where((p) => p.isComplete)
        .toList();

    // Fetch each completed hunt; skip any that fail individually.
    final huntResults = await Future.wait(
      completed.map((p) => _huntRepository.fetchHunt(p.huntId)),
    );

    final hunts = huntResults
        .whereType<Success<HuntModel>>()
        .map((r) => r.data)
        .toList();

    emit(ProfileLoaded(
      user: user,
      completedProgress: completed,
      completedHunts: hunts,
    ));
  }

  Future<void> signOut() async {
    // Best-effort; result is intentionally ignored — the auth stream
    // will fire AuthUnauthenticated which drives navigation.
    await _authRepository.signOut();
  }
}
