part of 'hunt_complete_cubit.dart';

sealed class HuntCompleteState extends Equatable {
  const HuntCompleteState();

  @override
  List<Object?> get props => [];
}

final class HuntCompleteInitial extends HuntCompleteState {
  const HuntCompleteInitial();
}

final class HuntCompleteLoading extends HuntCompleteState {
  const HuntCompleteLoading();
}

final class HuntCompleteLoaded extends HuntCompleteState {
  const HuntCompleteLoaded({
    required this.hunt,
    required this.elapsedSeconds,
    required this.hintsUsed,
  });

  final HuntModel hunt;
  final int elapsedSeconds;
  final int hintsUsed;

  @override
  List<Object?> get props => [hunt, elapsedSeconds, hintsUsed];
}

final class HuntCompleteError extends HuntCompleteState {
  const HuntCompleteError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
