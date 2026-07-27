import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/hm_button.dart';
import '../../../../shared/widgets/hm_loading.dart';
import '../../bloc/squad_bloc.dart';
import '../../bloc/squad_event.dart';
import '../../bloc/squad_state.dart';

/// Page where the host creates a new squad room for a hunt.
///
/// On success, navigates to [SquadLobbyPage] with the generated room code.
class CreateSquadPage extends StatelessWidget {
  const CreateSquadPage({
    super.key,
    required this.huntId,
    required this.userId,
    required this.displayName,
  });

  final String huntId;
  final String userId;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SquadBloc(squadRepository: sl())
        ..add(SquadCreateRequested(
          huntId: huntId,
          hostUserId: userId,
          hostDisplayName: displayName,
        )),
      child: BlocConsumer<SquadBloc, SquadState>(
        listener: (context, state) {
          if (state is SquadLobby) {
            context.go(RouteNames.squadLobbyPath(state.session.squadId));
          }
        },
        builder: (context, state) => switch (state) {
          SquadError(:final message) => Scaffold(
              appBar: AppBar(title: const Text('Create Squad')),
              body: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.all(AppDimensions.pagePadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 64, color: AppColors.error),
                      const SizedBox(height: AppDimensions.spaceM),
                      Text(message,
                          style: AppTypography.bodyLarge,
                          textAlign: TextAlign.center),
                      const SizedBox(height: AppDimensions.spaceL),
                      HMButton.primary(
                        label: 'Try Again',
                        onPressed: () => context.read<SquadBloc>().add(
                              SquadCreateRequested(
                                huntId: huntId,
                                hostUserId: userId,
                                hostDisplayName: displayName,
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _ => const Scaffold(
              body: Center(child: HMLoading()),
            ),
        },
      ),
    );
  }
}
