import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../shared/models/checkpoint_model.dart';
import '../../../../shared/widgets/hm_button.dart';
import '../../bloc/hunt_creator_bloc.dart';
import '../../bloc/hunt_creator_event.dart';
import '../../bloc/hunt_creator_state.dart';

class StepCheckpointsView extends StatelessWidget {
  const StepCheckpointsView({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<HuntCreatorBloc>();
    final state = bloc.state as HuntCreatorFormState;
    final checkpoints = state.checkpoints;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Step 2: Checkpoints', style: AppTypography.headlineSmall),
                  Text(
                    'Add 2 to 10 stops. Drag handles (=) to reorder.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.chipPadding,
                  vertical: AppDimensions.spaceXXS,
                ),
                decoration: BoxDecoration(
                  color: (checkpoints.length >= 2 && checkpoints.length <= 10)
                      ? AppColors.successLight
                      : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  '${checkpoints.length}/10 Stops',
                  style: AppTypography.labelSmall.copyWith(
                    color: (checkpoints.length >= 2 && checkpoints.length <= 10)
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),

          // ── Checkpoint List ────────────────────────────────────────────────
          Expanded(
            child: checkpoints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 64,
                          color: AppColors.greyLight,
                        ),
                        const SizedBox(height: AppDimensions.spaceM),
                        Text(
                          'No checkpoints added yet.',
                          style: AppTypography.bodyLarge,
                        ),
                        const SizedBox(height: AppDimensions.spaceS),
                        Text(
                          'Tap below to add your first clue or photo stop!',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: checkpoints.length,
                    onReorder: (oldIdx, newIdx) {
                      context.read<HuntCreatorBloc>().add(
                            HuntCreatorCheckpointsReordered(
                              oldIndex: oldIdx,
                              newIndex: newIdx,
                            ),
                          );
                    },
                    itemBuilder: (context, index) {
                      final cp = checkpoints[index];
                      return Card(
                        key: ValueKey('cp_${index}_${cp.clueText.hashCode}'),
                        margin: const EdgeInsets.only(bottom: AppDimensions.spaceS),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            cp.clueText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall,
                          ),
                          subtitle: Text(
                            '${cp.displayLabel} • (${cp.latitude.toStringAsFixed(4)}, ${cp.longitude.toStringAsFixed(4)})',
                            style: AppTypography.bodySmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 20),
                                onPressed: () => _showCheckpointDialog(
                                  context,
                                  existingIndex: index,
                                  checkpoint: cp,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 20, color: AppColors.error),
                                onPressed: () {
                                  context.read<HuntCreatorBloc>().add(
                                        HuntCreatorCheckpointRemoved(index),
                                      );
                                },
                              ),
                              const Icon(Icons.drag_handle_rounded,
                                  color: AppColors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppDimensions.spaceM),

          // ── Add Checkpoint Button ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: HMButton.outlined(
              label: '+ Add Checkpoint Stop',
              icon: const Icon(Icons.add_location_alt_rounded),
              onPressed: checkpoints.length < 10
                  ? () => _showCheckpointDialog(context)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckpointDialog(
    BuildContext context, {
    int? existingIndex,
    CheckpointModel? checkpoint,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _AddCheckpointDialog(
        existingIndex: existingIndex,
        checkpoint: checkpoint,
        onSave: (cp) {
          if (existingIndex != null) {
            context.read<HuntCreatorBloc>().add(
                  HuntCreatorCheckpointUpdated(
                    index: existingIndex,
                    checkpoint: cp,
                  ),
                );
          } else {
            context
                .read<HuntCreatorBloc>()
                .add(HuntCreatorCheckpointAdded(cp));
          }
        },
      ),
    );
  }
}

class _AddCheckpointDialog extends StatefulWidget {
  const _AddCheckpointDialog({
    this.existingIndex,
    this.checkpoint,
    required this.onSave,
  });

  final int? existingIndex;
  final CheckpointModel? checkpoint;
  final ValueChanged<CheckpointModel> onSave;

  @override
  State<_AddCheckpointDialog> createState() => _AddCheckpointDialogState();
}

class _AddCheckpointDialogState extends State<_AddCheckpointDialog> {
  late TextEditingController _clueController;
  late TextEditingController _answerController;
  late TextEditingController _targetTextController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _hintController;
  late TextEditingController _funFactController;

  CheckpointType _type = CheckpointType.clue;
  double _radius = 20;

  @override
  void initState() {
    super.initState();
    final cp = widget.checkpoint;

    _clueController = TextEditingController(text: cp?.clueText ?? '');
    _answerController = TextEditingController(text: cp?.answer ?? '');
    _targetTextController = TextEditingController(text: cp?.targetText ?? '');
    _latController =
        TextEditingController(text: (cp?.latitude ?? 21.1959).toString());
    _lngController =
        TextEditingController(text: (cp?.longitude ?? 72.8124).toString());
    _hintController = TextEditingController(text: cp?.hintText ?? '');
    _funFactController = TextEditingController(text: cp?.funFact ?? '');

    _type = cp?.type ?? CheckpointType.clue;
    _radius = (cp?.unlockRadius ?? 20).toDouble();
  }

  @override
  void dispose() {
    _clueController.dispose();
    _answerController.dispose();
    _targetTextController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _hintController.dispose();
    _funFactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingIndex != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Checkpoint Stop' : 'Add Checkpoint Stop'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Task Type ────────────────────────────────────────────────────
            Text('Task Type', style: AppTypography.titleSmall),
            const SizedBox(height: AppDimensions.spaceXS),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Text Clue 🧩'),
                  selected: _type == CheckpointType.clue,
                  onSelected: (val) {
                    if (val) setState(() => _type = CheckpointType.clue);
                  },
                ),
                const SizedBox(width: AppDimensions.spaceS),
                ChoiceChip(
                  label: const Text('Photo Challenge 📷'),
                  selected: _type == CheckpointType.photoTask,
                  onSelected: (val) {
                    if (val) setState(() => _type = CheckpointType.photoTask);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceM),

            // ── Clue Text ────────────────────────────────────────────────────
            TextField(
              controller: _clueController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Clue / Riddle Text *',
                hintText: 'Enter the riddle for players to solve...',
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),

            // ── Verification Answer / Target Text ────────────────────────────
            if (_type == CheckpointType.clue) ...[
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(
                  labelText: 'Correct Answer *',
                  hintText: 'e.g. DIAMOND',
                ),
              ),
            ] else ...[
              TextField(
                controller: _targetTextController,
                decoration: const InputDecoration(
                  labelText: 'Target Text/Sign (for OCR Photo check)',
                  hintText: 'e.g. DUTCH VAULT or A',
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.spaceM),

            // ── Lat & Lng ────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Latitude *'),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceS),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Longitude *'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceM),

            // ── Unlock Radius ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Unlock Radius', style: AppTypography.titleSmall),
                Text('${_radius.toInt()}m', style: AppTypography.bodyMedium),
              ],
            ),
            Slider(
              value: _radius,
              min: 10,
              max: 50,
              divisions: 8,
              onChanged: (val) => setState(() => _radius = val),
            ),
            const SizedBox(height: AppDimensions.spaceM),

            // ── Hint & Fun Fact ──────────────────────────────────────────────
            TextField(
              controller: _hintController,
              decoration: const InputDecoration(
                labelText: 'Hint Text (Optional)',
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            TextField(
              controller: _funFactController,
              decoration: const InputDecoration(
                labelText: 'Fun Fact / Lore (Optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final clue = _clueController.text.trim();
            final lat = double.tryParse(_latController.text.trim()) ?? 0.0;
            final lng = double.tryParse(_lngController.text.trim()) ?? 0.0;

            if (clue.isEmpty || lat == 0.0 || lng == 0.0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter valid clue text and coordinates.'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }

            final cp = CheckpointModel(
              checkpointId: widget.checkpoint?.checkpointId ?? '',
              huntId: widget.checkpoint?.huntId ?? '',
              orderIndex: widget.checkpoint?.orderIndex ?? 0,
              clueText: clue,
              hintText: _hintController.text.trim(),
              latitude: lat,
              longitude: lng,
              type: _type,
              answer: _type == CheckpointType.clue
                  ? _answerController.text.trim()
                  : null,
              targetText: _type == CheckpointType.photoTask
                  ? _targetTextController.text.trim()
                  : null,
              unlockRadius: _radius.toInt(),
              funFact: _funFactController.text.trim(),
            );

            widget.onSave(cp);
            Navigator.of(context).pop();
          },
          child: Text(isEdit ? 'Update' : 'Add Stop'),
        ),
      ],
    );
  }
}
