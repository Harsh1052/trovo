import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../shared/models/hunt_model.dart';
import '../../../../shared/widgets/hm_badge.dart';
import '../../../../shared/widgets/hm_cached_image.dart';

class FeaturedHuntCard extends StatelessWidget {
  const FeaturedHuntCard({super.key, required this.hunt});

  final HuntModel hunt;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.huntDetailPath(hunt.huntId)),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hunt.coverImageUrl.isNotEmpty)
              HMCachedImage(url: hunt.coverImageUrl, height: 130)
            else
              Container(
                height: 130,
                color: AppColors.primaryLight,
                child: const Center(
                  child: Icon(Icons.explore_rounded,
                      size: 48, color: Colors.white),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hunt.title,
                          style: AppTypography.titleMedium,
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
                  Text(
                    hunt.city,
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
