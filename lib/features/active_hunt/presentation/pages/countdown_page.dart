import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';

class CountdownPage extends StatefulWidget {
  const CountdownPage({super.key, required this.huntId});

  final String huntId;

  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _count = 3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _startCountdown();
  }

  Future<void> _startCountdown() async {
    for (var i = 3; i >= 1; i--) {
      setState(() => _count = i);
      await _controller.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (mounted) context.go(RouteNames.cluePath(widget.huntId));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.2, end: 0.8).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          ),
          child: Text(
            '$_count',
            style: AppTypography.displayLarge.copyWith(
              color: Colors.white,
              fontSize: 120,
            ),
          ),
        ),
      ),
    );
  }
}
