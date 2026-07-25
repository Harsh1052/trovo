import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../shared/widgets/hm_button.dart';
import '../../../active_hunt/bloc/active_hunt_bloc.dart';
import '../../../active_hunt/bloc/active_hunt_event.dart';
import '../../../active_hunt/bloc/active_hunt_state.dart';

class PhotoTaskPage extends StatefulWidget {
  const PhotoTaskPage({super.key, required this.huntId});

  final String huntId;

  @override
  State<PhotoTaskPage> createState() => _PhotoTaskPageState();
}

class _PhotoTaskPageState extends State<PhotoTaskPage> {
  final _picker = ImagePicker();
  File? _photo;
  bool _picking = false;

  Future<void> _pickPhoto() async {
    if (_picking) return;
    setState(() => _picking = true);

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked != null && mounted) {
        setState(() => _photo = File(picked.path));
      }
    } catch (_) {
      // camera unavailable in simulator — fall back to gallery
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked != null && mounted) {
        setState(() => _photo = File(picked.path));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _submit() {
    context.read<ActiveHuntBloc>().add(const ActiveHuntPhotoSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActiveHuntBloc, ActiveHuntState>(
      listener: (context, state) {
        // BLoC handles navigation once the checkpoint advances —
        // no extra logic needed here.
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Photo Challenge')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Photo Task',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Text(
                  'Take a photo at this location to continue.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppDimensions.spaceXL),

                // ── Photo preview / tap target ──────────────────────────────
                GestureDetector(
                  onTap: _picking ? null : _pickPhoto,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 240,
                    decoration: BoxDecoration(
                      color: _photo != null
                          ? Colors.transparent
                          : AppColors.greyExtraLight,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusL),
                      border: Border.all(
                        color: _photo != null
                            ? AppColors.primary
                            : AppColors.greyLight,
                      ),
                    ),
                    child: _picking
                        ? const Center(child: CircularProgressIndicator())
                        : _photo != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusL),
                                child: Image.file(
                                  _photo!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_alt_outlined,
                                      size: 48, color: AppColors.greyLight),
                                  const SizedBox(height: AppDimensions.spaceS),
                                  Text(
                                    'Tap to take photo',
                                    style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                  ),
                ),

                if (_photo != null) ...[
                  const SizedBox(height: AppDimensions.spaceS),
                  // retake option
                  Center(
                    child: TextButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retake'),
                    ),
                  ),
                ],

                const Spacer(),

                HMButton.primary(
                  label: 'Submit Photo',
                  onPressed: _photo != null ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
