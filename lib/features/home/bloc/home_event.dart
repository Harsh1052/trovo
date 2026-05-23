import 'package:equatable/equatable.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Load hunts for [city]. Pass an empty string to load all cities (no filter).
final class HomeLoadRequested extends HomeEvent {
  const HomeLoadRequested(this.city);

  final String city;

  @override
  List<Object?> get props => [city];
}

/// User picked a different city from the selector sheet.
final class HomeCityChanged extends HomeEvent {
  const HomeCityChanged(this.city);

  /// Empty string means "All Cities" (no filter applied).
  final String city;

  @override
  List<Object?> get props => [city];
}

final class HomeRefreshRequested extends HomeEvent {
  const HomeRefreshRequested();
}
