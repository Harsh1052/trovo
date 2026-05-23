part of 'hunt_detail_cubit.dart';

sealed class HuntDetailState extends Equatable {
  const HuntDetailState();

  @override
  List<Object?> get props => [];
}

final class HuntDetailInitial extends HuntDetailState {
  const HuntDetailInitial();
}

final class HuntDetailLoading extends HuntDetailState {
  const HuntDetailLoading();
}

final class HuntDetailLoaded extends HuntDetailState {
  const HuntDetailLoaded({
    required this.hunt,
    required this.checkpoints,
    required this.hasAccess,
  });

  final HuntModel hunt;
  final List<CheckpointModel> checkpoints;
  final bool hasAccess;

  @override
  List<Object?> get props => [hunt, checkpoints, hasAccess];
}

final class HuntDetailError extends HuntDetailState {
  const HuntDetailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
