import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _userType;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userType = prefs.getString('user_type');
    });
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // Password validation function
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }

  Future<void> _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_userType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User type not found. Please select again.')),
        );
        return;
      }
      
      // Check network connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your network and try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      context.read<AuthBloc>().add(
        SignUpEvent(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim(),
          password: _pass.text,
          userType: _userType!,
        ),
      );
    }
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
          child: Form(
            key: _formKey,
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
                  'Create Account',
                  style: AppDesignSystem.headline1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDesignSystem.spacingS),
                Text(
                  'Sign up as ${_userType?.toUpperCase() ?? "USER"}',
                  style: AppDesignSystem.bodyMedium.copyWith(
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDesignSystem.spacingXXL),
                
                // Form Fields
                ModernTextField(
                  controller: _firstName,
                  label: 'First Name',
                  hint: 'Enter your first name',
                  prefixIcon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter first name';
                    }
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim())) {
                      return 'First name must contain only alphabetic characters';
                    }
                    if (v.trim().length > 50) {
                      return 'First name must not exceed 50 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDesignSystem.spacingM),
                ModernTextField(
                  controller: _lastName,
                  label: 'Last Name',
                  hint: 'Enter your last name',
                  prefixIcon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter last name';
                    }
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim())) {
                      return 'Last name must contain only alphabetic characters';
                    }
                    if (v.trim().length > 50) {
                      return 'Last name must not exceed 50 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDesignSystem.spacingM),
                ModernTextField(
                  controller: _email,
                  label: 'Email Address',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter email address';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDesignSystem.spacingM),
                ModernTextField(
                  controller: _pass,
                  label: 'Password',
                  hint: 'Create a strong password',
                  prefixIcon: Icons.lock_outline_rounded,
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
                  validator: _validatePassword,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppDesignSystem.spacingM,
                    top: AppDesignSystem.spacingXS,
                  ),
                  child: Text(
                    'Min 8 chars, 1 uppercase, 1 number, 1 special char',
                    style: AppDesignSystem.bodySmall,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacingM),
                ModernTextField(
                  controller: _confirm,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: !_isConfirmPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: AppColors.textLight,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (v != _pass.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDesignSystem.spacingXL),
                
                // Signup Button
                BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is AuthSuccess) {
                      Navigator.pop(context);
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
                    if (state is AuthLoading) {
                      return Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: AppDesignSystem.spacingM),
                          Text(
                            'Creating account...',
                            style: AppDesignSystem.bodyLarge,
                          ),
                          const SizedBox(height: AppDesignSystem.spacingXS),
                          Text(
                            'Please wait, this may take a moment',
                            style: AppDesignSystem.bodySmall,
                          ),
                        ],
                      );
                    }
                    return ModernButton(
                      text: 'Create Account',
                      icon: Icons.person_add_rounded,
                      onPressed: _signup,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
