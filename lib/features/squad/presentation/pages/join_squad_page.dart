import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/hm_button.dart';
import '../../bloc/squad_bloc.dart';
import '../../bloc/squad_event.dart';
import '../../bloc/squad_state.dart';

/// Page where a player enters a 4-digit room code to join an existing squad.
class JoinSquadPage extends StatefulWidget {
  const JoinSquadPage({
    super.key,
    required this.userId,
    required this.displayName,
  });

  final String userId;
  final String displayName;

  @override
  State<JoinSquadPage> createState() => _JoinSquadPageState();
}

class _JoinSquadPageState extends State<JoinSquadPage> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isJoining = false;

  String get _code => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SquadBloc(squadRepository: sl()),
      child: BlocConsumer<SquadBloc, SquadState>(
        listener: (context, state) {
          if (state is SquadLobby) {
            context.go(RouteNames.squadLobbyPath(state.session.squadId));
          }
          if (state is SquadError) {
            setState(() => _isJoining = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Join Squad'),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.pagePadding),
                child: Column(
                  children: [
                    const SizedBox(height: AppDimensions.spaceXXL),

                    // ── Icon ──────────────────────────────────────────
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.group_add_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spaceL),

                    Text(
                      'Enter Room Code',
                      style: AppTypography.headlineSmall,
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    Text(
                      'Ask your squad captain for the\n4-digit room code',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppDimensions.spaceXL),

                    // ── 4-digit code input ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        return Container(
                          width: 64,
                          height: 72,
                          margin: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spaceS),
                          child: TextField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: AppTypography.headlineLarge
                                .copyWith(color: AppColors.primary),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusM),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusM),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (v) => _onDigitChanged(i, v),
                          ),
                        );
                      }),
                    ),

                    const Spacer(),

                    // ── Join button ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: HMButton.primary(
                        label: 'Join Squad',
                        isLoading: _isJoining,
                        icon: const Icon(Icons.login_rounded,
                            color: Colors.white),
                        onPressed: _code.length == 4
                            ? () {
                                setState(() => _isJoining = true);
                                context.read<SquadBloc>().add(
                                      SquadJoinRequested(
                                        roomCode: _code,
                                        userId: widget.userId,
                                        displayName: widget.displayName,
                                      ),
                                    );
                              }
                            : null,
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spaceM),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
