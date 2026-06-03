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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthSignUpRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
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

                    // back button
                    GestureDetector(
                      onTap: () => context.canPop() ? context.pop() : null,
                      child: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),

                    const SizedBox(height: AppDimensions.spaceL),

                    Text('Create account', style: AppTypography.headlineLarge),
                    const SizedBox(height: AppDimensions.spaceS),
                    Text(
                      'Join the hunt. It\'s free.',
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: AppDimensions.spaceXXL),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Name
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().length < 2) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: AppDimensions.spaceM),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) {
                              if (v == null || !v.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: AppDimensions.spaceM),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 6) {
                                return 'Minimum 6 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: AppDimensions.spaceM),

                          // Confirm password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spaceXL),

                    isLoading
                        ? const Center(child: HMLoading())
                        : HMButton.primary(
                            label: 'Create Account',
                            onPressed: _submit,
                            width: double.infinity,
                          ),

                    const SizedBox(height: AppDimensions.spaceL),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => context.go(RouteNames.login),
                            child: Text(
                              'Sign in',
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
