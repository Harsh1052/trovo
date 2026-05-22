import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/result.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/hunt_model.dart';
import '../../../shared/repositories/hunt_repository.dart';

part 'hunt_complete_state.dart';

class HuntCompleteCubit extends Cubit<HuntCompleteState> {
  HuntCompleteCubit({required HuntRepository huntRepository})
      : _huntRepository = huntRepository,
        super(const HuntCompleteInitial());

  final HuntRepository _huntRepository;
  static const _tag = 'HuntCompleteCubit';

  Future<void> load({
    required String huntId,
    required int elapsedSeconds,
    required int hintsUsed,
  }) async {
    emit(const HuntCompleteLoading());
    final result = await _huntRepository.fetchHunt(huntId);
    result.fold(
      onSuccess: (hunt) => emit(HuntCompleteLoaded(
        hunt: hunt,
        elapsedSeconds: elapsedSeconds,
        hintsUsed: hintsUsed,
      )),
      onErr: (failure) {
        AppLogger.e('HuntComplete load failed', tag: _tag, error: failure.message);
        emit(HuntCompleteError(failure.userFriendlyMessage));
      },
    );
  }
}
