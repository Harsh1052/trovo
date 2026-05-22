import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/error/result.dart';
import '../../../core/utils/gps_utils.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/hunt_progress_model.dart';
import '../../../shared/repositories/hunt_repository.dart';
import '../../../shared/repositories/progress_repository.dart';
import '../../../shared/services/analytics_service.dart';
import '../../../shared/services/location_service.dart';
import 'active_hunt_event.dart';
import 'active_hunt_state.dart';

class ActiveHuntBloc extends Bloc<ActiveHuntEvent, ActiveHuntState> {
  ActiveHuntBloc({
    required HuntRepository huntRepository,
    required ProgressRepository progressRepository,
    required LocationService locationService,
    required AnalyticsService analyticsService,
  })  : _huntRepository = huntRepository,
        _progressRepository = progressRepository,
        _locationService = locationService,
        _analyticsService = analyticsService,
        super(const ActiveHuntInitial()) {
    on<ActiveHuntStarted>(_onStarted);
    on<ActiveHuntResumed>(_onResumed);
    on<ActiveHuntLocationUpdated>(_onLocationUpdated);
    on<ActiveHuntCheckpointAnswerSubmitted>(_onAnswerSubmitted);
    on<ActiveHuntHintRequested>(_onHintRequested);
    on<ActiveHuntPhotoSubmitted>(_onPhotoSubmitted);
    on<ActiveHuntTimerTicked>(_onTimerTicked);
    on<ActiveHuntMapToggled>(_onMapToggled);
    on<ActiveHuntAbandoned>(_onAbandoned);
    on<ActiveHuntLocationRetried>(_onLocationRetried);
  }

  final HuntRepository _huntRepository;
  final ProgressRepository _progressRepository;
  final LocationService _locationService;
  final AnalyticsService _analyticsService;

  Timer? _timer;
  StreamSubscription? _locationSubscription;
  static const _tag = 'ActiveHuntBloc';

  // ── Event handlers ────────────────────────────────────────────────────────

  Future<void> _onStarted(
      ActiveHuntStarted event, Emitter<ActiveHuntState> emit) async {
    emit(const ActiveHuntLoading());

    // Fetch hunt metadata and checkpoints in parallel.
    final (huntResult, checkpointsResult) = await (
      _huntRepository.fetchHunt(event.huntId),
      _huntRepository.fetchCheckpoints(event.huntId),
    ).wait;

    if (huntResult case Err(:final failure)) {
      AppLogger.e('ActiveHunt: fetch hunt failed',
          tag: _tag, error: failure.message);
      emit(ActiveHuntError(failure.userFriendlyMessage));
      return;
    }
    if (checkpointsResult case Err(:final failure)) {
      AppLogger.e('ActiveHunt: fetch checkpoints failed',
          tag: _tag, error: failure.message);
      emit(ActiveHuntError(failure.userFriendlyMessage));
      return;
    }

    final progressResult =
        await _progressRepository.startHunt(event.userId, event.huntId);
    if (progressResult case Err(:final failure)) {
      AppLogger.e('ActiveHunt: start hunt failed',
          tag: _tag, error: failure.message);
      emit(ActiveHuntError(failure.userFriendlyMessage));
      return;
    }

    final hunt = (huntResult as Success).data;
    final checkpoints = (checkpointsResult as Success).data;
    final progress = (progressResult as Success).data;

    // 3 → 2 → 1 countdown; each tick is 1 second.
    for (int i = 3; i > 0; i--) {
      emit(ActiveHuntCountdown(hunt: hunt, secondsLeft: i));
      await Future.delayed(const Duration(seconds: 1));
    }

    emit(ActiveHuntInProgress(
      hunt: hunt,
      checkpoints: checkpoints,
      progress: progress,
      elapsed: Duration.zero,
    ));

    _startTimer();
    await _startLocationTracking(
      emit,
      huntId: event.huntId,
      userId: event.userId,
    );

    await _analyticsService.logHuntStarted(hunt.huntId, hunt.title);
  }

