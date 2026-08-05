import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/shared/models/checkpoint_model.dart';
import 'package:huntermania/shared/models/hunt_model.dart';

void main() {
  group('UGC Creator Verification Models', () {
    test('HuntModel parses creator and private fields correctly', () {
      final json = {
        'huntId': 'ugc_123',
        'title': 'Custom Surat Food Crawl',
        'description': 'A private food hunt around Surat old city.',
        'city': 'Surat',
        'gardenName': 'Nanpura Food Circle',
        'difficulty': 'easy',
        'durationMinutes': 30,
        'checkpointCount': 2,
        'isFree': true,
        'price': 0,
        'coverImageUrl': '',
        'startLatitude': 21.1959,
        'startLongitude': 72.8124,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'creatorUserId': 'user_abc',
        'creatorName': 'Harsh',
        'isPrivate': true,
        'accessCode': 'FOOD99',
      };

      final hunt = HuntModel.fromJson(json);

      expect(hunt.isUgc, isTrue);
      expect(hunt.creatorUserId, 'user_abc');
      expect(hunt.creatorName, 'Harsh');
      expect(hunt.isPrivate, isTrue);
      expect(hunt.accessCode, 'FOOD99');
    });

    test('CheckpointModel handles OCR targetText correctly for photo tasks', () {
      const cp = CheckpointModel(
        checkpointId: 'cp_ugc_1',
        huntId: 'ugc_123',
        orderIndex: 0,
        clueText: 'Take a photo of the sign.',
        hintText: '',
        latitude: 21.1959,
        longitude: 72.8124,
        type: CheckpointType.photoTask,
        targetText: 'SURAT VAULT',
      );

      expect(cp.isPhotoTask, isTrue);
      expect(cp.targetText, 'SURAT VAULT');
    });
  });
}
