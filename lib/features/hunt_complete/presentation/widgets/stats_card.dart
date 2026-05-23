import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.elapsedSeconds,
    required this.hintsUsed,
    required this.checkpointCount,
  });

  final int elapsedSeconds;
  final int hintsUsed;
  final int checkpointCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(
            icon: Icons.timer_outlined,
            value: HMDateUtils.formatElapsedSeconds(elapsedSeconds),
            label: 'Time',
          ),
          _divider(),
          _Stat(
            icon: Icons.flag_rounded,
            value: '$checkpointCount',
            label: 'Stops',
          ),
          _divider(),
          _Stat(
            icon: Icons.lightbulb_outline_rounded,
            value: '$hintsUsed',
            label: 'Hints',
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 48,
        color: Colors.white24,
      );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.secondary, size: AppDimensions.iconSizeM),
        const SizedBox(height: AppDimensions.spaceXS),
        Text(value,
            style: AppTypography.titleLarge.copyWith(color: Colors.white)),
        Text(label,
            style: AppTypography.caption.copyWith(color: Colors.white70)),
      ],
    );
  }
}
