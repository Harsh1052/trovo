part of 'paywall_cubit.dart';

sealed class PaywallState extends Equatable {
  const PaywallState();

  @override
  List<Object?> get props => [];
}

final class PaywallInitial extends PaywallState {
  const PaywallInitial();
}

final class PaywallLoading extends PaywallState {
  const PaywallLoading();
}

final class PaywallPurchaseSuccess extends PaywallState {
  const PaywallPurchaseSuccess();
}

final class PaywallRestoreSuccess extends PaywallState {
  const PaywallRestoreSuccess();
}

final class PaywallError extends PaywallState {
  const PaywallError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
