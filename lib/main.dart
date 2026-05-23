import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app.dart';
import 'app/app_bloc_observer.dart';
import 'config/firebase/firebase_config.dart';
import 'core/di/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await FirebaseConfig.initialize();

  // Dependency injection
  await initDependencies();

  // Global BLoC observer (debug logging)
  Bloc.observer = AppBlocObserver();

  runApp(const App());
}