  Future<void> _onResumed(
      ActiveHuntResumed event, Emitter<ActiveHuntState> emit) async {
    emit(const ActiveHuntLoading());

    final (huntResult, checkpointsResult) = await (
      _huntRepository.fetchHunt(event.huntId),
      _huntRepository.fetchCheckpoints(event.huntId),
    ).wait;

    if (huntResult case Err(:final failure)) {
      emit(ActiveHuntError(failure.userFriendlyMessage));
      return;
    }
    if (checkpointsResult case Err(:final failure)) {
      emit(ActiveHuntError(failure.userFriendlyMessage));
      return;
    }

    final progressResult =
        await _progressRepository.fetchProgress(event.userId, event.huntId);
    if (progressResult case Err(:final failure)) {
      emit(ActiveHuntError(failure.userFriendlyMessage));
      return;
    }

    final fetchedProgress = (progressResult as Success).data;
    HuntProgressModel progress;

    if (fetchedProgress == null || !fetchedProgress.isActive) {
      // Missing progress doc means they UI skipped ActiveHuntStarted or cleared it. Auto-fix.
      final startResult = await _progressRepository.startHunt(event.userId, event.huntId);
      if (startResult case Err(:final failure)) {
        emit(ActiveHuntError(failure.userFriendlyMessage));
        return;
      }
      progress = (startResult as Success).data;
    } else {
      progress = fetchedProgress;
    }

    final hunt = (huntResult as Success).data;
    final checkpoints = (checkpointsResult as Success).data;

    // Reconstruct elapsed time from the persisted startedAt timestamp.
    final elapsed = DateTime.now().difference(progress.startedAt);

    emit(ActiveHuntInProgress(
      hunt: hunt,
      checkpoints: checkpoints,
      progress: progress,
      elapsed: elapsed,
    ));

    _startTimer();
    await _startLocationTracking(
      emit,
      huntId: event.huntId,
      userId: event.userId,
    );
  }

  void _onLocationUpdated(
      ActiveHuntLocationUpdated event, Emitter<ActiveHuntState> emit) {
    if (state is! ActiveHuntInProgress) return;
    final current = state as ActiveHuntInProgress;
    final checkpoint = current.currentCheckpoint;

    final distance = GpsUtils.distanceInMetres(
      event.latitude,
      event.longitude,
      checkpoint.latitude,
      checkpoint.longitude,
    );
    final isWithin =
        distance <= checkpoint.unlockRadius.toDouble();

    emit(current.copyWith(
      currentLat: event.latitude,
      currentLng: event.longitude,
      distanceToCheckpoint: distance,
      isWithinRange: isWithin,
    ));
  }

  Future<void> _onAnswerSubmitted(
      ActiveHuntCheckpointAnswerSubmitted event,
      Emitter<ActiveHuntState> emit) async {
    if (state is! ActiveHuntInProgress) return;
    final current = state as ActiveHuntInProgress;
    final checkpoint = current.currentCheckpoint;

    final isCorrect = event.answer.trim().toLowerCase() ==
        (checkpoint.answer?.trim().toLowerCase() ?? '');

    if (!isCorrect) {
      emit(current.copyWith(isAnswerWrong: true));
      await Future.delayed(const Duration(milliseconds: 600));
      emit(current.copyWith(isAnswerWrong: false));
      return;
    }

    // TODO(prod): Re-enable proximity guard before production release.
    // if (!current.isWithinRange) {
    //   emit(current.copyWith(
    //       feedbackMessage: 'Get closer to the location!'));
    //   await Future.delayed(const Duration(seconds: 2));
    //   emit(current.copyWith(feedbackMessage: null));
    //   return;
    // }

    await _advanceCheckpoint(current, emit);
  }

