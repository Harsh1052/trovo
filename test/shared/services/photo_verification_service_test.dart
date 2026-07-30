import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/shared/models/checkpoint_model.dart';
import 'package:huntermania/shared/services/photo_verification_service.dart';

void main() {
  group('PhotoVerificationService', () {
    const baseCheckpoint = CheckpointModel(
      checkpointId: 'cp_01',
      huntId: 'hunt_01',
      orderIndex: 0,
      clueText: 'Take a photo of the fountain sign.',
      hintText: 'Look near the entrance.',
      latitude: 21.292,
      longitude: 72.900,
      type: CheckpointType.photoTask,
      unlockRadius: 20,
      targetText: 'FOUNTAIN',
    );

    test('returns PhotoVerificationFailure when user is outside GPS unlock radius', () async {
      final dummyFile = File('test_resources/dummy.png');

      final result = await PhotoVerificationService.verifyPhoto(
        photoFile: dummyFile,
        checkpoint: baseCheckpoint,
        distanceInMeters: 45.0, // 45m > 20m unlock radius
      );

      expect(result, isA<PhotoVerificationFailure>());
      final failure = result as PhotoVerificationFailure;
      expect(failure.message, contains('Location Verification Failed'));
      expect(failure.message, contains('45m away'));
    });
  });
}
