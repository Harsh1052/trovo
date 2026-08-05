import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_state.dart';
import '../../../../shared/widgets/hm_button.dart';
import '../../../../shared/widgets/hm_loading.dart';
import '../../bloc/hunt_creator_bloc.dart';
import '../../bloc/hunt_creator_event.dart';
import '../../bloc/hunt_creator_state.dart';

class StepReviewView extends StatelessWidget {
  const StepReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HuntCreatorBloc, HuntCreatorState>(
      builder: (context, state) {
        if (state is HuntCreatorSubmitting) {
          return const Center(child: HMLoading());
        }

        if (state is! HuntCreatorFormState) {
          return const SizedBox.shrink();
        }

        final form = state;
        final authState = context.read<AuthBloc>().state;
        final userId = authState is AuthAuthenticated ? authState.user.uid : '';
        final userName =
            authState is AuthAuthenticated ? authState.user.displayName : 'Hunter';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Step 3: Review & Publish', style: AppTypography.headlineSmall),
              const SizedBox(height: AppDimensions.spaceXS),
              Text(
                'Verify your adventure story before publishing to players.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // ── Validation Errors Banner ───────────────────────────────────
              if (form.validationError != null)
                Container(
                  padding: const EdgeInsets.all(AppDimensions.cardPadding),
                  margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error),
                      const SizedBox(width: AppDimensions.spaceM),
                      Expanded(
                        child: Text(
                          form.validationError!,
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Hunt Details Card Summary ──────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              form.title.isEmpty ? 'Untitled Story' : form.title,
                              style: AppTypography.titleLarge,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.chipPadding,
                              vertical: AppDimensions.spaceXXS,
                            ),
                            decoration: BoxDecoration(
                              color: form.isPrivate
                                  ? AppColors.secondary.withValues(alpha: 0.2)
                                  : AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusFull),
                            ),
                            child: Text(
                              form.isPrivate ? 'Private 🔒' : 'Public 🌍',
                              style: AppTypography.labelSmall.copyWith(
                                color: form.isPrivate
                                    ? AppColors.secondaryDark
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                      Text(
                        form.description.isEmpty
                            ? 'No description provided.'
                            : form.description,
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const Divider(height: AppDimensions.spaceL),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Location: ${form.city} (${form.gardenName})',
                              style: AppTypography.bodySmall),
                          Text('Duration: ${form.durationMinutes} min',
                              style: AppTypography.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // ── Checkpoints Summary ────────────────────────────────────────
              Text(
                'Checkpoints (${form.checkpoints.length} Stops)',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: AppDimensions.spaceS),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: form.checkpoints.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppDimensions.spaceS),
                itemBuilder: (context, index) {
                  final cp = form.checkpoints[index];
                  return Container(
                    padding: const EdgeInsets.all(AppDimensions.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(color: AppColors.greyLight),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            '${index + 1}',
                            style: AppTypography.labelSmall
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cp.clueText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.titleSmall),
                              Text(
                                '${cp.displayLabel} • ${cp.answer ?? cp.targetText ?? "Photo Target"}',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDimensions.spaceXXL),

              // ── Publish Action Button ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: HMButton.primary(
                  label: 'Publish Adventure Story 🚀',
                  onPressed: form.canPublish
                      ? () {
                          context.read<HuntCreatorBloc>().add(
                                HuntCreatorSubmitted(
                                  creatorUserId: userId,
                                  creatorName: userName,
                                ),
                              );
                        }
                      : null,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceL),
            ],
          ),
        );
      },
    );
  }
}
