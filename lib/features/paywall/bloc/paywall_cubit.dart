import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/result.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/repositories/payment_repository.dart';

part 'paywall_state.dart';

class PaywallCubit extends Cubit<PaywallState> {
  PaywallCubit({required PaymentRepository paymentRepository})
      : _paymentRepository = paymentRepository,
        super(const PaywallInitial());

  final PaymentRepository _paymentRepository;
  static const _tag = 'PaywallCubit';

  Future<void> purchase(String productId) async {
    emit(const PaywallLoading());
    final result = await _paymentRepository.purchaseHunt(productId);
    result.fold(
      onSuccess: (_) => emit(const PaywallPurchaseSuccess()),
      onErr: (failure) {
        AppLogger.e('Purchase failed', tag: _tag, error: failure.message);
        emit(PaywallError(failure.userFriendlyMessage));
      },
    );
  }

  Future<void> purchasePremium(String productId) async {
    emit(const PaywallLoading());
    final result = await _paymentRepository.purchasePremium(productId);
    result.fold(
      onSuccess: (_) => emit(const PaywallPurchaseSuccess()),
      onErr: (failure) {
        AppLogger.e('Premium purchase failed', tag: _tag, error: failure.message);
        emit(PaywallError(failure.userFriendlyMessage));
      },
    );
  }

  Future<void> restore() async {
    emit(const PaywallLoading());
    final result = await _paymentRepository.restorePurchases();
    result.fold(
      onSuccess: (_) => emit(const PaywallRestoreSuccess()),
      onErr: (failure) {
        AppLogger.e('Restore failed', tag: _tag, error: failure.message);
        emit(PaywallError(failure.userFriendlyMessage));
      },
    );
  }
}
