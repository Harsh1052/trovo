import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/utils/logger.dart';

class AppBlocObserver extends BlocObserver {
  static const _tag = 'BlocObserver';

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    AppLogger.d('onCreate -- ${bloc.runtimeType}', tag: _tag);
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    AppLogger.d('onEvent -- ${bloc.runtimeType}: $event', tag: _tag);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    AppLogger.d(
      'onChange -- ${bloc.runtimeType}\n'
      '  current: ${change.currentState}\n'
      '  next:    ${change.nextState}',
      tag: _tag,
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    AppLogger.d(
      'onTransition -- ${bloc.runtimeType}\n'
      '  event:   ${transition.event}\n'
      '  current: ${transition.currentState}\n'
      '  next:    ${transition.nextState}',
      tag: _tag,
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    AppLogger.e(
      'onError -- ${bloc.runtimeType}',
      tag: _tag,
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    AppLogger.d('onClose -- ${bloc.runtimeType}', tag: _tag);
  }
}
