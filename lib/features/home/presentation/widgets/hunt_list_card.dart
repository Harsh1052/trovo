import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../shared/models/hunt_model.dart';
import '../../../../shared/widgets/hm_badge.dart';
import '../../../../shared/widgets/hm_cached_image.dart';

class HuntListCard extends StatelessWidget {
  const HuntListCard({super.key, required this.hunt});

  final HuntModel hunt;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.huntDetailPath(hunt.huntId)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            if (hunt.coverImageUrl.isNotEmpty)
              HMCachedImage(
                url: hunt.coverImageUrl,
                width: 90,
                height: 90,
              )
            else
              Container(
                width: 90,
                height: 90,
                color: AppColors.primaryLight,
                child: const Icon(Icons.explore_rounded,
                    size: 36, color: Colors.white),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hunt.title,
                            style: AppTypography.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        HMBadge(type: hunt.isFree
                            ? HMBadgeType.free
                            : HMBadgeType.paid),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(hunt.city, style: AppTypography.bodySmall),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${hunt.durationMinutes}m',
                            style: AppTypography.caption),
                        const SizedBox(width: AppDimensions.spaceS),
                        const Icon(Icons.flag_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${hunt.checkpointCount} stops',
                            style: AppTypography.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
