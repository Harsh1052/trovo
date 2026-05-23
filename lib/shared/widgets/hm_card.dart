import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimensions.dart';

class HMCard extends StatelessWidget {
  const HMCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.elevation = AppDimensions.elevationLow,
    this.borderRadius = AppDimensions.radiusL,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double elevation;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color ?? AppColors.surface,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppDimensions.cardPadding),
          child: child,
        ),
      ),
    );
  }
}
