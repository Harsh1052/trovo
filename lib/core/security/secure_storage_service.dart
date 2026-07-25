import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger.dart';

/// Secure Storage Service wrapping Android EncryptedSharedPreferences & iOS Keychain.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Test-only constructor with in-memory secure vault.
  SecureStorageService.testInstance({
    Map<String, String>? mockVault,
  })  : _storage = null,
        _mockVault = mockVault ?? {};

  final FlutterSecureStorage? _storage;
  Map<String, String>? _mockVault;

  static const String keyAuthToken = 'sec_auth_token';
  static const String keyRefreshToken = 'sec_refresh_token';
  static const String keyUserId = 'sec_user_id';

  /// Securely writes a key-value pair to hardware-backed storage.
  Future<void> write(String key, String value) async {
    if (_mockVault != null) {
      _mockVault![key] = value;
      return;
    }

    try {
      await _storage!.write(key: key, value: value);
    } catch (e) {
      AppLogger.w('Failed to write key "$key" to secure storage: $e',
          tag: 'SecureStorage');
    }
  }

  /// Securely reads a value from storage. Returns null if not found.
  Future<String?> read(String key) async {
    if (_mockVault != null) {
      return _mockVault![key];
    }

    try {
      return await _storage!.read(key: key);
    } catch (e) {
      AppLogger.w('Failed to read key "$key" from secure storage: $e',
          tag: 'SecureStorage');
      return null;
    }
  }

  /// Deletes a key from secure storage.
  Future<void> delete(String key) async {
    if (_mockVault != null) {
      _mockVault!.remove(key);
      return;
    }

    try {
      await _storage!.delete(key: key);
    } catch (e) {
      AppLogger.w('Failed to delete key "$key" from secure storage: $e',
          tag: 'SecureStorage');
    }
  }

  /// Clears all encrypted keys and resets session storage.
  Future<void> clearAll() async {
    if (_mockVault != null) {
      _mockVault!.clear();
      return;
    }

    try {
      await _storage!.deleteAll();
      AppLogger.i('Cleared all keys from secure storage', tag: 'SecureStorage');
    } catch (e) {
      AppLogger.w('Failed to clear secure storage: $e', tag: 'SecureStorage');
    }
  }
}
