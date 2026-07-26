import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';

/// Renders one box per character in [answer], filling left-to-right
/// as the user types.
class LetterBoxInput extends StatefulWidget {
  const LetterBoxInput({
    super.key,
    required this.answer,
    required this.onChanged,
    this.controller,
    this.isWrong = false,
  });

  final String answer;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final bool isWrong;

  @override
  State<LetterBoxInput> createState() => _LetterBoxInputState();
}

class _LetterBoxInputState extends State<LetterBoxInput> {
  late final TextEditingController _internalController;
  final int _maxLength = 30;

  TextEditingController get _controller => widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    widget.onChanged(_controller.text);
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(LetterBoxInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.answer != widget.answer) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cleanAnswer = widget.answer.replaceAll(' ', '');
    final answerLen = cleanAnswer.isEmpty ? 1 : cleanAnswer.length.clamp(1, _maxLength);
    final typed = _controller.text.replaceAll(' ', '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppDimensions.spaceXS,
          runSpacing: AppDimensions.spaceXS,
          children: List.generate(answerLen, (i) {
            final filled = i < typed.length;
            final isError = widget.isWrong && filled;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 44,
              decoration: BoxDecoration(
                color: isError
                    ? AppColors.errorLight
                    : filled
                        ? AppColors.primaryLight.withValues(alpha: 0.15)
                        : AppColors.greyExtraLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color: isError
                      ? AppColors.error
                      : filled
                          ? AppColors.primary
                          : AppColors.greyLight,
                  width: filled ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  filled ? typed[i].toUpperCase() : '',
                  style: AppTypography.titleMedium.copyWith(
                    color: isError ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        TextField(
          controller: _controller,
          maxLength: (widget.answer.length + 5).clamp(1, 40),
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Type your answer…',
            counterText: '',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
          style: AppTypography.bodyLarge,
        ),
      ],
    );
  }
}
