import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/models/hunt_model.dart';
import '../../../../shared/models/hunt_progress_model.dart';

class CompletedHuntTile extends StatelessWidget {
  const CompletedHuntTile({
    super.key,
    required this.hunt,
    required this.progress,
  });

  final HuntModel hunt;
  final HuntProgressModel progress;

  int _elapsedSeconds(HuntProgressModel p) =>
      p.completedAt?.difference(p.startedAt).inSeconds ?? 0;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePadding,
        vertical: AppDimensions.spaceXS,
      ),
      leading: Container(
        width: AppDimensions.avatarSizeM,
        height: AppDimensions.avatarSizeM,
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: const Icon(Icons.check_rounded,
            color: AppColors.success, size: AppDimensions.iconSizeM),
      ),
      title: Text(hunt.title,
          style: AppTypography.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${HMDateUtils.formatElapsedSeconds(_elapsedSeconds(progress))} · '
        '${progress.hintsUsed} hints · '
        '${HMDateUtils.toShortDate(progress.completedAt ?? progress.startedAt)}',
        style: AppTypography.caption,
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.greyLight),
      onTap: () => context.push(RouteNames.huntDetailPath(hunt.huntId)),
    );
  }
}
