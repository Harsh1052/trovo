import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/result.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/checkpoint_model.dart';
import '../../../shared/models/hunt_model.dart';
import '../../../shared/repositories/hunt_repository.dart';
import '../../../shared/repositories/payment_repository.dart';

part 'hunt_detail_state.dart';

class HuntDetailCubit extends Cubit<HuntDetailState> {
  HuntDetailCubit({
    required HuntRepository huntRepository,
    required PaymentRepository paymentRepository,
  })  : _huntRepository = huntRepository,
        _paymentRepository = paymentRepository,
        super(const HuntDetailInitial());

  final HuntRepository _huntRepository;
  final PaymentRepository _paymentRepository;
  static const _tag = 'HuntDetailCubit';

  Future<void> load(String huntId) async {
    emit(const HuntDetailLoading());

    final huntResult = await _huntRepository.fetchHunt(huntId);
    if (huntResult case Err(:final failure)) {
      AppLogger.e('HuntDetail: fetch hunt failed', tag: _tag, error: failure.message);
      emit(HuntDetailError(failure.userFriendlyMessage));
      return;
    }

    final checkpointsResult = await _huntRepository.fetchCheckpoints(huntId);
    if (checkpointsResult case Err(:final failure)) {
      AppLogger.e('HuntDetail: fetch checkpoints failed', tag: _tag, error: failure.message);
      emit(HuntDetailError(failure.userFriendlyMessage));
      return;
    }

    final hunt = (huntResult as Success).data;
    final checkpoints = (checkpointsResult as Success).data;

    // For free hunts skip the entitlement check entirely.
    bool hasAccess = true;
    if (!hunt.isFree) {
      final accessResult = await _paymentRepository.hasHuntAccess(huntId);
      hasAccess = accessResult.dataOrNull ?? false;
    }

    emit(HuntDetailLoaded(
      hunt: hunt,
      checkpoints: checkpoints,
      hasAccess: hasAccess,
    ));
  }
}
