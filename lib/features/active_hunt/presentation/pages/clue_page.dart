import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/models/checkpoint_model.dart';
import '../../../../shared/services/photo_verification_service.dart';
import '../../../../shared/widgets/hm_button.dart';
import '../../../../shared/widgets/hm_error_widget.dart';
import '../../../../shared/widgets/hm_loading.dart';
import '../../../../shared/widgets/hm_location_denied_widget.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_state.dart';
import '../../bloc/active_hunt_bloc.dart';
import '../../bloc/active_hunt_event.dart';
import '../../bloc/active_hunt_state.dart';
import '../../../../core/utils/proximity_calculator.dart';
import '../widgets/checkpoint_celebration.dart';
import '../widgets/hint_bottom_sheet.dart';
import '../widgets/hunt_progress_bar.dart';
import '../widgets/letter_box_input.dart';
import '../widgets/radar_compass_widget.dart';

class CluePage extends StatefulWidget {
  const CluePage({super.key, required this.huntId});

  final String huntId;

  @override
  State<CluePage> createState() => _CluePageState();
}

class _CluePageState extends State<CluePage> {
  late final TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) {
        final authState = ctx.read<AuthBloc>().state;
        final userId = authState is AuthAuthenticated ? authState.user.uid : '';
        return ActiveHuntBloc(
          huntRepository: sl(),
          progressRepository: sl(),
          locationService: sl(),
          analyticsService: sl(),
        )..add(ActiveHuntResumed(huntId: widget.huntId, userId: userId));
      },
      child: BlocListener<ActiveHuntBloc, ActiveHuntState>(
        listenWhen: (previous, current) =>
            current is ActiveHuntCompleted || current is ActiveHuntCheckpointUnlocked,
        listener: (context, state) {
          if (state is ActiveHuntCompleted) {
            context.go(
              RouteNames.huntCompletePath(
                widget.huntId,
                elapsedSeconds: state.totalTime.inSeconds,
                hintsUsed: state.hintsUsed,
              ),
            );
          } else if (state is ActiveHuntCheckpointUnlocked) {
            _answerController.clear();
          }
        },
        child: BlocBuilder<ActiveHuntBloc, ActiveHuntState>(
          builder: (context, state) => switch (state) {
            ActiveHuntInitial() || ActiveHuntLoading() =>
              const Scaffold(body: Center(child: HMLoading())),
            ActiveHuntError(:final message) => Scaffold(
                body: HMErrorWidget(message: message)),
            ActiveHuntLocationDenied(
              :final isPermanentlyDenied,
            ) =>
              Scaffold(
                appBar: AppBar(title: const Text('Location Required')),
                body: HMLocationDeniedWidget(
                  isPermanentlyDenied: isPermanentlyDenied,
                  onRetry: () => context
                      .read<ActiveHuntBloc>()
                      .add(const ActiveHuntLocationRetried()),
                ),
              ),
            ActiveHuntCountdown(:final secondsLeft) => Scaffold(
                body: Center(
                  child: Text(
                    '$secondsLeft',
                    style: AppTypography.displayLarge
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ActiveHuntCheckpointUnlocked(
              :final checkpointIndex,
              :final totalCheckpoints,
            ) =>
              CheckpointCelebration(
                checkpointIndex: checkpointIndex,
                totalCheckpoints: totalCheckpoints,
                onContinue: () {}, // Auto-dismissed by bloc after 2s
              ),
            ActiveHuntInProgress() => _ClueContent(
                state: state,
                controller: _answerController,
                onSubmit: () {
                  final typedText = _answerController.text;
                  debugPrint('🔍 [UI_DEBUG] Submit Button Tapped on CluePage!');
                  debugPrint('   ├─ Controller Text: "$typedText"');
                  context
                      .read<ActiveHuntBloc>()
                      .add(ActiveHuntCheckpointAnswerSubmitted(typedText));
                },
                onPhotoSubmit: () async {
                  final checkpoint = state.currentCheckpoint;
                  final distance = state.distanceToCheckpoint;
                  final picker = ImagePicker();

                  try {
                    final photo = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 85,
                    );
                    if (photo == null || !context.mounted) return;

                    final verification =
                        await PhotoVerificationService.verifyPhoto(
                      photoFile: File(photo.path),
                      checkpoint: checkpoint,
                      distanceInMeters: distance,
                    );

                    if (!context.mounted) return;

                    switch (verification) {
                      case PhotoVerificationFailure(:final message):
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.redAccent,
                            content: Text(message),
                          ),
                        );
                        // Block progression to next question when image verification fails!
                        return;

                      case PhotoVerificationSuccess():
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.green,
                            content: Text(
                              '🎉 Location & Photo Verified! Checkpoint Unlocked!',
                            ),
                          ),
                        );
                        context
                            .read<ActiveHuntBloc>()
                            .add(const ActiveHuntPhotoSubmitted());
                    }
                  } catch (e) {
                    debugPrint('Photo capture error: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.redAccent,
                          content: Text('❌ Error capturing photo: $e'),
                        ),
                      );
                    }
                  }
                },
                onHint: () => HintBottomSheet.show(context),
              ),
            // ActiveHuntCompleted is handled by BlocListener above (navigation).
            ActiveHuntCompleted() =>
              const Scaffold(body: Center(child: HMLoading())),
          },
        ),
      ),
    );
  }
}

