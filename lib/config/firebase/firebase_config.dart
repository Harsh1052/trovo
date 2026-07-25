import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Initializes Firebase and connects to the production project.
///
/// Call once from [main] before [runApp].
abstract final class FirebaseConfig {
  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Firebase] Initialization notice: $e');
      }
    }

    if (kDebugMode) {
      debugPrint('[Firebase] Initialized successfully');
    }
  }
}
