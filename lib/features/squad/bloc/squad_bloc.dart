import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/result.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/squad_session_model.dart';
import '../../../shared/repositories/squad_repository.dart';
import 'squad_event.dart';
import 'squad_state.dart';

/// Manages the lifecycle of a squad multiplayer session.
///
/// Subscribes to a Firestore real-time stream once a squad is created or
/// joined, and emits [SquadLobby] / [SquadHuntActive] / [SquadDisbanded]
/// states as the session evolves.
class SquadBloc extends Bloc<SquadEvent, SquadState> {
  SquadBloc({required SquadRepository squadRepository})
      : _squadRepository = squadRepository,
        super(const SquadInitial()) {
    on<SquadCreateRequested>(_onCreateRequested);
    on<SquadJoinRequested>(_onJoinRequested);
    on<SquadSessionUpdated>(_onSessionUpdated);
    on<SquadReadyToggled>(_onReadyToggled);
    on<SquadHuntStarted>(_onHuntStarted);
    on<SquadLeft>(_onLeft);
    on<SquadLocationSynced>(_onLocationSynced);
  }

  final SquadRepository _squadRepository;
  StreamSubscription<SquadSessionModel>? _squadSubscription;
  String _currentSquadId = '';
  String _currentUserId = '';
  static const _tag = 'SquadBloc';

  // ── Create ────────────────────────────────────────────────────────────────

  Future<void> _onCreateRequested(
    SquadCreateRequested event,
    Emitter<SquadState> emit,
  ) async {
    emit(const SquadLoading());
    _currentUserId = event.hostUserId;

    final result = await _squadRepository.createSquad(
      huntId: event.huntId,
      hostUserId: event.hostUserId,
      hostDisplayName: event.hostDisplayName,
    );

    switch (result) {
      case Success(:final data):
        _currentSquadId = data.squadId;
        _subscribeToSquad(data.squadId);
        emit(SquadLobby(session: data, currentUserId: _currentUserId));
      case Err(:final failure):
        AppLogger.e('Create squad failed', tag: _tag, error: failure.message);
        emit(SquadError(failure.userFriendlyMessage));
    }
  }

  // ── Join ───────────────────────────────────────────────────────────────────

  Future<void> _onJoinRequested(
    SquadJoinRequested event,
    Emitter<SquadState> emit,
  ) async {
    emit(const SquadLoading());
    _currentUserId = event.userId;

    final result = await _squadRepository.joinSquad(
      roomCode: event.roomCode,
      userId: event.userId,
      displayName: event.displayName,
    );

    switch (result) {
      case Success(:final data):
        _currentSquadId = data.squadId;
        _subscribeToSquad(data.squadId);
        emit(SquadLobby(session: data, currentUserId: _currentUserId));
      case Err(:final failure):
        AppLogger.e('Join squad failed', tag: _tag, error: failure.message);
        emit(SquadError(failure.userFriendlyMessage));
    }
  }

  // ── Real-time updates ─────────────────────────────────────────────────────

  void _subscribeToSquad(String squadId) {
    _squadSubscription?.cancel();
    _squadSubscription = _squadRepository.watchSquad(squadId).listen(
      (session) => add(SquadSessionUpdated(session)),
      onError: (Object error) {
        AppLogger.e('Squad stream error', tag: _tag, error: error);
        add(const SquadSessionUpdated(null));
      },
    );
  }

  void _onSessionUpdated(
    SquadSessionUpdated event,
    Emitter<SquadState> emit,
  ) {
    final session = event.session;

    if (session == null || session is! SquadSessionModel) {
      emit(const SquadDisbanded());
      return;
    }

    // TTL check: if inactive for 4+ hours, treat as disbanded.
    if (session.isExpired()) {
      emit(const SquadDisbanded(
        message: 'Session expired due to inactivity.',
      ));
      return;
    }

    switch (session.status) {
      case SquadStatus.lobby:
        emit(SquadLobby(session: session, currentUserId: _currentUserId));
      case SquadStatus.active:
        emit(SquadHuntActive(session: session, currentUserId: _currentUserId));
      case SquadStatus.completed:
        // Check if current user is still a member.
        final isMember = session.memberById(_currentUserId) != null;
        if (!isMember && session.members.isNotEmpty) {
          emit(const SquadDisbanded(
            message: 'You have been removed from the squad.',
          ));
        } else {
          emit(const SquadDisbanded());
        }
    }
  }

  // ── Ready toggle ──────────────────────────────────────────────────────────

  Future<void> _onReadyToggled(
    SquadReadyToggled event,
    Emitter<SquadState> emit,
  ) async {
    final result = await _squadRepository.setReady(
      squadId: _currentSquadId,
      userId: event.userId,
      ready: event.ready,
    );

    if (result case Err(:final failure)) {
      AppLogger.e('Ready toggle failed', tag: _tag, error: failure.message);
    }
    // No emit needed — the Firestore stream will push the update.
  }

  // ── Start hunt ────────────────────────────────────────────────────────────

  Future<void> _onHuntStarted(
    SquadHuntStarted event,
    Emitter<SquadState> emit,
  ) async {
    final result = await _squadRepository.startSquadHunt(_currentSquadId);

    if (result case Err(:final failure)) {
      AppLogger.e('Start hunt failed', tag: _tag, error: failure.message);
      // Show error on current lobby state.
      if (state is SquadLobby) {
        emit(SquadError(failure.userFriendlyMessage));
      }
    }
    // Success → the stream will emit SquadHuntActive automatically.
  }

  // ── Leave ─────────────────────────────────────────────────────────────────

  Future<void> _onLeft(
    SquadLeft event,
    Emitter<SquadState> emit,
  ) async {
    await _squadSubscription?.cancel();
    _squadSubscription = null;

    final result = await _squadRepository.leaveSquad(
      squadId: _currentSquadId,
      userId: event.userId,
    );

    switch (result) {
      case Success():
        emit(const SquadInitial());
      case Err(:final failure):
        AppLogger.e('Leave squad failed', tag: _tag, error: failure.message);
        emit(SquadError(failure.userFriendlyMessage));
    }
  }

  // ── Location sync ─────────────────────────────────────────────────────────

  Future<void> _onLocationSynced(
    SquadLocationSynced event,
    Emitter<SquadState> emit,
  ) async {
    // Fire-and-forget — don't block the UI on location updates.
    await _squadRepository.updateMemberLocation(
      squadId: _currentSquadId,
      userId: event.userId,
      latitude: event.latitude,
      longitude: event.longitude,
    );
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  @override
  Future<void> close() async {
    await _squadSubscription?.cancel();
    return super.close();
  }
}
