import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';

/// Manages interactive in-app feature showcases & spotlight onboarding tooltips.
class ShowcaseService {
  ShowcaseService({SharedPreferences? prefs}) : _prefs = prefs;

  /// Test-only constructor with in-memory storage.
  ShowcaseService.testInstance({
    Map<String, bool>? mockFlags,
  })  : _prefs = null,
        _mockFlags = mockFlags ?? {};

  final SharedPreferences? _prefs;
  Map<String, bool>? _mockFlags;

  static const String featureRadarHud = 'showcase_seen_radar_hud';
  static const String featureOfflineSync = 'showcase_seen_offline_sync';
  static const String featurePhotoTask = 'showcase_seen_photo_task';

  /// Returns true if the user has NOT seen the feature showcase spotlight yet.
  Future<bool> shouldShowShowcase(String featureKey) async {
    if (_mockFlags != null) {
      return !(_mockFlags![featureKey] ?? false);
    }

    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(featureKey) ?? false;
      return !hasSeen;
    } catch (e) {
      AppLogger.w('Failed to read showcase state: $e', tag: 'Showcase');
      return false;
    }
  }

  /// Marks the feature showcase spotlight as completed.
  Future<void> markShowcaseCompleted(String featureKey) async {
    if (_mockFlags != null) {
      _mockFlags![featureKey] = true;
      return;
    }

    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setBool(featureKey, true);
      AppLogger.i('Marked showcase completed for: $featureKey', tag: 'Showcase');
    } catch (e) {
      AppLogger.w('Failed to save showcase state: $e', tag: 'Showcase');
    }
  }

  /// Resets all showcase flags (useful for testing or app resets).
  Future<void> resetAllShowcases() async {
    if (_mockFlags != null) {
      _mockFlags!.clear();
      return;
    }

    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove(featureRadarHud);
      await prefs.remove(featureOfflineSync);
      await prefs.remove(featurePhotoTask);
    } catch (e) {
      AppLogger.w('Failed to reset showcases: $e', tag: 'Showcase');
    }
  }
}
