import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/result.dart';
import '../../../../shared/repositories/creator_repository.dart';
import '../../../../shared/widgets/hm_button.dart';

/// Dialog for players to enter a 6-character private access code (e.g. `PARTY9`).
class JoinByCodeDialog extends StatefulWidget {
  const JoinByCodeDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const JoinByCodeDialog(),
    );
  }

  @override
  State<JoinByCodeDialog> createState() => _JoinByCodeDialogState();
}

class _JoinByCodeDialogState extends State<JoinByCodeDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length < 6) {
      setState(() => _error = 'Please enter a 6-character code.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = sl<CreatorRepository>();
    final result = await repo.fetchHuntByAccessCode(code);

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case Success(:final data):
        Navigator.of(context).pop();
        context.push(RouteNames.huntDetailPath(data.huntId));
      case Err(:final failure):
        setState(() => _error = failure.userFriendlyMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.key_rounded, color: AppColors.secondary),
          const SizedBox(width: AppDimensions.spaceS),
          const Text('Enter Private Code'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Have a private hunt code from a friend or event organizer?',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppDimensions.spaceM),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            ],
            decoration: InputDecoration(
              counterText: '',
              hintText: 'PARTY9',
              errorText: _error,
            ),
            onSubmitted: (_) => _submitCode(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        HMButton.primary(
          label: 'Open Hunt',
          isLoading: _loading,
          onPressed: _submitCode,
        ),
      ],
    );
  }
}