  Future<void> _onPhotoSubmitted(
      ActiveHuntPhotoSubmitted event, Emitter<ActiveHuntState> emit) async {
    if (state is! ActiveHuntInProgress) return;
    final current = state as ActiveHuntInProgress;

    // TODO(prod): Re-enable proximity guard before production release.
    // if (!current.isWithinRange) {
    //   emit(current.copyWith(
    //       feedbackMessage: 'Get closer to the location!'));
    //   await Future.delayed(const Duration(seconds: 2));
    //   emit(current.copyWith(feedbackMessage: null));
    //   return;
    // }

    await _advanceCheckpoint(current, emit);
  }

  Future<void> _onHintRequested(
      ActiveHuntHintRequested event, Emitter<ActiveHuntState> emit) async {
    if (state is! ActiveHuntInProgress) return;
    final current = state as ActiveHuntInProgress;

    // No hint configured for this checkpoint.
    if (current.currentCheckpoint.hintText.isEmpty) return;

    // Hint already revealed for this checkpoint.
    if (current.hintRevealed) return;

    // Global hint limit reached.
    if (current.hintsUsed >= current.maxHints) {
      emit(current.copyWith(feedbackMessage: 'No hints remaining!'));
      await Future.delayed(const Duration(milliseconds: 1500));
      emit(current.copyWith(feedbackMessage: null));
      return;
    }

    _analyticsService.logHintUsed(
        current.hunt.huntId, current.currentCheckpointIndex);

    final updatedProgress =
        current.progress.copyWith(hintsUsed: current.hintsUsed + 1);

    // Persist hint usage — non-fatal if it fails.
    final saveResult = await _progressRepository.saveProgress(updatedProgress);
    if (saveResult case Err(:final failure)) {
      AppLogger.w('ActiveHunt: failed to save hint usage',
          tag: _tag, error: failure.message);
    }

    emit(current.copyWith(
      hintRevealed: true,
      progress: updatedProgress,
    ));
  }

  void _onTimerTicked(
      ActiveHuntTimerTicked event, Emitter<ActiveHuntState> emit) {
    if (state is! ActiveHuntInProgress) return;
    final current = state as ActiveHuntInProgress;
    emit(current.copyWith(
        elapsed: current.elapsed + const Duration(seconds: 1)));
  }

  void _onMapToggled(
      ActiveHuntMapToggled event, Emitter<ActiveHuntState> emit) {
    if (state is! ActiveHuntInProgress) return;
    final current = state as ActiveHuntInProgress;
    emit(current.copyWith(showMap: !current.showMap));
  }

  Future<void> _onAbandoned(
      ActiveHuntAbandoned event, Emitter<ActiveHuntState> emit) async {
    if (state is ActiveHuntInProgress) {
      final current = state as ActiveHuntInProgress;

      await _analyticsService.logHuntAbandoned(
        huntId: current.hunt.huntId,
        checkpointIndex: current.currentCheckpointIndex,
        elapsedSeconds: current.elapsed.inSeconds,
      );

      final abandoned =
          current.progress.copyWith(status: HuntStatus.abandoned);
      await _progressRepository.saveProgress(abandoned);
    }
    _stopTracking();
  }

  // ── Core checkpoint advance ───────────────────────────────────────────────

