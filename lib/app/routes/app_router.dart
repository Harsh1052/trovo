import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/active_hunt/presentation/pages/clue_page.dart';
import '../../features/active_hunt/presentation/pages/countdown_page.dart';
import '../../features/active_hunt/presentation/pages/hunt_map_page.dart';
import '../../features/active_hunt/presentation/pages/photo_task_page.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/hunt_complete/presentation/pages/hunt_complete_page.dart';
import '../../features/hunt_detail/presentation/pages/hunt_detail_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/paywall/presentation/pages/paywall_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/squad/presentation/pages/create_squad_page.dart';
import '../../features/squad/presentation/pages/join_squad_page.dart';
import '../../features/squad/presentation/pages/squad_lobby_page.dart';
import 'route_names.dart';

/// Builds the app's [GoRouter] instance.
///
/// The router is owned by [App] (a [StatefulWidget]) so it can be disposed
/// correctly. Passing [authBloc] directly avoids any context-lookup issues
/// inside the redirect callback.
GoRouter buildAppRouter({
  required AuthBloc authBloc,
  required ChangeNotifier refreshListenable,
}) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshListenable,
    redirect: (_, state) => _authRedirect(authBloc.state, state),
    routes: _routes,
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}

// ── Redirect logic ────────────────────────────────────────────────────────────

/// Pure function — takes the current [AuthState] and the [GoRouterState] and
/// returns the destination path, or null to allow the navigation.
///
/// State machine:
///   AuthInitial / AuthLoading  → hold on splash (auth check is in flight)
///   AuthAuthenticated          → block public routes, redirect to home
///   AuthUnauthenticated/Error  → block protected routes, redirect to login
String? _authRedirect(AuthState authState, GoRouterState routerState) {
  final location = routerState.matchedLocation;

  // While the session check is in flight, keep the splash visible.
  if (authState is AuthInitial || authState is AuthLoading) {
    return location == RouteNames.splash ? null : RouteNames.splash;
  }

  final isAuthenticated = authState is AuthAuthenticated;

  // Splash is the gateway — once we know the auth status, leave it.
  if (location == RouteNames.splash) {
    return isAuthenticated ? RouteNames.home : RouteNames.login;
  }

  const publicRoutes = {RouteNames.onboarding, RouteNames.login, RouteNames.register};


  if (!isAuthenticated && !publicRoutes.contains(location)) {
    return RouteNames.login;
  }

  if (isAuthenticated && publicRoutes.contains(location)) {
    return RouteNames.home;
  }

  return null;
}

// ── Route table ───────────────────────────────────────────────────────────────

final List<RouteBase> _routes = [
  // ── Onboarding ──────────────────────────────────────────────────────────────
  GoRoute(
    path: RouteNames.splash,
    builder: (_, _) => const SplashPage(),
  ),
  GoRoute(
    path: RouteNames.onboarding,
    builder: (_, _) => const OnboardingPage(),
  ),

  // ── Auth ─────────────────────────────────────────────────────────────────────
  GoRoute(
    path: RouteNames.login,
    builder: (_, _) => const LoginPage(),
  ),
  GoRoute(
    path: RouteNames.register,
    builder: (_, _) => const RegisterPage(),
  ),

  // ── Main shell ────────────────────────────────────────────────────────────────
  GoRoute(
    path: RouteNames.home,
    builder: (_, _) => const HomePage(),
  ),
  GoRoute(
    path: RouteNames.profile,
    builder: (_, _) => const ProfilePage(),
  ),

  // ── Hunt flow ─────────────────────────────────────────────────────────────────
  GoRoute(
    path: '/hunt/:huntId',
    builder: (_, state) => HuntDetailPage(
      huntId: state.pathParameters['huntId']!,
    ),
    routes: [
      GoRoute(
        path: 'countdown',
        builder: (_, state) => CountdownPage(
          huntId: state.pathParameters['huntId']!,
        ),
      ),
      GoRoute(
        path: 'clue',
        builder: (_, state) => CluePage(
          huntId: state.pathParameters['huntId']!,
        ),
      ),
      GoRoute(
        path: 'photo',
        builder: (_, state) => PhotoTaskPage(
          huntId: state.pathParameters['huntId']!,
        ),
      ),
      GoRoute(
        path: 'map',
        builder: (_, state) => HuntMapPage(
          huntId: state.pathParameters['huntId']!,
        ),
      ),
      GoRoute(
        path: 'squad/create',
        builder: (_, state) => CreateSquadPage(
          huntId: state.pathParameters['huntId']!,
          userId: state.uri.queryParameters['userId'] ?? '',
          displayName: state.uri.queryParameters['name'] ?? '',
        ),
      ),
      GoRoute(
        path: 'complete',
        builder: (_, state) => HuntCompletePage(
          huntId: state.pathParameters['huntId']!,
          elapsedSeconds:
              int.tryParse(state.uri.queryParameters['elapsed'] ?? '') ?? 0,
          hintsUsed:
              int.tryParse(state.uri.queryParameters['hints'] ?? '') ?? 0,
        ),
      ),
    ],
  ),

  // ── Squad flow ──────────────────────────────────────────────────────────────────
  GoRoute(
    path: RouteNames.squadJoin,
    builder: (_, state) => JoinSquadPage(
      userId: state.uri.queryParameters['userId'] ?? '',
      displayName: state.uri.queryParameters['name'] ?? '',
    ),
  ),
  GoRoute(
    path: RouteNames.squadLobby,
    builder: (_, state) => SquadLobbyPage(
      squadId: state.pathParameters['squadId']!,
      userId: state.uri.queryParameters['userId'] ?? '',
      displayName: state.uri.queryParameters['name'] ?? '',
    ),
  ),

  // ── Paywall ───────────────────────────────────────────────────────────────────
  GoRoute(
    path: RouteNames.paywall,
    builder: (_, _) => const PaywallPage(),
  ),
];

// ── Auth change notifier ──────────────────────────────────────────────────────

/// Bridges [AuthBloc]'s stream to [ChangeNotifier] so GoRouter re-evaluates
/// its redirect whenever the auth state changes.
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(AuthBloc bloc) {
    _sub = bloc.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
