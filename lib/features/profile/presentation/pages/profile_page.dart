import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/hm_error_widget.dart';
import '../../../../shared/widgets/hm_loading.dart';
import '../../bloc/profile_cubit.dart';
import '../widgets/completed_hunt_tile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(
        authRepository: sl(),
        progressRepository: sl(),
        huntRepository: sl(),
      )..load(),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => switch (state) {
          ProfileInitial() || ProfileLoading() => const Scaffold(
              body: Center(child: HMLoading()),
            ),
          ProfileError(:final message) => Scaffold(
              appBar: AppBar(title: const Text('Profile')),
              body: HMErrorWidget(
                message: message,
                onRetry: () => context.read<ProfileCubit>().load(),
              ),
            ),
          ProfileLoaded() => _ProfileContent(state: state),
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.state});

  final ProfileLoaded state;

  @override
  Widget build(BuildContext context) {
    final user = state.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<ProfileCubit>().signOut();
              if (context.mounted) context.go(RouteNames.login);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppDimensions.pagePadding),
            color: AppColors.primary.withValues(alpha: 0.06),
            child: Row(
              children: [
                CircleAvatar(
                  radius: AppDimensions.avatarSizeM / 2,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: AppTypography.headlineSmall
                        .copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName.isNotEmpty
                            ? user.displayName
                            : 'Explorer',
                        style: AppTypography.titleLarge,
                      ),
                      if (user.email != null)
                        Text(user.email!,
                            style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Stats row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppDimensions.pagePadding),
            child: Row(
              children: [
                _StatPill(
                  value: '${state.completedHunts.length}',
                  label: 'Completed',
                ),
                const SizedBox(width: AppDimensions.spaceM),
                _StatPill(
                  value: user.purchasedHunts.isNotEmpty ? 'Hunter' : 'Explorer',
                  label: 'Plan',
                  color: user.purchasedHunts.isNotEmpty
                      ? AppColors.secondary
                      : AppColors.greyLight,
                ),
              ],
            ),
          ),

          // ── Completed hunts ───────────────────────────────────────────────
          if (state.completedHunts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePadding),
              child: Text('Completed Hunts',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            ...state.completedHunts.asMap().entries.map(
                  (e) => CompletedHuntTile(
                    hunt: e.value,
                    progress: state.completedProgress[e.key],
                  ),
                ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.pagePadding),
                child: Text(
                  'No completed hunts yet.\nHead out and explore!',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.value,
    required this.label,
    this.color,
  });

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceS,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style:
                  AppTypography.titleLarge.copyWith(color: c)),
          Text(label,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
