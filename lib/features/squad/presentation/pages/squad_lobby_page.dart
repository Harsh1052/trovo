import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/models/squad_member_model.dart';
import '../../../../shared/models/squad_session_model.dart';
import '../../../../shared/widgets/hm_button.dart';
import '../../../../shared/widgets/hm_loading.dart';
import '../../bloc/squad_bloc.dart';
import '../../bloc/squad_event.dart';
import '../../bloc/squad_state.dart';

/// Real-time squad lobby page.
///
/// Shows the room code, member list with ready indicators, and
/// start / ready / leave actions.
class SquadLobbyPage extends StatelessWidget {
  const SquadLobbyPage({
    super.key,
    required this.squadId,
    required this.userId,
    required this.displayName,
  });

  final String squadId;
  final String userId;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SquadBloc(squadRepository: sl()),
      child: _SquadLobbyContent(
        squadId: squadId,
        userId: userId,
        displayName: displayName,
      ),
    );
  }
}

class _SquadLobbyContent extends StatefulWidget {
  const _SquadLobbyContent({
    required this.squadId,
    required this.userId,
    required this.displayName,
  });

  final String squadId;
  final String userId;
  final String displayName;

  @override
  State<_SquadLobbyContent> createState() => _SquadLobbyContentState();
}

class _SquadLobbyContentState extends State<_SquadLobbyContent> {
  @override
  void initState() {
    super.initState();
    // Subscribe to the squad session stream via the bloc.
    // The BLoC was created by the parent — we need to join or watch.
    // If we arrived via create → already subscribed. Via join → also subscribed.
    // If we navigated directly (e.g. deep link), we need to join.
    // For now, the lobby relies on the BLoC already being active from
    // CreateSquadPage or JoinSquadPage.
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SquadBloc, SquadState>(
      listener: (context, state) {
        if (state is SquadHuntActive) {
          // Navigate to the active hunt flow.
          context.go(RouteNames.countdownPath(state.session.huntId));
        }
        if (state is SquadDisbanded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.warning,
            ),
          );
          context.go(RouteNames.home);
        }
      },
      builder: (context, state) => switch (state) {
        SquadLobby() => _buildLobby(context, state),
        SquadLoading() => const Scaffold(body: Center(child: HMLoading())),
        SquadError(:final message) => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(message, style: AppTypography.bodyLarge),
            ),
          ),
        _ => const Scaffold(body: Center(child: HMLoading())),
      },
    );
  }

  Widget _buildLobby(BuildContext context, SquadLobby state) {
    final session = state.session;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Squad Lobby'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _showLeaveDialog(context, state),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          child: Column(
            children: [
              // ── Room code card ──────────────────────────────────
              _RoomCodeCard(roomCode: session.roomCode),
              const SizedBox(height: AppDimensions.spaceL),

              // ── Members header ──────────────────────────────────
              Row(
                children: [
                  Text(
                    'Squad Members',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(width: AppDimensions.spaceS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.chipPadding,
                      vertical: AppDimensions.spaceXXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull),
                    ),
                    child: Text(
                      '${session.memberCount}/${SquadSessionModel.maxMembers}',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceM),

              // ── Member list ─────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  itemCount: session.members.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppDimensions.spaceS),
                  itemBuilder: (context, index) {
                    final member = session.members[index];
                    final isCurrentUser = member.userId == state.currentUserId;
                    final isHost = session.isHost(member.userId);
                    return _MemberTile(
                      member: member,
                      isHost: isHost,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                ),
              ),

              // ── Waiting message ────────────────────────────────
              if (!state.canStart && state.isHost)
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: AppDimensions.spaceM),
                  child: Text(
                    session.memberCount < 2
                        ? 'Waiting for teammates to join...'
                        : 'Waiting for all members to be ready...',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),

      // ── Bottom action ──────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          child: state.isHost
              ? HMButton.primary(
                  label: 'Start Hunt 🚀',
                  onPressed: state.canStart
                      ? () => context
                          .read<SquadBloc>()
                          .add(const SquadHuntStarted())
                      : null,
                  icon: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white),
                )
              : HMButton.primary(
                  label: state.isCurrentUserReady
                      ? 'Not Ready'
                      : 'Ready! ✅',
                  onPressed: () => context.read<SquadBloc>().add(
                        SquadReadyToggled(
                          userId: widget.userId,
                          ready: !state.isCurrentUserReady,
                        ),
                      ),
                ),
        ),
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, SquadLobby state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(state.isHost
            ? 'Disband Squad?'
            : 'Leave Squad?'),
        content: Text(state.isHost
            ? 'Leaving as the host will disband the squad for everyone.'
            : 'You will be removed from the squad.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<SquadBloc>()
                  .add(SquadLeft(userId: widget.userId));
              context.go(RouteNames.home);
            },
            child: Text(
              state.isHost ? 'Disband' : 'Leave',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Room Code Card ──────────────────────────────────────────────────────────

class _RoomCodeCard extends StatelessWidget {
  const _RoomCodeCard({required this.roomCode});

  final String roomCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ROOM CODE',
            style: AppTypography.overline.copyWith(
              color: Colors.white70,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            roomCode.split('').join(' '),
            style: AppTypography.displayMedium.copyWith(
              color: Colors.white,
              letterSpacing: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionChip(
                icon: Icons.copy_rounded,
                label: 'Copy',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: roomCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Room code copied!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(width: AppDimensions.spaceM),
              _ActionChip(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: () {
                  Share.share(
                    'Join my HunterMania squad! 🏆\n'
                    'Room Code: $roomCode\n\n'
                    'Download: https://huntermania.app',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceM,
          vertical: AppDimensions.spaceS,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: AppDimensions.spaceXS),
            Text(
              label,
              style: AppTypography.labelMedium
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Member Tile ─────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isHost,
    required this.isCurrentUser,
  });

  final SquadMemberModel member;
  final bool isHost;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.greyLight,
        ),
      ),
      child: Row(
        children: [
          // ── Avatar ────────────────────────────────────────────
          CircleAvatar(
            radius: 22,
            backgroundColor: isHost
                ? AppColors.secondary
                : AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              _initials(member.displayName),
              style: AppTypography.titleSmall.copyWith(
                color: isHost ? AppColors.textOnSecondary : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceM),

          // ── Name + role ───────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.displayName,
                      style: AppTypography.titleSmall,
                    ),
                    if (isCurrentUser)
                      Text(
                        '  (You)',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.primary),
                      ),
                  ],
                ),
                Text(
                  isHost ? '👑 Captain' : '🎯 Hunter',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),

          // ── Ready indicator ───────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.chipPadding + 4,
              vertical: AppDimensions.spaceXS,
            ),
            decoration: BoxDecoration(
              color: member.isReady
                  ? AppColors.successLight
                  : AppColors.greyExtraLight,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              member.isReady ? 'Ready ✅' : 'Waiting...',
              style: AppTypography.labelSmall.copyWith(
                color: member.isReady
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
