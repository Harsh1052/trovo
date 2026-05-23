import 'package:flutter/material.dart';

import '../../config/theme/app_dimensions.dart';
import 'hm_loading.dart';

enum _HMButtonVariant { primary, secondary, outlined, text }

class HMButton extends StatelessWidget {
  const HMButton._({
    required this.label,
    required this.onPressed,
    required _HMButtonVariant variant,
    this.isLoading = false,
    this.icon,
    this.width,
    super.key,
  }) : _variant = variant;

  factory HMButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    double? width,
  }) =>
      HMButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: _HMButtonVariant.primary,
        isLoading: isLoading,
        icon: icon,
        width: width,
      );

  factory HMButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    double? width,
  }) =>
      HMButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: _HMButtonVariant.secondary,
        isLoading: isLoading,
        icon: icon,
        width: width,
      );

  factory HMButton.outlined({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    double? width,
  }) =>
      HMButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: _HMButtonVariant.outlined,
        isLoading: isLoading,
        icon: icon,
        width: width,
      );

  factory HMButton.text({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
  }) =>
      HMButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: _HMButtonVariant.text,
        icon: icon,
      );

  final String label;
  final VoidCallback? onPressed;
  final _HMButtonVariant _variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const HMLoading(size: 20, color: Colors.white)
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  const SizedBox(width: AppDimensions.spaceS),
                  Text(label),
                ],
              )
            : Text(label);

    Widget button = switch (_variant) {
      _HMButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      _HMButtonVariant.secondary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
          ),
          child: child,
        ),
      _HMButtonVariant.outlined => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      _HMButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
    };

    if (width != null) {
      button = SizedBox(width: width, child: button);
    }

    return button;
  }
}
