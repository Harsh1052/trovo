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
import '../../../../core/error/result.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_state.dart';
import '../../../../shared/models/hunt_model.dart';
import '../../../../shared/repositories/creator_repository.dart';
import '../../../../shared/widgets/hm_button.dart';
import '../../../../shared/widgets/hm_loading.dart';

class MyCreatedHuntsPage extends StatefulWidget {
  const MyCreatedHuntsPage({super.key});

  @override
  State<MyCreatedHuntsPage> createState() => _MyCreatedHuntsPageState();
}

class _MyCreatedHuntsPageState extends State<MyCreatedHuntsPage> {
  bool _loading = true;
  List<HuntModel> _hunts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHunts();
  }

  Future<void> _fetchHunts() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = sl<CreatorRepository>();
    final result = await repo.fetchUserCreatedHunts(authState.user.uid);

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        setState(() {
          _hunts = data;
          _loading = false;
        });
      case Err(:final failure):
        setState(() {
          _error = failure.userFriendlyMessage;
          _loading = false;
        });
    }
  }

  Future<void> _deleteHunt(String huntId) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final repo = sl<CreatorRepository>();
    final result = await repo.deleteCreatedHunt(
      huntId: huntId,
      userId: authState.user.uid,
    );

    if (!mounted) return;

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hunt deleted successfully.')),
        );
        _fetchHunts();
      case Err(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.userFriendlyMessage),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Created Hunts 🛠️'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: HMLoading())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: AppTypography.bodyLarge),
                      const SizedBox(height: AppDimensions.spaceM),
                      HMButton.primary(
                        label: 'Retry',
                        onPressed: _fetchHunts,
                      ),
                    ],
                  ),
                )
              : _hunts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_stories_outlined,
                            size: 64,
                            color: AppColors.greyLight,
                          ),
                          const SizedBox(height: AppDimensions.spaceM),
                          Text(
                            'No stories created yet.',
                            style: AppTypography.headlineSmall,
                          ),
                          const SizedBox(height: AppDimensions.spaceS),
                          Text(
                            'Create your first custom treasure hunt in HunterMania Studio!',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.spaceL),
                          HMButton.primary(
                            label: 'Create New Story 🛠️',
                            onPressed: () =>
                                context.push(RouteNames.studioCreate),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppDimensions.pagePadding),
                      itemCount: _hunts.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppDimensions.spaceM),
                      itemBuilder: (context, index) {
                        final hunt = _hunts[index];
                        return Card(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(AppDimensions.cardPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        hunt.title,
                                        style: AppTypography.titleMedium,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppDimensions.chipPadding,
                                        vertical: AppDimensions.spaceXXS,
                                      ),
                                      decoration: BoxDecoration(
                                        color: hunt.isPrivate
                                            ? AppColors.secondary
                                                .withValues(alpha: 0.2)
                                            : AppColors.primary
                                                .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(
                                            AppDimensions.radiusFull),
                                      ),
                                      child: Text(
                                        hunt.isPrivate ? 'Private 🔒' : 'Public 🌍',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: hunt.isPrivate
                                              ? AppColors.secondaryDark
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppDimensions.spaceXS),
                                Text(
                                  hunt.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall,
                                ),
                                if (hunt.accessCode != null) ...[
                                  const SizedBox(height: AppDimensions.spaceS),
                                  Row(
                                    children: [
                                      Text(
                                        'Access Code: ${hunt.accessCode}',
                                        style: AppTypography.labelMedium
                                            .copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: AppDimensions.spaceS),
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded,
                                            size: 18),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                              text: hunt.accessCode!));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text('Code copied!')),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.share_rounded,
                                            size: 18),
                                        onPressed: () {
                                          Share.share(
                                            'Play my custom hunt "${hunt.title}"! 🏆\n'
                                            'Access Code: ${hunt.accessCode}\n\n'
                                            'Enter code in HunterMania app!',
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                                const Divider(height: AppDimensions.spaceL),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => context.push(
                                          RouteNames.huntDetailPath(hunt.huntId)),
                                      icon: const Icon(Icons.play_arrow_rounded),
                                      label: const Text('View Hunt'),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.error),
                                      onPressed: () => _confirmDelete(hunt),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.studioCreate),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Story'),
      ),
    );
  }

  void _confirmDelete(HuntModel hunt) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Story?'),
        content: Text('Are you sure you want to delete "${hunt.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _deleteHunt(hunt.huntId);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
