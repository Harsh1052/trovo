import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/result.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/hunt_model.dart';
import '../../../shared/repositories/hunt_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required HuntRepository huntRepository})
      : _huntRepository = huntRepository,
        super(const HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeCityChanged>(_onCityChanged);
    on<HomeRefreshRequested>(_onRefresh);
  }

  final HuntRepository _huntRepository;
  static const _tag = 'HomeBloc';

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    await _fetchAndEmit(emit, city: event.city);
  }

  Future<void> _onCityChanged(
    HomeCityChanged event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    await _fetchAndEmit(emit, city: event.city);
  }

  Future<void> _onRefresh(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    // Re-use the last known city filter; fall back to "all" on initial state.
    final currentCity =
        state is HomeLoaded ? (state as HomeLoaded).selectedCity : '';
    await _fetchAndEmit(emit, city: currentCity);
  }

  // ── Core fetch ────────────────────────────────────────────────────────────

  /// Fetches hunts and available cities in parallel, then emits the appropriate
  /// state. Empty [city] means no filter (all cities).
  Future<void> _fetchAndEmit(
    Emitter<HomeState> emit, {
    required String city,
  }) async {
    // Empty string sentinel → no Firestore city filter.
    final cityFilter = city.isEmpty ? null : city;

    // Parallel fetch using Dart 3 record .wait — both requests fly simultaneously.
    final (huntsResult, citiesResult) = await (
      _huntRepository.fetchHunts(city: cityFilter),
      _huntRepository.getAvailableCities(),
    ).wait;

    if (huntsResult case Err(:final failure)) {
      AppLogger.e('HomeBloc fetch failed', tag: _tag, error: failure.message);
      emit(HomeError(failure.userFriendlyMessage));
      return;
    }

    final hunts = (huntsResult as Success<List<HuntModel>>).data;

    // Cities failure is non-fatal: degrade gracefully without a city picker.
    final availableCities = citiesResult.dataOrNull ?? const <String>[];

    emit(HomeLoaded(
      hunts: hunts,
      // The featured hunt is the first free hunt — the hero card in the UI.
      featuredHunt: hunts.where((h) => h.isFree).firstOrNull,
      selectedCity: city,
      availableCities: availableCities,
    ));
  }
}
