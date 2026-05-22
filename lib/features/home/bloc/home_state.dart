import 'package:equatable/equatable.dart';

import '../../../shared/models/hunt_model.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.hunts,
    required this.featuredHunt,
    required this.selectedCity,
    required this.availableCities,
  });

  /// All hunts for the selected city, ordered free-first then by creation date.
  final List<HuntModel> hunts;

  /// The first free hunt — promoted to the hero card.
  /// Null when no free hunts exist for the current filter.
  final HuntModel? featuredHunt;

  /// Active city filter. Empty string means "All Cities" (no filter applied).
  final String selectedCity;

  /// Distinct cities that have at least one active hunt, sorted alphabetically.
  final List<String> availableCities;

  // ── Computed ──────────────────────────────────────────────────────────────

  /// Free hunts in the current result set — used by the "Free" section header.
  List<HuntModel> get freeHunts => hunts.where((h) => h.isFree).toList();

  /// Paid hunts in the current result set — used by the "Paid" section header.
  List<HuntModel> get paidHunts => hunts.where((h) => !h.isFree).toList();

  /// Human-readable label for the city filter chip in the AppBar.
  String get cityLabel =>
      selectedCity.isEmpty ? 'All Cities' : selectedCity;

  // ── copyWith ──────────────────────────────────────────────────────────────

  HomeLoaded copyWith({
    List<HuntModel>? hunts,
    HuntModel? featuredHunt,
    String? selectedCity,
    List<String>? availableCities,
  }) =>
      HomeLoaded(
        hunts: hunts ?? this.hunts,
        // Explicit null clears the featured hunt (e.g. no free hunts in city).
        featuredHunt: featuredHunt ?? this.featuredHunt,
        selectedCity: selectedCity ?? this.selectedCity,
        availableCities: availableCities ?? this.availableCities,
      );

  @override
  List<Object?> get props =>
      [hunts, featuredHunt, selectedCity, availableCities];
}

final class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
