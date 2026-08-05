import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_state.dart';
import '../../../../shared/models/league_member_model.dart';
import '../../../../shared/widgets/hm_loading.dart';
import '../../bloc/leaderboard_bloc.dart';
import '../../bloc/leaderboard_event.dart';
import '../../bloc/leaderboard_state.dart';
import '../widgets/guardian_card.dart';

class LeaderboardHubPage extends StatelessWidget {
  const LeaderboardHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';

    return BlocProvider(
      create: (_) => LeaderboardBloc(leaderboardRepository: sl())
        ..add(LeaderboardLoadRequested(userId: userId)),
      child: const _LeaderboardHubContent(),
    );
  }
}

class _LeaderboardHubContent extends StatefulWidget {
  const _LeaderboardHubContent();

  @override
  State<_LeaderboardHubContent> createState() => _LeaderboardHubContentState();
}

class _LeaderboardHubContentState extends State<_LeaderboardHubContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('City Rivals & Leagues 🏆'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: AppColors.textPrimary,
          tabs: const [
            Tab(icon: Icon(Icons.castle_rounded), text: 'City Guardians 👑'),
            Tab(icon: Icon(Icons.bolt_rounded), text: 'Weekly League ⚡'),
          ],
        ),
      ),
      body: BlocBuilder<LeaderboardBloc, LeaderboardState>(
        builder: (context, state) => switch (state) {
          LeaderboardInitial() ||
          LeaderboardLoading() =>
            const Center(child: HMLoading()),
          LeaderboardError(:final message) => Center(
              child: Text(message, style: AppTypography.bodyLarge),
            ),
          LeaderboardLoaded() => TabBarView(
              controller: _tabController,
              children: [
                _GuardiansTab(state: state),
                _WeeklyLeagueTab(state: state),
              ],
            ),
        },
      ),
    );
  }
}

class _GuardiansTab extends StatelessWidget {
  const _GuardiansTab({required this.state});

  final LeaderboardLoaded state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      children: [
        // ── XP Rank Summary ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppDimensions.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Text('🕵️‍♂️', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.userRank.rankTitle,
                      style: AppTypography.titleLarge
                          .copyWith(color: Colors.white),
                    ),
                    Text(
                      'Total XP: ${state.userRank.totalXp} XP • ${state.userRank.guardianshipsHeld} Guardianships',
                      style: AppTypography.bodySmall
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),

        Text('City Landmark Guardians (Surat)', style: AppTypography.titleMedium),
        const SizedBox(height: AppDimensions.spaceS),

        if (state.guardians.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXL),
            child: Center(
              child: Text(
                'No Guardians crowned yet.\nBe the first to complete a hunt to claim a landmark!',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.guardians.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppDimensions.spaceM),
            itemBuilder: (context, index) {
              final g = state.guardians[index];
              return GuardianCard(
                guardian: g,
                huntTitle: 'Landmark #${index + 1}',
              );
            },
          ),
      ],
    );
  }
}

class _WeeklyLeagueTab extends StatelessWidget {
  const _WeeklyLeagueTab({required this.state});

  final LeaderboardLoaded state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      children: [
        // ── League Header Banner ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppDimensions.cardPadding),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondaryDark, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Emerald League 💎',
                    style: AppTypography.headlineSmall
                        .copyWith(color: AppColors.textOnSecondary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.chipPadding,
                      vertical: AppDimensions.spaceXXS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Builder(
                      builder: (context) {
                        final now = DateTime.now();
                        final daysUntilSunday = DateTime.sunday - now.weekday;
                        final remaining = daysUntilSunday <= 0 ? 7 : daysUntilSunday;
                        return Text(
                          'Resets in $remaining day${remaining == 1 ? '' : 's'}',
                          style: AppTypography.labelSmall
                              .copyWith(color: Colors.white),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceXS),
              Text(
                'Top 3 hunters promote to Diamond League at Sunday midnight!',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textOnSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),

        Text('20-Player League Cohort Standings', style: AppTypography.titleMedium),
        const SizedBox(height: AppDimensions.spaceS),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.leagueStandings.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppDimensions.spaceS),
          itemBuilder: (context, index) {
            final member = state.leagueStandings[index];
            final isTop3 = member.zone == PromotionZone.promotion;

            return Container(
              padding: const EdgeInsets.all(AppDimensions.cardPadding),
              decoration: BoxDecoration(
                color: isTop3
                    ? AppColors.secondary.withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color: isTop3 ? AppColors.secondary : AppColors.greyLight,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '#${member.rankPosition}',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isTop3 ? AppColors.secondaryDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(
                    child: Text(
                      member.displayName,
                      style: AppTypography.titleSmall,
                    ),
                  ),
                  Text(
                    '${member.weeklyXp} XP',
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.primary),
                  ),
                  if (isTop3) ...[
                    const SizedBox(width: AppDimensions.spaceS),
                    const Icon(Icons.arrow_upward_rounded,
                        color: AppColors.success, size: 18),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
