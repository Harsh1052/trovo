import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/hm_button.dart';
import '../../../../shared/widgets/hm_cached_image.dart';
import '../../../../shared/widgets/hm_error_widget.dart';
import '../../../../shared/widgets/hm_loading.dart';
import '../../bloc/hunt_detail_cubit.dart';
import '../widgets/hunt_info_chips.dart';
import '../widgets/route_preview_map.dart';

class HuntDetailPage extends StatelessWidget {
  const HuntDetailPage({super.key, required this.huntId});

  final String huntId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HuntDetailCubit(
        huntRepository: sl(),
        paymentRepository: sl(),
      )..load(huntId),
      child: BlocBuilder<HuntDetailCubit, HuntDetailState>(
        builder: (context, state) => switch (state) {
          HuntDetailInitial() || HuntDetailLoading() => const Scaffold(
              body: Center(child: HMLoading()),
            ),
          HuntDetailError(:final message) => Scaffold(
              appBar: AppBar(),
              body: HMErrorWidget(
                message: message,
                onRetry: () =>
                    context.read<HuntDetailCubit>().load(huntId),
              ),
            ),
          HuntDetailLoaded() => _HuntDetailContent(
              state: state,
              huntId: huntId,
            ),
        },
      ),
    );
  }
}

class _HuntDetailContent extends StatelessWidget {
  const _HuntDetailContent({
    required this.state,
    required this.huntId,
  });

  final HuntDetailLoaded state;
  final String huntId;

  @override
  Widget build(BuildContext context) {
    final hunt = state.hunt;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(hunt.title,
                  style: AppTypography.titleMedium
                      .copyWith(color: Colors.white)),
              background: HMCachedImage(url: hunt.coverImageUrl!),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HuntInfoChips(hunt: hunt),
                  const SizedBox(height: AppDimensions.spaceL),
                  Text('About',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppDimensions.spaceS),
                  Text(hunt.description,
                      style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary)),
                  const SizedBox(height: AppDimensions.spaceL),
                  Text('Route Preview',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppDimensions.spaceS),
                  RoutePreviewMap(checkpoints: state.checkpoints),
                  const SizedBox(height: AppDimensions.spaceXXL),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          child: state.hasAccess
              ? HMButton.primary(
                  label: 'Start Hunt',
                  onPressed: () =>
                      context.push(RouteNames.countdownPath(huntId)),
                  icon: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white),
                )
              : HMButton.secondary(
                  label: 'Unlock for \$${hunt.price!.toStringAsFixed(2)}',
                  onPressed: () => context.push(RouteNames.paywall),
                ),
        ),
      ),
    );
  }
}
