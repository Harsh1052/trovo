import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../shared/widgets/hm_button.dart';
import '../../../../shared/widgets/hm_loading.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../auth/bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitEmailPassword() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthSignInRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // AuthBloc is provided at app level — no local BlocProvider needed.
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Navigation is handled by the GoRouter redirect; this listener only
        // surfaces error messages to the user.
        if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimensions.spaceXXL),
                    Text('Welcome back', style: AppTypography.headlineLarge),
                    const SizedBox(height: AppDimensions.spaceS),
                    Text(
                      'Sign in to continue your hunt',
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppDimensions.spaceXXL),

                    // ── Email / password form ─────────────────────────────────
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) =>
                                v != null && v.contains('@')
                                    ? null
                                    : 'Enter a valid email',
                          ),
                          const SizedBox(height: AppDimensions.spaceM),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) =>
                                v != null && v.length >= 6
                                    ? null
                                    : 'Minimum 6 characters',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spaceXL),
                    isLoading
                        ? const Center(child: HMLoading())
                        : HMButton.primary(
                            label: 'Sign In',
                            onPressed: _submitEmailPassword,
                          ),

                    // ── Divider ───────────────────────────────────────────────
                    const SizedBox(height: AppDimensions.spaceL),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spaceM),
                          child: Text(
                            'or',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceL),

                    // ── Google sign-in ────────────────────────────────────────
                    HMButton.outlined(
                      label: 'Continue with Google',
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
                      onPressed: isLoading
                          ? null
                          : () => context
                              .read<AuthBloc>()
                              .add(const AuthGoogleSignInRequested()),
                    ),

                    const SizedBox(height: AppDimensions.spaceM),

                    // ── Guest sign-in ─────────────────────────────────────────
                    Center(
                      child: HMButton.text(
                        label: 'Continue as Guest',
                        onPressed: isLoading
                            ? null
                            : () => context
                                .read<AuthBloc>()
                                .add(const AuthGuestSignInRequested()),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spaceXL),

                    // ── Register link ─────────────────────────────────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'New here? ',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => context.push(RouteNames.register),
                            child: Text(
                              'Create an account',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
