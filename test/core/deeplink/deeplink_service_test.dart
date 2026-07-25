import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/core/deeplink/deeplink_service.dart';

void main() {
  group('DeepLinkService.parseRoutePath', () {
    test('parses web HTTPS hunt detail link correctly', () {
      final uri = Uri.parse('https://huntermania-app.web.app/hunts/panchvati_garden');
      final route = DeepLinkService.parseRoutePath(uri);
      expect(route, '/hunts/panchvati_garden');
    });

    test('parses custom scheme trovo://hunts/sula_vineyards link correctly', () {
      final uri = Uri.parse('trovo://hunts/sula_vineyards');
      final route = DeepLinkService.parseRoutePath(uri);
      expect(route, '/hunts/sula_vineyards');
    });

    test('parses profile path correctly', () {
      final uri = Uri.parse('https://huntermania-app.web.app/profile');
      final route = DeepLinkService.parseRoutePath(uri);
      expect(route, '/profile');
    });

    test('returns null for unrecognized or invalid URIs', () {
      final uri = Uri.parse('https://huntermania-app.web.app/unknown_route');
      final route = DeepLinkService.parseRoutePath(uri);
      expect(route, isNull);
    });
  });
}