class _ClueContent extends StatelessWidget {
  const _ClueContent({
    required this.state,
    required this.controller,
    required this.onSubmit,
    required this.onPhotoSubmit,
    required this.onHint,
  });

  final ActiveHuntInProgress state;
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onPhotoSubmit;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    final checkpoint = state.currentCheckpoint;
    final distance = state.distanceToCheckpoint;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Stop ${state.currentCheckpointIndex + 1} of ${state.checkpoints.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceM),
            child: Center(
              child: Text(
                _formatElapsed(state.elapsed.inSeconds),
                style: AppTypography.titleMedium
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HuntProgressBar(
                current: state.progress.currentCheckpointIndex,
                total: state.checkpoints.length,
              ),
              const SizedBox(height: AppDimensions.spaceL),
              if (distance != null) ...[
                Center(
                  child: RadarCompassWidget(
                    feedback: ProximityCalculator.calculate(
                      userLat: state.currentLat ?? 0.0,
                      userLng: state.currentLng ?? 0.0,
                      targetLat: checkpoint.latitude,
                      targetLng: checkpoint.longitude,
                      unlockRadiusMetres: checkpoint.unlockRadius.toDouble(),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),
              ],
              Text('Clue', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppDimensions.spaceS),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spaceL),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (checkpoint.imageUrl != null &&
                        checkpoint.imageUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM),
                        child: checkpoint.imageUrl!.startsWith('http')
                            ? Image.network(
                                checkpoint.imageUrl!,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) =>
                                    const SizedBox.shrink(),
                              )
                            : Image.asset(
                                checkpoint.imageUrl!,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) =>
                                    const SizedBox.shrink(),
                              ),
                      ),
                      const SizedBox(height: AppDimensions.spaceM),
                    ],
                    Text(checkpoint.clueText,
                        style: AppTypography.bodyLarge),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              if (checkpoint.type == CheckpointType.clue) ...[
                Text('Your Answer',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppDimensions.spaceM),
                LetterBoxInput(
                  answer: checkpoint.answer ?? '',
                  controller: controller,
                  isWrong: state.isAnswerWrong,
                  onChanged: (_) {},
                ),
                const SizedBox(height: AppDimensions.spaceXL),
                HMButton.primary(
                  label: 'Submit Answer',
                  onPressed: onSubmit,
                ),
              ] else if (checkpoint.type == CheckpointType.photoTask) ...[
                const SizedBox(height: AppDimensions.spaceM),
                HMButton.primary(
                  label: 'Complete Photo Task',
                  onPressed: onPhotoSubmit,
                  icon: const Icon(Icons.camera_alt_rounded),
                ),
              ],
              const SizedBox(height: AppDimensions.spaceM),
              if (state.remainingHints > 0)
                HMButton.outlined(
                  label:
                      'Hint (${state.remainingHints} left)',
                  onPressed: onHint,
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatElapsed(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
