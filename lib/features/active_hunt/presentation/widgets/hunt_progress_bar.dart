import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';

class HuntProgressBar extends StatelessWidget {
  const HuntProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Checkpoint $current / $total',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceXS),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.greyExtraLight,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
