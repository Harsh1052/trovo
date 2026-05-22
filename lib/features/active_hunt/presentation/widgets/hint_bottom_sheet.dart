import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../shared/widgets/hm_button.dart';

class HintBottomSheet extends StatelessWidget {
  const HintBottomSheet({
    super.key,
    required this.hints,
    required this.onReveal,
  });

  final List<String> hints;
  final VoidCallback onReveal;

  static Future<void> show(
    BuildContext context, {
    required List<String> hints,
    required VoidCallback onReveal,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => HintBottomSheet(hints: hints, onReveal: onReveal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppDimensions.pagePadding,
        right: AppDimensions.pagePadding,
        top: AppDimensions.spaceM,
        bottom: MediaQuery.viewInsetsOf(context).bottom +
            AppDimensions.spaceXL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hints', style: AppTypography.headlineSmall),
          const SizedBox(height: AppDimensions.spaceM),
          if (hints.isEmpty)
            Text(
              'No hints revealed yet.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            )
          else
            ...hints.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(
                        bottom: AppDimensions.spaceM),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: AppTypography.labelSmall
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceS),
                        Expanded(
                          child: Text(e.value,
                              style: AppTypography.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: AppDimensions.spaceM),
          HMButton.outlined(
            label: 'Reveal next hint (+${60}s penalty)',
            onPressed: onReveal,
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
        ],
      ),
    );
  }
}
