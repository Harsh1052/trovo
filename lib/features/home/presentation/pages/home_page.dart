import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/models/hunt_model.dart';
import '../../../../shared/widgets/hm_error_widget.dart';
import '../../../../shared/widgets/hm_loading.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';
import '../widgets/city_selector_sheet.dart';
import '../widgets/featured_hunt_card.dart';
import '../widgets/hunt_list_card.dart';
import '../../../studio/presentation/widgets/join_by_code_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(huntRepository: sl())
        ..add(const HomeLoadRequested('')),
      child: const _HomeScaffold(),
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HunterMania'),
        actions: [
          // ── City selector ───────────────────────────────────────────────
          BlocBuilder<HomeBloc, HomeState>(
            buildWhen: (prev, next) =>
                next is HomeLoaded &&
                (prev is! HomeLoaded ||
                    prev.selectedCity != next.selectedCity),
            builder: (context, state) {
              if (state is! HomeLoaded) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => _openCitySelector(context, state),
                icon: const Icon(Icons.location_on_outlined, size: 16),
                label: Text(
                  state.cityLabel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              );
            },
          ),
          // ── Leaderboard Hub ─────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => context.push(RouteNames.leaderboard),
          ),
          // ── Profile ─────────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push(RouteNames.profile),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) => switch (state) {
          HomeInitial() || HomeLoading() => const Center(child: HMLoading()),
          HomeError(:final message) => HMErrorWidget(
              message: message,
              onRetry: () =>
                  context.read<HomeBloc>().add(const HomeRefreshRequested()),
            ),
          HomeLoaded() => _HomeContent(state: state),
        },
      ),
    );
  }

  Future<void> _openCitySelector(
      BuildContext context, HomeLoaded state) async {
    final selected = await CitySelectorSheet.show(
      context,
      cities: state.availableCities,
      // Pass null to the sheet when "All Cities" is active so it highlights
      // the "All Cities" row; convert empty string back to null here.
      selectedCity: state.selectedCity.isEmpty ? null : state.selectedCity,
    );

    if (!context.mounted) return;

    // Sheet dismissed without selection — do nothing.
    if (selected == null && state.selectedCity.isEmpty) return;

    // Map null (= "All Cities") back to empty string sentinel.
    final city = selected ?? '';
    context.read<HomeBloc>().add(HomeCityChanged(city));
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.state});

  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<HomeBloc>().add(const HomeRefreshRequested()),
      child: state.hunts.isEmpty
          ? _EmptyState(city: state.cityLabel)
          : ListView(
              padding:
                  const EdgeInsets.symmetric(vertical: AppDimensions.spaceM),
              children: [
                // ── Featured hero card ────────────────────────────────────
                if (state.featuredHunt != null) ...[
                  _SectionHeader(title: 'Featured'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.pagePadding),
                    child: FeaturedHuntCard(hunt: state.featuredHunt!),
                  ),
                  const SizedBox(height: AppDimensions.spaceXL),
                ],

                // ── Free hunts ────────────────────────────────────────────
                if (state.freeHunts.isNotEmpty) ...[
                  _SectionHeader(title: 'Free Hunts'),
                  ..._huntTiles(state.freeHunts),
                  const SizedBox(height: AppDimensions.spaceL),
                ],

                // ── Studio Creator Banner ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.pagePadding,
                    vertical: AppDimensions.spaceS,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.cardPadding),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusL),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_stories_rounded,
                                color: AppColors.secondary, size: 28),
                            const SizedBox(width: AppDimensions.spaceS),
                            Text(
                              'HunterMania Studio 🛠️',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spaceXS),
                        Text(
                          'Create custom treasure hunts & private event stories for your friends!',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: AppDimensions.spaceM),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: AppColors.textOnSecondary,
                                ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Create Story'),
                                onPressed: () =>
                                    context.push(RouteNames.studioCreate),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceS),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54),
                                ),
                                icon: const Icon(Icons.key_rounded, size: 18),
                                label: const Text('Enter Code'),
                                onPressed: () => JoinByCodeDialog.show(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),

                // ── Paid hunts ────────────────────────────────────────────
                if (state.paidHunts.isNotEmpty) ...[
                  _SectionHeader(title: 'Paid Hunts'),
                  ..._huntTiles(state.paidHunts),
                ],
              ],
            ),
    );
  }

  List<Widget> _huntTiles(List<HuntModel> hunts) => hunts
      .map((hunt) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePadding,
              vertical: AppDimensions.spaceXS,
            ),
            child: HuntListCard(hunt: hunt),
          ))
      .toList();
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePadding,
        vertical: AppDimensions.spaceS,
      ),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.city});
  final String city;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore_off_outlined,
              size: 64, color: AppColors.textSecondary),
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            'No hunts in $city yet.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          TextButton(
            onPressed: () =>
                context.read<HomeBloc>().add(const HomeCityChanged('')),
            child: const Text('Browse all cities'),
          ),
        ],
      ),
    );
  }
}
