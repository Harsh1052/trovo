import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimensions.dart';
import '../../config/theme/app_typography.dart';
import 'hm_button.dart';

/// Full-screen widget shown when the user has denied location permission.
///
/// Explains why location is essential for the hunt and provides two actions:
/// 1. **Try Again** — re-triggers the OS permission dialog (if not permanently
///    denied) or opens app settings (if permanently denied).
/// 2. **Open Settings** — always navigates to the OS location settings screen.
class HMLocationDeniedWidget extends StatelessWidget {
  const HMLocationDeniedWidget({
    super.key,
    required this.onRetry,
    this.isPermanentlyDenied = false,
  });

  /// Called when the user taps "Allow Location Access" / "Open Settings".
  final VoidCallback onRetry;

  /// When true, the user has permanently denied (Android's "Don't ask again"
  /// or iOS never-allowed). Show the "Open Settings" CTA instead.
  final bool isPermanentlyDenied;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Illustration circle ──────────────────────────────────────
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: AppDimensions.iconSizeXL,
                color: AppColors.warning,
              ),
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // ── Title ────────────────────────────────────────────────────
            Text(
              'Location Access Required',
              style: AppTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppDimensions.spaceM),

            // ── Description ──────────────────────────────────────────────
            Text(
              'Trovo uses your location to guide you to hunt checkpoints '
              'and verify that you\'ve arrived at each clue. '
              'Without it, the hunt can\'t work.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppDimensions.spaceXL),

            // ── Primary CTA ──────────────────────────────────────────────
            HMButton.primary(
              label: isPermanentlyDenied
                  ? 'Open Settings'
                  : 'Allow Location Access',
              onPressed: onRetry,
              icon: Icon(
                isPermanentlyDenied
                    ? Icons.settings_rounded
                    : Icons.my_location_rounded,
              ),
              width: 240,
            ),

            if (isPermanentlyDenied) ...[
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                'Tap "Location" → "While Using the App"',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: AppDimensions.spaceM),

            // ── Secondary: open device location settings ─────────────────
            if (!isPermanentlyDenied)
              HMButton.text(
                label: 'Open Settings Instead',
                onPressed: () => Geolocator.openAppSettings(),
              ),
          ],
        ),
      ),
    );
  }
}
