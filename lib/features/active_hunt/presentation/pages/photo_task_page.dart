import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../shared/widgets/hm_button.dart';

class PhotoTaskPage extends StatefulWidget {
  const PhotoTaskPage({super.key, required this.huntId});

  final String huntId;

  @override
  State<PhotoTaskPage> createState() => _PhotoTaskPageState();
}

class _PhotoTaskPageState extends State<PhotoTaskPage> {
  String? _imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Challenge')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Photo Task',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                'Take a photo at this location to continue.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: double.infinity,
                  height: 240,
                  decoration: BoxDecoration(
                    color: AppColors.greyExtraLight,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(
                        color: AppColors.greyLight,
                        style: BorderStyle.solid),
                  ),
                  child: _imagePath != null
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusL),
                          child: Image.asset(_imagePath!,
                              fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_outlined,
                                size: 48, color: AppColors.greyLight),
                            const SizedBox(height: AppDimensions.spaceS),
                            Text('Tap to take photo',
                                style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                ),
              ),
              const Spacer(),
              HMButton.primary(
                label: 'Submit Photo',
                onPressed: _imagePath != null ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickPhoto() {
    // TODO: integrate image_picker
    setState(() => _imagePath = 'placeholder');
  }

  void _submit() {
    // TODO: dispatch ActiveHuntPhotoSubmitted event
  }
}
