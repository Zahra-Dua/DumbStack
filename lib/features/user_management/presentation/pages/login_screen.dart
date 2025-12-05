import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/utils/media_query_helpers.dart';
import 'package:parental_control_app/core/design_system/app_design_system.dart';
import 'package:parental_control_app/core/widgets/modern_button.dart';
import 'package:parental_control_app/core/widgets/modern_text_field.dart';
import 'package:parental_control_app/core/widgets/modern_app_bar.dart';
import 'package:parental_control_app/features/user_management/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'package:parental_control_app/features/user_management/presentation/blocs/auth_bloc/auth_event.dart';
import 'package:parental_control_app/features/user_management/presentation/blocs/auth_bloc/auth_state.dart';
import '../../presentation/widgets/responsive_logo.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  void _login() {
    context.read<AuthBloc>().add(
      SignInEvent(email: _emailC.text.trim(), password: _passC.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: const ModernAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacingL,
            vertical: AppDesignSystem.spacingXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Section
              Center(
                child: ResponsiveLogo(sizeFactor: 0.18),
              ),
              const SizedBox(height: AppDesignSystem.spacingXL),
              
              // Title Section
              Text(
                'Welcome Back',
                style: AppDesignSystem.headline1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDesignSystem.spacingS),
              Text(
                'Sign in to continue protecting your family',
                style: AppDesignSystem.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDesignSystem.spacingXXL),
              
              // Form Section
              ModernTextField(
                controller: _emailC,
                label: 'Email',
                hint: 'Enter your email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDesignSystem.spacingM),
              ModernTextField(
                controller: _passC,
                label: 'Password',
                hint: 'Enter your password',
                prefixIcon: Icons.lock_outline,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: AppColors.textLight,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDesignSystem.spacingS),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  style: AppDesignSystem.textButtonStyle(),
                  child: Text(
                    'Forgot Password?',
                    style: AppDesignSystem.labelMedium.copyWith(
                      color: AppColors.darkCyan,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDesignSystem.spacingXL),
              
              // Login Button
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthSuccess) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentHomeScreen(),
                      ),
                    );
                  } else if (state is AuthFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDesignSystem.radiusM,
                          ),
                        ),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return ModernButton(
                    text: 'Sign In',
                    icon: Icons.login_rounded,
                    onPressed: _login,
                    isLoading: state is AuthLoading,
                  );
                },
              ),
              const SizedBox(height: AppDesignSystem.spacingL),
              
              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppDesignSystem.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignupScreen(),
                      ),
                    ),
                    style: AppDesignSystem.textButtonStyle(),
                    child: Text(
                      'Sign up',
                      style: AppDesignSystem.labelLarge.copyWith(
                        color: AppColors.darkCyan,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
