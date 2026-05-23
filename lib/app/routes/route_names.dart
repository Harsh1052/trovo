abstract final class RouteNames {
  // ── Onboarding ────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/login';

  // ── Main ──────────────────────────────────────────────────────────────────
  static const String home = '/home';
  static const String profile = '/profile';

  // ── Hunt detail ───────────────────────────────────────────────────────────
  static const String huntDetail = '/hunt/:huntId';

  // ── Active hunt ───────────────────────────────────────────────────────────
  static const String countdown = '/hunt/:huntId/countdown';
  static const String clue = '/hunt/:huntId/clue';
  static const String photoTask = '/hunt/:huntId/photo';
  static const String huntMap = '/hunt/:huntId/map';

  // ── Hunt complete ─────────────────────────────────────────────────────────
  static const String huntComplete = '/hunt/:huntId/complete';

  // ── Paywall ───────────────────────────────────────────────────────────────
  static const String paywall = '/paywall';

  // ── Path helpers ──────────────────────────────────────────────────────────
  static String huntDetailPath(String huntId) => '/hunt/$huntId';
  static String countdownPath(String huntId) => '/hunt/$huntId/countdown';
  static String cluePath(String huntId) => '/hunt/$huntId/clue';
  static String photoTaskPath(String huntId) => '/hunt/$huntId/photo';
  static String huntMapPath(String huntId) => '/hunt/$huntId/map';
  static String huntCompletePath(
    String huntId, {
    int elapsedSeconds = 0,
    int hintsUsed = 0,
  }) =>
      '/hunt/$huntId/complete?elapsed=$elapsedSeconds&hints=$hintsUsed';
}
