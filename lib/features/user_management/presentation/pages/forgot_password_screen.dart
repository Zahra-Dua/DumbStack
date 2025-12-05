import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/utils/media_query_helpers.dart';
import 'package:parental_control_app/features/user_management/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'package:parental_control_app/features/user_management/presentation/blocs/auth_bloc/auth_event.dart';
import 'package:parental_control_app/features/user_management/presentation/blocs/auth_bloc/auth_state.dart';
import 'password_reset_success_screen.dart';
import '../widgets/responsive_logo.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailC = TextEditingController();

  @override
  void dispose() {
    _emailC.dispose();
    super.dispose();
  }

  void _sendReset() {
    context.read<AuthBloc>().add(SendResetEmailEvent(email: _emailC.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);
    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: AppBar(
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: mq.w(0.06)),
          child: Column(
            children: [
              SizedBox(height: mq.h(0.03)),
              ResponsiveLogo(sizeFactor: 0.16),
              SizedBox(height: mq.h(0.02)),
              Text(
                'Forgot Password',
                style: TextStyle(
                  fontSize: mq.sp(0.07),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: mq.h(0.02)),
              Text(
                'Enter your email and we will send a link to reset your password.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: mq.h(0.02)),
              TextField(
                controller: _emailC,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: mq.h(0.03)),
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthSuccess) {
                    // Show success page that instructs user to check their email
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PasswordResetSuccessScreen(),
                      ),
                    );
                  } else if (state is AuthFailure) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.error)));
                  }
                },
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const CircularProgressIndicator();
                  }
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendReset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkCyan,
                        padding: EdgeInsets.symmetric(vertical: mq.h(0.018)),
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(fontSize: mq.sp(0.038)),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: mq.h(0.02)), // Extra space at bottom
            ],
          ),
        ),
      ),
    );
  }
}
