import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';

/// Full-screen brand splash shown while [AuthBloc] performs its initial session
/// check ([AuthCheckRequested]).
///
/// This page does **not** navigate itself. The [GoRouter] redirect in
/// [buildAppRouter] drives the transition:
///   - [AuthAuthenticated]   → /home
///   - [AuthUnauthenticated] → /login
///
/// Keeping navigation out of here avoids timing races between the splash delay
/// and the async auth check.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_rounded, size: 72, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'HunterMania',
              style: AppTypography.headlineLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Colors.white54,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
