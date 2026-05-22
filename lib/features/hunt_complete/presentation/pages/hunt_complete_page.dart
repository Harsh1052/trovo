import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/hm_button.dart';
import '../../../../shared/widgets/hm_loading.dart';
import '../../bloc/hunt_complete_cubit.dart';
import '../widgets/share_card.dart';
import '../widgets/stats_card.dart';

class HuntCompletePage extends StatelessWidget {
  const HuntCompletePage({
    super.key,
    required this.huntId,
    this.elapsedSeconds = 0,
    this.hintsUsed = 0,
  });

  final String huntId;
  final int elapsedSeconds;
  final int hintsUsed;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HuntCompleteCubit(huntRepository: sl())
        ..load(
          huntId: huntId,
          elapsedSeconds: elapsedSeconds,
          hintsUsed: hintsUsed,
        ),
      child: BlocBuilder<HuntCompleteCubit, HuntCompleteState>(
        builder: (context, state) => switch (state) {
          HuntCompleteInitial() || HuntCompleteLoading() => const Scaffold(
              body: Center(child: HMLoading()),
            ),
          HuntCompleteError(:final message) => Scaffold(
              body: Center(child: Text(message)),
            ),
          HuntCompleteLoaded() => _CompleteContent(state: state),
        },
      ),
    );
  }
}

class _CompleteContent extends StatelessWidget {
  const _CompleteContent({required this.state});

  final HuntCompleteLoaded state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.spaceXL),
              const Icon(Icons.emoji_events_rounded,
                  size: 80, color: AppColors.secondary),
              const SizedBox(height: AppDimensions.spaceL),
              Text(
                'Hunt Complete!',
                style: AppTypography.headlineLarge
                    .copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                state.hunt.title,
                style: AppTypography.bodyLarge
                    .copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceXXL),
              StatsCard(
                elapsedSeconds: state.elapsedSeconds,
                hintsUsed: state.hintsUsed,
                checkpointCount: state.hunt.checkpointCount,
              ),
              const SizedBox(height: AppDimensions.spaceL),
              ShareCard(
                huntTitle: state.hunt.title,
                elapsedTime:
                    HMDateUtils.formatElapsedSeconds(state.elapsedSeconds),
              ),
              const SizedBox(height: AppDimensions.spaceXXL),
              HMButton.secondary(
                label: 'Back to Home',
                onPressed: () => context.go(RouteNames.home),
              ),
              const SizedBox(height: AppDimensions.spaceM),
              HMButton.text(
                label: 'View Profile',
                onPressed: () => context.go(RouteNames.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
