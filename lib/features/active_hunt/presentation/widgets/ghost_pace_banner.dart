import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';

class GhostPaceBanner extends StatelessWidget {
  const GhostPaceBanner({
    super.key,
    required this.elapsedSeconds,
    required this.guardianTimeSeconds,
  });

  final int elapsedSeconds;
  final int guardianTimeSeconds;

  @override
  Widget build(BuildContext context) {
    if (guardianTimeSeconds <= 0) return const SizedBox.shrink();

    final diff = guardianTimeSeconds - elapsedSeconds;
    final isAhead = diff >= 0;

    final formattedDiff = isAhead ? '${diff}s faster' : '${diff.abs()}s behind';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceS,
      ),
      decoration: BoxDecoration(
        color: isAhead
            ? AppColors.successLight
            : AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isAhead ? AppColors.success : AppColors.error,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAhead ? Icons.bolt_rounded : Icons.timer_outlined,
            color: isAhead ? AppColors.success : AppColors.error,
            size: 18,
          ),
          const SizedBox(width: AppDimensions.spaceXS),
          Text(
            'Ghost Pace: $formattedDiff than Guardian record',
            style: AppTypography.labelSmall.copyWith(
              color: isAhead ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