  /// Unlocks the current checkpoint and either advances to the next or
  /// completes the hunt.
  Future<void> _advanceCheckpoint(
      ActiveHuntInProgress current, Emitter<ActiveHuntState> emit) async {
    final completedIndex = current.currentCheckpointIndex;
    final nextIndex = completedIndex + 1;
    final newTimestamps = {
      ...current.progress.checkpointTimestamps,
      current.currentCheckpoint.checkpointId: DateTime.now(),
    };

    await _analyticsService.logCheckpointUnlocked(
      huntId: current.hunt.huntId,
      checkpointIndex: completedIndex,
    );

    // ── Hunt completed ────────────────────────────────────────────────────
    if (nextIndex >= current.checkpoints.length) {
      final finalProgress = current.progress.copyWith(
        status: HuntStatus.completed,
        completedAt: DateTime.now(),
        checkpointTimestamps: newTimestamps,
      );

      final saveResult = await _progressRepository.saveProgress(finalProgress);
      if (saveResult case Err(:final failure)) {
        AppLogger.e('ActiveHunt: save final progress failed',
            tag: _tag, error: failure.message);
        // Non-fatal: show completion screen regardless.
      }

      _stopTracking();

      await _analyticsService.logHuntCompleted(
        huntId: current.hunt.huntId,
        elapsedSeconds: current.elapsed.inSeconds,
        hintsUsed: finalProgress.hintsUsed,
      );

      emit(ActiveHuntCompleted(
        progress: finalProgress,
        totalTime: current.elapsed,
        hintsUsed: finalProgress.hintsUsed,
      ));
      return;
    }

    // ── Checkpoint unlocked, more to go ───────────────────────────────────
    final nextCheckpoint = current.checkpoints[nextIndex];

    emit(ActiveHuntCheckpointUnlocked(
      checkpointIndex: completedIndex,
      totalCheckpoints: current.checkpoints.length,
      nextCheckpoint: nextCheckpoint,
    ));

    // Celebration screen auto-dismisses after 2 seconds.
    await Future.delayed(const Duration(seconds: 2));

    final updatedProgress = current.progress.copyWith(
      currentCheckpointIndex: nextIndex,
      checkpointTimestamps: newTimestamps,
    );

    final saveResult = await _progressRepository.saveProgress(updatedProgress);
    if (saveResult case Err(:final failure)) {
      AppLogger.e('ActiveHunt: save progress failed',
          tag: _tag, error: failure.message);
      // Non-fatal: continue with in-memory progress.
    }

    emit(current.copyWith(
      progress: updatedProgress,
      hintRevealed: false,
      isAnswerWrong: false,
      feedbackMessage: null,
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const ActiveHuntTimerTicked()),
    );
  }

  /// Checks location permission before starting the GPS stream.
  ///
  /// If denied → emits [ActiveHuntLocationDenied] so the UI can show the
  /// permission-denied screen with contextual CTA.
  Future<void> _startLocationTracking(
      Emitter<ActiveHuntState> emit, {
      required String huntId,
      required String userId,
  }) async {
    final hasPermission = await _locationService.requestPermission();

    if (!hasPermission) {
      // Distinguish "denied" from "permanently denied".
      final permission = await Geolocator.checkPermission();
      final isPermanent = permission == LocationPermission.deniedForever;

      AppLogger.w(
        'Location permission denied (permanent: $isPermanent)',
        tag: _tag,
      );

      emit(ActiveHuntLocationDenied(
        huntId: huntId,
        userId: userId,
        isPermanentlyDenied: isPermanent,
      ));
      return;
    }

    _locationSubscription?.cancel();
    _locationSubscription =
        _locationService.startTrackingForHunt().listen((position) {
      add(ActiveHuntLocationUpdated(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    });
  }

  /// Handles the retry from the permission-denied screen.
  ///
  /// Re-requests permission and, if granted, re-dispatches the
  /// [ActiveHuntResumed] event to reload hunt data and start tracking.
  Future<void> _onLocationRetried(
      ActiveHuntLocationRetried event, Emitter<ActiveHuntState> emit) async {
    if (state is! ActiveHuntLocationDenied) return;
    final denied = state as ActiveHuntLocationDenied;

    if (denied.isPermanentlyDenied) {
      await Geolocator.openAppSettings();
      return;
    }

    // Re-trigger the full hunt resume flow (which will re-check permission).
    add(ActiveHuntResumed(
      huntId: denied.huntId,
      userId: denied.userId,
    ));
  }

  void _stopTracking() {
    _timer?.cancel();
    _timer = null;
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationService.stopTracking();
  }

  @override
  Future<void> close() {
    _stopTracking();
    return super.close();
  }
}
