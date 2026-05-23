import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';

class CheckpointCelebration extends StatefulWidget {
  const CheckpointCelebration({
    super.key,
    required this.checkpointIndex,
    required this.totalCheckpoints,
    required this.onContinue,
  });

  final int checkpointIndex;
  final int totalCheckpoints;
  final VoidCallback onContinue;

  @override
  State<CheckpointCelebration> createState() =>
      _CheckpointCelebrationState();
}

class _CheckpointCelebrationState extends State<CheckpointCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scaleAnim = CurvedAnimation(
        parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast =
        widget.checkpointIndex == widget.totalCheckpoints - 1;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 64, color: Colors.white),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceL),
              Text(
                isLast ? 'Final Stop!' : 'Checkpoint!',
                style: AppTypography.headlineLarge
                    .copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                isLast
                    ? 'You found the last clue!'
                    : '${widget.checkpointIndex + 1} of ${widget.totalCheckpoints} complete',
                style: AppTypography.bodyLarge
                    .copyWith(color: Colors.white70),
              ),
              const SizedBox(height: AppDimensions.spaceXXL),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.dark,
                ),
                onPressed: widget.onContinue,
                child: Text(
                    isLast ? 'See Results' : 'Next Clue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
