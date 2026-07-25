import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';

class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.huntTitle,
    required this.elapsedTime,
  });

  final String huntTitle;
  final String elapsedTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        children: [
          Text('Share your adventure',
              style: AppTypography.titleMedium.copyWith(color: Colors.white)),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            'I just completed "$huntTitle" in $elapsedTime on HunterMania! 🗺️',
            style:
                AppTypography.bodyMedium.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spaceL),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
            ),
            onPressed: () => _share(context),
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final text =
        'I just completed "$huntTitle" in $elapsedTime on HunterMania! 🗺️\n\n'
        'Download the app and start your own treasure hunt!';

    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      text,
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }
}
