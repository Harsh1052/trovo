import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../shared/models/guardian_record_model.dart';

class GuardianCard extends StatelessWidget {
  const GuardianCard({
    super.key,
    required this.guardian,
    this.huntTitle,
  });

  final GuardianRecordModel guardian;
  final String? huntTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.15),
            AppColors.surfaceVariant,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.secondary,
            child: const Text('👑', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (huntTitle != null)
                  Text(
                    huntTitle!,
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Row(
                  children: [
                    Text(
                      'Guardian: ',
                      style: AppTypography.caption,
                    ),
                    Text(
                      guardian.guardianName,
                      style: AppTypography.labelMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  'Record Time: ${guardian.formattedTime}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.chipPadding,
              vertical: AppDimensions.spaceXXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              'Challenged 🏆',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textOnSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
