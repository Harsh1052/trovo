import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../shared/models/checkpoint_model.dart';

/// Placeholder map widget — replace with a real Google Maps widget
/// once the google_maps_flutter package is added.
class RoutePreviewMap extends StatelessWidget {
  const RoutePreviewMap({super.key, required this.checkpoints});

  final List<CheckpointModel> checkpoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.mapPreviewHeight,
      decoration: BoxDecoration(
        color: AppColors.greyExtraLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: checkpoints.isEmpty
          ? const Center(
              child: Icon(Icons.map_outlined,
                  size: 48, color: AppColors.greyLight),
            )
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.map_outlined,
                            size: 48, color: AppColors.primary),
                        const SizedBox(height: AppDimensions.spaceS),
                        Text(
                          '${checkpoints.length} checkpoints',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                // Checkpoint list
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceM),
                    itemCount: checkpoints.length,
                    separatorBuilder: (_, __) => const Icon(
                      Icons.chevron_right,
                      color: AppColors.greyLight,
                    ),
                    itemBuilder: (_, i) => Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: AppTypography.labelSmall
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
