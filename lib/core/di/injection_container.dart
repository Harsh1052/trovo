import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../config/constants/app_constants.dart';
import '../../features/active_hunt/bloc/active_hunt_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/home/bloc/home_bloc.dart';
import '../../features/hunt_complete/bloc/hunt_complete_cubit.dart';
import '../../features/hunt_detail/bloc/hunt_detail_cubit.dart';
import '../../features/paywall/bloc/paywall_cubit.dart';
import '../../features/profile/bloc/profile_cubit.dart';
import '../network/connectivity_checker.dart';
import '../../shared/repositories/auth_repository.dart';
import '../../shared/repositories/cached_hunt_repository.dart';
import '../../shared/repositories/hunt_repository.dart';
import '../../shared/repositories/payment_repository.dart';
import '../../shared/repositories/progress_repository.dart';
import '../../shared/services/analytics_service.dart';
import '../../shared/services/location_service.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/services/offline_hunt_cache_service.dart';
import '../../shared/services/purchase_service.dart';
import '../config/remote_config_service.dart';
import '../deeplink/deeplink_service.dart';
import '../error/crashlytics_observer.dart';

/// Global service locator. Access via `sl<T>()` anywhere in the app.
final GetIt sl = GetIt.instance;

/// Registers all dependencies in the correct order.
///
/// Must be called from [main] after [FirebaseConfig.initialize] and before
/// [runApp]. The function is idempotent — safe to call in tests after
/// [GetIt.reset].
Future<void> initDependencies() async {
  // ── 1. External: Firebase service singletons ──────────────────────────────
  // Registered as eager singletons because Firebase is already initialized by
  // FirebaseConfig.initialize() before this function is called.
  sl.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  sl.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  sl.registerSingleton<FirebaseStorage>(FirebaseStorage.instance);
  sl.registerSingleton<FirebaseAnalytics>(FirebaseAnalytics.instance);
  sl.registerSingleton<GoogleSignIn>(
    GoogleSignIn(scopes: const ['email', 'profile']),
  );

  // ── 2. Core ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ConnectivityChecker>(
    () => ConnectivityChecker(),
  );

  // ── 3. Services ───────────────────────────────────────────────────────────
  // LocationService — no Firebase dependency, owns the GPS stream lifecycle.
  sl.registerSingleton<LocationService>(LocationService());

  // PurchaseService — configure RevenueCat before registering the instance.
  // Replace the API key constants in AppConstants with your real RC keys.
  await PurchaseService.configure(
    apiKey: Platform.isIOS
        ? AppConstants.rcApiKeyIos
        : AppConstants.rcApiKeyAndroid,
  );
  sl.registerSingleton<PurchaseService>(PurchaseService());

  // AnalyticsService — receives FirebaseAnalytics from the locator so the
  // real instance flows in production and a fake can be swapped in tests.
  sl.registerSingleton<AnalyticsService>(
    AnalyticsService(analytics: sl<FirebaseAnalytics>()),
  );

  // ── Foundational Services ───────────────────────────────────────────────
  sl.registerSingleton<RemoteConfigService>(RemoteConfigService());
  sl.registerSingleton<DeepLinkService>(DeepLinkService());
  sl.registerSingleton<NotificationService>(NotificationService());
  sl.registerSingleton<CrashlyticsObserver>(CrashlyticsObserver());

  // ── 4. Repositories (lazy singletons bound to their abstractions) ─────────
  // Binding to the abstract type means feature code never imports a Firebase
  // class. Swap the backend by changing only the registration below.

  sl.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepository(
      auth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
      googleSignIn: sl<GoogleSignIn>(),
    ),
  );

  // ── Offline cache ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<OfflineHuntCacheService>(
    () => OfflineHuntCacheService(),
  );

  sl.registerLazySingleton<HuntRepository>(
    () => CachedHuntRepository(
      remote: FirebaseHuntRepository(
        firestore: sl<FirebaseFirestore>(),
      ),
      cache: sl<OfflineHuntCacheService>(),
      connectivity: sl<ConnectivityChecker>(),
    ),
  );

  sl.registerLazySingleton<ProgressRepository>(
    () => FirebaseProgressRepository(
      firestore: sl<FirebaseFirestore>(),
    ),
  );

  sl.registerLazySingleton<PaymentRepository>(
    () => RevenueCatPaymentRepository(
      purchaseService: sl<PurchaseService>(),
    ),
  );

  // ── 5. BLoCs / Cubits (factory = fresh instance per BlocProvider) ─────────
  // Factories are cheap — GetIt constructs a new BLoC each time sl() is called,
  // which matches the lifecycle of the screen that owns the BlocProvider.

  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );

  sl.registerFactory<HomeBloc>(
    () => HomeBloc(huntRepository: sl<HuntRepository>()),
  );

  sl.registerFactory<ActiveHuntBloc>(
    () => ActiveHuntBloc(
      huntRepository: sl<HuntRepository>(),
      progressRepository: sl<ProgressRepository>(),
      locationService: sl<LocationService>(),
      analyticsService: sl<AnalyticsService>(),
    ),
  );

  sl.registerFactory<HuntDetailCubit>(
    () => HuntDetailCubit(
      huntRepository: sl<HuntRepository>(),
      paymentRepository: sl<PaymentRepository>(),
    ),
  );

  sl.registerFactory<PaywallCubit>(
    () => PaywallCubit(paymentRepository: sl<PaymentRepository>()),
  );

  sl.registerFactory<ProfileCubit>(
    () => ProfileCubit(
      authRepository: sl<AuthRepository>(),
      progressRepository: sl<ProgressRepository>(),
      huntRepository: sl<HuntRepository>(),
    ),
  );

  sl.registerFactory<HuntCompleteCubit>(
    () => HuntCompleteCubit(huntRepository: sl<HuntRepository>()),
  );
}
