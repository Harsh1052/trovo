import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../shared/widgets/hm_button.dart';
import '../widgets/onboarding_slide.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    OnboardingSlideData(
      icon: Icons.explore_rounded,
      title: 'Explore Real Places',
      description:
          'Follow GPS clues through stunning gardens and hidden gems in your city.',
    ),
    OnboardingSlideData(
      icon: Icons.lightbulb_outline_rounded,
      title: 'Solve the Clues',
      description:
          'Crack riddles, answer questions, and snap photos at each checkpoint.',
    ),
    OnboardingSlideData(
      icon: Icons.emoji_events_rounded,
      title: 'Claim Your Victory',
      description:
          'Complete hunts, earn badges, and share your adventure with friends.',
    ),
  ];

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => OnboardingSlide(data: _slides[i]),
              ),
            ),
            _DotIndicator(count: _slides.length, current: _currentPage),
            const SizedBox(height: AppDimensions.spaceL),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePadding),
              child: HMButton.primary(
                label: _currentPage == _slides.length - 1
                    ? 'Get Started'
                    : 'Next',
                onPressed: _next,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),
          ],
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == current ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == current ? AppColors.primary : AppColors.greyLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
        ),
      ),
    );
  }
}
