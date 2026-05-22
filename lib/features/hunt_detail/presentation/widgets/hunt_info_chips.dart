import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../shared/models/hunt_model.dart';
import '../../../../shared/widgets/hm_badge.dart';

class HuntInfoChips extends StatelessWidget {
  const HuntInfoChips({super.key, required this.hunt});

  final HuntModel hunt;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spaceS,
      runSpacing: AppDimensions.spaceS,
      children: [
        HMBadge(type: hunt.isFree ? HMBadgeType.free : HMBadgeType.paid),
        _Chip(
          icon: Icons.timer_outlined,
          label: '${hunt.durationMinutes} min',
        ),
        _Chip(
          icon: Icons.flag_outlined,
          label: '${hunt.checkpointCount} stops',
        ),
        _Chip(
          icon: Icons.bar_chart_rounded,
          label: hunt.difficulty.name.toUpperCase(),
          color: _difficultyColor(hunt.difficulty),
        ),
        _Chip(
          icon: Icons.location_on_outlined,
          label: hunt.gardenName,
        ),
      ],
    );
  }

  Color _difficultyColor(HuntDifficulty d) => switch (d) {
        HuntDifficulty.easy => AppColors.success,
        HuntDifficulty.medium => AppColors.secondary,
        HuntDifficulty.hard => AppColors.error,
      };
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS,
        vertical: AppDimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: effectiveColor),
          ),
        ],
      ),
    );
  }
}
