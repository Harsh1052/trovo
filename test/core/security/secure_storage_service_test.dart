import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/core/security/secure_storage_service.dart';

void main() {
  group('SecureStorageService', () {
    late SecureStorageService service;

    setUp(() {
      service = SecureStorageService.testInstance();
    });

    test('writes and reads secure token successfully', () async {
      await service.write(SecureStorageService.keyAuthToken, 'secret_token_123');

      final token = await service.read(SecureStorageService.keyAuthToken);
      expect(token, 'secret_token_123');
    });

    test('deletes key from secure vault', () async {
      await service.write(SecureStorageService.keyAuthToken, 'secret_token_123');
      await service.delete(SecureStorageService.keyAuthToken);

      final token = await service.read(SecureStorageService.keyAuthToken);
      expect(token, isNull);
    });

    test('clearAll wipes out all saved keys', () async {
      await service.write(SecureStorageService.keyAuthToken, 'token_1');
      await service.write(SecureStorageService.keyUserId, 'user_99');

      await service.clearAll();

      expect(await service.read(SecureStorageService.keyAuthToken), isNull);
      expect(await service.read(SecureStorageService.keyUserId), isNull);
    });
  });
}
