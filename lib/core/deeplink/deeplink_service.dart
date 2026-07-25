import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import '../utils/logger.dart';

/// Serverless Deep Link Handler for HunterMania.
///
/// Parses incoming App Links (`https://huntermania-app.web.app/hunts/:id`)
/// and Custom Schemes (`trovo://hunts/:id`), steering GoRouter to the destination.
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  /// Initializes deep link listeners and attaches the active GoRouter instance.
  Future<void> init(GoRouter router) async {
    try {
      // 1. Handle cold-start initial deep link (if launched via link)
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri, router);
      }

      // 2. Handle warm stream deep links (while app is running)
      _sub = _appLinks.uriLinkStream.listen(
        (uri) => _handleUri(uri, router),
        onError: (err) {
          AppLogger.w('Deep link stream error: $err', tag: 'DeepLink');
        },
      );
    } catch (e) {
      AppLogger.w('Failed to initialize deep links: $e', tag: 'DeepLink');
    }
  }

  void _handleUri(Uri uri, GoRouter router) {
    final route = parseRoutePath(uri);
    if (route != null) {
      AppLogger.i('Deep link navigating to: $route', tag: 'DeepLink');
      router.go(route);
    }
  }

  /// Parses a deep link Uri into a valid GoRouter path string.
  /// Returns null if the Uri is unhandled.
  static String? parseRoutePath(Uri uri) {
    final path = uri.path;

    // Handles: https://huntermania-app.web.app/hunts/:id or trovo://hunts/:id
    if (path.startsWith('/hunts/') && path.length > 7) {
      return path; // e.g. /hunts/panchvati_garden
    }

    if (path == '/profile' || path == '/paywall') {
      return path;
    }

    // Handles custom scheme host mapping: trovo://hunts/123 -> /hunts/123
    if (uri.scheme == 'trovo' && uri.host == 'hunts') {
      final huntId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (huntId.isNotEmpty) {
        return '/hunts/$huntId';
      }
    }

    return null;
  }

  /// Disposes stream subscriptions.
  void dispose() {
    _sub?.cancel();
  }
}
