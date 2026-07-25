import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/proximity_calculator.dart';

class RadarCompassWidget extends StatefulWidget {
  const RadarCompassWidget({
    super.key,
    required this.feedback,
  });

  final ProximityFeedback feedback;

  @override
  State<RadarCompassWidget> createState() => _RadarCompassWidgetState();
}

class _RadarCompassWidgetState extends State<RadarCompassWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.feedback.zone.pulseIntervalMs),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant RadarCompassWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedback.zone != widget.feedback.zone) {
      _pulseController.duration =
          Duration(milliseconds: widget.feedback.zone.pulseIntervalMs);
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _zoneColor => switch (widget.feedback.zone) {
        ProximityZone.cold => AppColors.info,
        ProximityZone.warm => AppColors.warning,
        ProximityZone.hot => AppColors.error,
        ProximityZone.unlocked => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    final headingRad = widget.feedback.relativeHeadingOffset * math.pi / 180;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Animated Radar Disc ───────────────────────────────────────────────
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulseScale = 1.0 + (_pulseController.value * 0.12);
            final opacity = 0.3 + (_pulseController.value * 0.4);

            return SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Pulsing Wave Ring
                  Transform.scale(
                    scale: pulseScale,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _zoneColor.withValues(alpha: opacity),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                  // Dark Obsidian Radar Base
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.dark,
                      boxShadow: [
                        BoxShadow(
                          color: _zoneColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: _zoneColor.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Concentric Target Rings
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                        ),
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                        ),
                        // Rotating Compass Needle Arrow
                        Transform.rotate(
                          angle: headingRad,
                          child: Icon(
                            Icons.navigation_rounded,
                            size: 44,
                            color: _zoneColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: AppDimensions.spaceS),

        // ── Zone Label & Distance Badge ─────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceM,
            vertical: AppDimensions.spaceXS,
          ),
          decoration: BoxDecoration(
            color: _zoneColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(color: _zoneColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _zoneColor,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceXS),
              Text(
                '${widget.feedback.zone.label} • ${widget.feedback.formattedDistance}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
