import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/hm_button.dart';
import '../../../../shared/widgets/hm_loading.dart';
import '../../bloc/paywall_cubit.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key, this.huntProductId});

  final String? huntProductId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaywallCubit(paymentRepository: sl()),
      child: BlocConsumer<PaywallCubit, PaywallState>(
        listener: (context, state) {
          if (state is PaywallPurchaseSuccess ||
              state is PaywallRestoreSuccess) {
            Navigator.of(context).pop(true);
          }
          if (state is PaywallError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is PaywallLoading;
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.textPrimary,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.all(AppDimensions.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_open_rounded,
                        size: 72, color: AppColors.secondary),
                    const SizedBox(height: AppDimensions.spaceL),
                    Text('Unlock This Hunt',
                        style: AppTypography.headlineMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppDimensions.spaceS),
                    Text(
                      'Get full access to GPS checkpoints, clues, and photo challenges.',
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spaceXXL),
                    _FeatureRow(
                        icon: Icons.explore_rounded,
                        text: 'All GPS checkpoints unlocked'),
                    _FeatureRow(
                        icon: Icons.lightbulb_outline_rounded,
                        text: 'Up to 3 hints per stop'),
                    _FeatureRow(
                        icon: Icons.camera_alt_outlined,
                        text: 'Photo challenge tasks'),
                    _FeatureRow(
                        icon: Icons.emoji_events_rounded,
                        text: 'Completion badge & stats'),
                    const SizedBox(height: AppDimensions.spaceXXL),
                    isLoading
                        ? const HMLoading()
                        : HMButton.primary(
                            label: 'Unlock — \$2.99',
                            onPressed: () => context
                                .read<PaywallCubit>()
                                .purchase(
                                    huntProductId ?? 'hunt_single'),
                          ),
                    const SizedBox(height: AppDimensions.spaceM),
                    HMButton.text(
                      label: 'Restore Purchases',
                      onPressed: isLoading
                          ? null
                          : () =>
                              context.read<PaywallCubit>().restore(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.spaceS),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Icon(icon,
                size: AppDimensions.iconSizeS + 2,
                color: AppColors.success),
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
              child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
