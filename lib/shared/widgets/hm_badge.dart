import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimensions.dart';
import '../../config/theme/app_typography.dart';

enum HMBadgeType { free, paid }

class HMBadge extends StatelessWidget {
  const HMBadge({super.key, required this.type});

  const HMBadge.free({super.key}) : type = HMBadgeType.free;
  const HMBadge.paid({super.key}) : type = HMBadgeType.paid;

  final HMBadgeType type;

  @override
  Widget build(BuildContext context) {
    final isFree = type == HMBadgeType.free;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS,
        vertical: AppDimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: isFree ? AppColors.badgeFree : AppColors.badgePaid,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        isFree ? 'FREE' : 'PAID',
        style: AppTypography.labelSmall.copyWith(
          color: isFree ? AppColors.badgeFreeText : AppColors.badgePaidText,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
