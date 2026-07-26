import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../shared/widgets/hm_button.dart';
import '../../bloc/active_hunt_bloc.dart';
import '../../bloc/active_hunt_event.dart';
import '../../bloc/active_hunt_state.dart';

class HintBottomSheet extends StatelessWidget {
  const HintBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<ActiveHuntBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusL)),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const HintBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveHuntBloc, ActiveHuntState>(
      builder: (context, state) {
        if (state is! ActiveHuntInProgress) {
          return const SizedBox.shrink();
        }

        final checkpoint = state.currentCheckpoint;
        final isRevealed = state.hintRevealed;
        final rawHint = checkpoint.hintText.trim();
        final rawAnswer = (checkpoint.answer ?? '').trim();

        // Generate first letter helper string
        String firstLetterHint = '';
        if (rawAnswer.isNotEmpty) {
          final firstChar = rawAnswer[0].toUpperCase();
          final length = rawAnswer.length;
          firstLetterHint = "First letter is '$firstChar' ($length letters total)";
        }

        final hintMessage = rawHint.isNotEmpty
            ? rawHint
            : (firstLetterHint.isNotEmpty
                ? firstLetterHint
                : 'Look carefully around the checkpoint area!');

        return Padding(
          padding: EdgeInsets.only(
            left: AppDimensions.pagePadding,
            right: AppDimensions.pagePadding,
            top: AppDimensions.spaceL,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppDimensions.spaceXL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('💡 Checkpoint Hint', style: AppTypography.headlineSmall),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceM),
              if (!isRevealed) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.spaceM),
                  decoration: BoxDecoration(
                    color: AppColors.greyExtraLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Text(
                    'Need help? Reveal the clue hint for this location.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),
                HMButton.primary(
                  label: 'Reveal Hint (${state.remainingHints} left)',
                  onPressed: () {
                    context.read<ActiveHuntBloc>().add(const ActiveHuntHintRequested());
                  },
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.spaceL),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: AppDimensions.spaceXS),
                          Text(
                            'HINT REVEALED',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                      Text(
                        hintMessage,
                        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (firstLetterHint.isNotEmpty && rawHint.isNotEmpty) ...[
                        const Divider(height: AppDimensions.spaceL),
                        Text(
                          '🔤 $firstLetterHint',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),
                HMButton.outlined(
                  label: 'Got it, thanks!',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
