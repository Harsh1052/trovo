import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../shared/models/hunt_model.dart';
import '../../bloc/hunt_creator_bloc.dart';
import '../../bloc/hunt_creator_event.dart';
import '../../bloc/hunt_creator_state.dart';

class StepDetailsView extends StatefulWidget {
  const StepDetailsView({super.key});

  @override
  State<StepDetailsView> createState() => _StepDetailsViewState();
}

class _StepDetailsViewState extends State<StepDetailsView> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _cityController;
  late TextEditingController _gardenController;
  late TextEditingController _coverController;

  HuntDifficulty _difficulty = HuntDifficulty.medium;
  int _duration = 45;
  bool _isPrivate = false;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<HuntCreatorBloc>();
    final state = bloc.state is HuntCreatorFormState
        ? bloc.state as HuntCreatorFormState
        : const HuntCreatorFormState();

    _titleController = TextEditingController(text: state.title);
    _descController = TextEditingController(text: state.description);
    _cityController = TextEditingController(text: state.city);
    _gardenController = TextEditingController(text: state.gardenName);
    _coverController = TextEditingController(text: state.coverImageUrl);

    _difficulty = state.difficulty;
    _duration = state.durationMinutes;
    _isPrivate = state.isPrivate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _cityController.dispose();
    _gardenController.dispose();
    _coverController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    context.read<HuntCreatorBloc>().add(
          HuntCreatorDetailsUpdated(
            title: _titleController.text,
            description: _descController.text,
            city: _cityController.text,
            gardenName: _gardenController.text,
            difficulty: _difficulty,
            durationMinutes: _duration,
            coverImageUrl: _coverController.text,
            isPrivate: _isPrivate,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 1: Story Details', style: AppTypography.headlineSmall),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            'Craft the title, narrative hook, and settings for your hunt.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spaceL),

          // ── Title ──────────────────────────────────────────────────────────
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Story Title *',
              hintText: 'e.g. The Forgotten Vault of Dutch Garden',
              prefixIcon: Icon(Icons.title_rounded),
            ),
            onChanged: (_) => _notifyChanges(),
          ),
          const SizedBox(height: AppDimensions.spaceM),

          // ── Description ────────────────────────────────────────────────────
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Story Description *',
              hintText: 'Describe the story hook and adventure for players...',
              prefixIcon: Icon(Icons.description_rounded),
            ),
            onChanged: (_) => _notifyChanges(),
          ),
          const SizedBox(height: AppDimensions.spaceM),

          // ── City & Garden Name ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City *',
                    prefixIcon: Icon(Icons.location_city_rounded),
                  ),
                  onChanged: (_) => _notifyChanges(),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: TextField(
                  controller: _gardenController,
                  decoration: const InputDecoration(
                    labelText: 'Landmark / Garden *',
                    hintText: 'e.g. Dutch Garden',
                    prefixIcon: Icon(Icons.park_rounded),
                  ),
                  onChanged: (_) => _notifyChanges(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceL),

          // ── Difficulty ─────────────────────────────────────────────────────
          Text('Difficulty Level', style: AppTypography.titleSmall),
          const SizedBox(height: AppDimensions.spaceS),
          SegmentedButton<HuntDifficulty>(
            segments: const [
              ButtonSegment(
                value: HuntDifficulty.easy,
                label: Text('Easy 😊'),
              ),
              ButtonSegment(
                value: HuntDifficulty.medium,
                label: Text('Medium 🧗'),
              ),
              ButtonSegment(
                value: HuntDifficulty.hard,
                label: Text('Hard 🏆'),
              ),
            ],
            selected: {_difficulty},
            onSelectionChanged: (set) {
              setState(() => _difficulty = set.first);
              _notifyChanges();
            },
          ),
          const SizedBox(height: AppDimensions.spaceL),

          // ── Duration ───────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estimated Duration', style: AppTypography.titleSmall),
              Text(
                '$_duration min',
                style: AppTypography.titleMedium
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
          Slider(
            value: _duration.toDouble(),
            min: 15,
            max: 180,
            divisions: 11,
            label: '$_duration min',
            onChanged: (val) {
              setState(() => _duration = val.toInt());
              _notifyChanges();
            },
          ),
          const SizedBox(height: AppDimensions.spaceM),

          // ── Cover Image URL ────────────────────────────────────────────────
          TextField(
            controller: _coverController,
            decoration: const InputDecoration(
              labelText: 'Cover Image URL (Optional)',
              hintText: 'https://...',
              prefixIcon: Icon(Icons.image_rounded),
            ),
            onChanged: (_) => _notifyChanges(),
          ),
          const SizedBox(height: AppDimensions.spaceL),

          // ── Private Event Toggle ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppDimensions.cardPadding),
            decoration: BoxDecoration(
              color: _isPrivate
                  ? AppColors.secondary.withValues(alpha: 0.1)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: _isPrivate ? AppColors.secondary : AppColors.greyLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                  color: _isPrivate ? AppColors.secondaryDark : AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPrivate ? 'Private Event Hunt 🔒' : 'Public Hunt 🌍',
                        style: AppTypography.titleSmall,
                      ),
                      Text(
                        _isPrivate
                            ? 'Requires a 6-character access code. Will not appear on public Home feed.'
                            : 'Visible to all players on the Home page feed.',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isPrivate,
                  onChanged: (val) {
                    setState(() => _isPrivate = val);
                    _notifyChanges();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXXL),
        ],
      ),
    );
  }
}
