import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../config/theme/app_theme.dart';
import '../core/di/injection_container.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_event.dart';
import 'routes/app_router.dart';

/// Root widget. Owns the [AuthBloc] and [GoRouter] singletons so both are
/// available for the lifetime of the app and are disposed together.
///
/// [AuthBloc] is provided via [BlocProvider.value] above [MaterialApp.router],
/// which means every route's [BuildContext] can reach it with
/// `context.read<AuthBloc>()` or `context.watch<AuthBloc>()`.
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthBloc _authBloc;
  late final AuthChangeNotifier _authNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Create once. The factory registration in GetIt means each sl() call
    // returns a fresh instance — we hold the reference ourselves.
    _authBloc = sl<AuthBloc>()..add(const AuthCheckRequested());
    _authNotifier = AuthChangeNotifier(_authBloc);
    _router = buildAppRouter(
      authBloc: _authBloc,
      refreshListenable: _authNotifier,
    );
  }

  @override
  void dispose() {
    _authBloc.close();
    _authNotifier.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'HunterMania',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
