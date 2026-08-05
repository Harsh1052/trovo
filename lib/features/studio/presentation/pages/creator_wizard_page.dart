import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/models/hunt_model.dart';
import '../../../../shared/widgets/hm_button.dart';
import '../../bloc/hunt_creator_bloc.dart';
import '../../bloc/hunt_creator_event.dart';
import '../../bloc/hunt_creator_state.dart';
import '../widgets/step_checkpoints_view.dart';
import '../widgets/step_details_view.dart';
import '../widgets/step_review_view.dart';

class CreatorWizardPage extends StatelessWidget {
  const CreatorWizardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HuntCreatorBloc(creatorRepository: sl()),
      child: const _CreatorWizardContent(),
    );
  }
}

class _CreatorWizardContent extends StatefulWidget {
  const _CreatorWizardContent();

  @override
  State<_CreatorWizardContent> createState() => _CreatorWizardContentState();
}

class _CreatorWizardContentState extends State<_CreatorWizardContent> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStepTap(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    context.read<HuntCreatorBloc>().add(HuntCreatorStepChanged(step));
  }

  bool _canAdvance(HuntCreatorState state, int currentStep) {
    if (state is! HuntCreatorFormState) return false;
    if (currentStep == 0) return state.isStep1Valid;
    if (currentStep == 1) return state.isStep2Valid;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HuntCreatorBloc, HuntCreatorState>(
      listener: (context, state) {
        if (state is HuntCreatorSuccess) {
          _showSuccessDialog(context, state.publishedHunt, state.accessCode);
        }
        if (state is HuntCreatorError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final currentStep = state is HuntCreatorFormState ? state.stepIndex : 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('HunterMania Studio 🛠️'),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _StepProgressBar(
                currentStep: currentStep,
                onStepTap: _onStepTap,
              ),
            ),
          ),
          body: PageView(
            controller: _pageController,
            onPageChanged: (page) {
              context.read<HuntCreatorBloc>().add(HuntCreatorStepChanged(page));
            },
            children: const [
              StepDetailsView(),
              StepCheckpointsView(),
              StepReviewView(),
            ],
          ),
          bottomNavigationBar: (state is HuntCreatorFormState)
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.pagePadding,
                      vertical: AppDimensions.spaceS,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (currentStep > 0)
                          HMButton.outlined(
                            label: 'Previous',
                            onPressed: () => _onStepTap(currentStep - 1),
                          )
                        else
                          const SizedBox.shrink(),
                        if (currentStep < 2)
                          HMButton.primary(
                            label: 'Next Step',
                            onPressed: _canAdvance(state, currentStep)
                                ? () => _onStepTap(currentStep + 1)
                                : null,
                          ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  void _showSuccessDialog(
    BuildContext context,
    HuntModel hunt,
    String? accessCode,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('🎉 Story Published!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your custom hunt "${hunt.title}" is live!',
              style: AppTypography.bodyMedium,
            ),
            if (accessCode != null) ...[
              const SizedBox(height: AppDimensions.spaceM),
              Container(
                padding: const EdgeInsets.all(AppDimensions.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(color: AppColors.secondary),
                ),
                child: Column(
                  children: [
                    Text('PRIVATE ACCESS CODE', style: AppTypography.caption),
                    const SizedBox(height: AppDimensions.spaceXS),
                    SelectableText(
                      accessCode,
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: accessCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied!')),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_rounded),
                          onPressed: () {
                            Share.share(
                              'Join my private HunterMania hunt! 🏆\n'
                              'Hunt: ${hunt.title}\n'
                              'Access Code: $accessCode\n\n'
                              'Open app and enter code to play!',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.go(RouteNames.home);
            },
            child: const Text('Go to Home'),
          ),
        ],
      ),
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({
    required this.currentStep,
    required this.onStepTap,
  });

  final int currentStep;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    const titles = ['1. Details', '2. Checkpoints', '3. Review'];
    return Container(
      color: AppColors.surfaceVariant,
      child: Row(
        children: List.generate(3, (i) {
          final isSelected = i == currentStep;
          return Expanded(
            child: InkWell(
              onTap: () => onStepTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  titles[i],
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
