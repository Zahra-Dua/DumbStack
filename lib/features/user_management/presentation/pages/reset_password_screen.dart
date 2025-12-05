import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/utils/media_query_helpers.dart';
import 'package:parental_control_app/features/user_management/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'package:parental_control_app/features/user_management/presentation/blocs/auth_bloc/auth_event.dart';
import 'package:parental_control_app/features/user_management/presentation/blocs/auth_bloc/auth_state.dart';

class ResetPasswordScreen extends StatefulWidget {
  // Pass oobCode if the app is opened directly via dynamic link
  final String? oobCode;
  const ResetPasswordScreen({super.key, this.oobCode});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeC = TextEditingController();
  final _newPassC = TextEditingController();
  final _confirmC = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.oobCode != null) {
      _codeC.text = widget.oobCode!;
    }
  }

  @override
  void dispose() {
    _codeC.dispose();
    _newPassC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  void _verifyCode() {
    final code = _codeC.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter code')));
      return;
    }
    context.read<AuthBloc>().add(VerifyResetCodeEvent(code: code));
  }

  void _confirmReset() {
    final code = _codeC.text.trim();
    final newPass = _newPassC.text;
    final confirm = _confirmC.text;
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be >= 6 chars')),
      );
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    context.read<AuthBloc>().add(
      ConfirmResetEvent(code: code, newPassword: newPass),
    );
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: mq.w(0.06)),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: mq.h(0.03)),
                Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: mq.sp(0.07),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: mq.h(0.02)),
                Text(
                  'Paste the code (oobCode) from the reset link or the link itself.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: mq.h(0.02)),
                TextField(
                  controller: _codeC,
                  decoration: const InputDecoration(
                    labelText: 'Reset Code (oobCode) or link',
                  ),
                ),
                SizedBox(height: mq.h(0.015)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkCyan,
                      padding: EdgeInsets.symmetric(vertical: mq.h(0.018)),
                    ),
                    child: Text(
                      'Verify Code',
                      style: TextStyle(fontSize: mq.sp(0.038)),
                    ),
                  ),
                ),
                SizedBox(height: mq.h(0.02)),
                TextField(
                  controller: _newPassC,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password'),
                ),
                SizedBox(height: mq.h(0.015)),
                TextField(
                  controller: _confirmC,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                ),
                SizedBox(height: mq.h(0.02)),
                BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is AuthSuccess) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(state.message)));
                      Navigator.pop(context); // go back to login
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
                        onPressed: _confirmReset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepTeal,
                          padding: EdgeInsets.symmetric(vertical: mq.h(0.018)),
                        ),
                        child: Text(
                          'Reset Password',
                          style: TextStyle(fontSize: mq.sp(0.038)),
                        ),
                      ),
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
