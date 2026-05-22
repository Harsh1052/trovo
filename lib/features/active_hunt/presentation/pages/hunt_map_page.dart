import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';

/// Full-screen map view for the active hunt.
/// Replace the placeholder with google_maps_flutter once configured.
class HuntMapPage extends StatelessWidget {
  const HuntMapPage({super.key, required this.huntId});

  final String huntId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Stack(
        children: [
          // Placeholder — swap for GoogleMap widget
          Container(
            color: AppColors.greyExtraLight,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map_outlined,
                      size: 72, color: AppColors.primary),
                  const SizedBox(height: AppDimensions.spaceM),
                  Text('Map view coming soon',
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: AppDimensions.spaceXL,
            left: AppDimensions.pagePadding,
            right: AppDimensions.pagePadding,
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Clue'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
