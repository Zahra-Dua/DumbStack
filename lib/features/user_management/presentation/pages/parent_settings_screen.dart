import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/utils/media_query_helpers.dart';
import 'package:parental_control_app/core/utils/error_message_helper.dart';
import 'login_screen.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  String _currentFirstName = '';
  String _currentLastName = '';
  String _currentEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get user data from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('parents')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          _currentFirstName = data['firstName'] ?? '';
          _currentLastName = data['lastName'] ?? '';
          _currentEmail = data['email'] ?? user.email ?? '';
          
          // If firstName/lastName not found, try to split from name field
          if (_currentFirstName.isEmpty && _currentLastName.isEmpty) {
            final fullName = data['name'] ?? user.displayName ?? '';
            final nameParts = fullName.trim().split(' ');
            if (nameParts.isNotEmpty) {
              _currentFirstName = nameParts[0];
              _currentLastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
            }
          }
          
          _firstNameController.text = _currentFirstName;
          _lastNameController.text = _currentLastName;
          _emailController.text = _currentEmail;
        } else {
          final fullName = user.displayName ?? '';
          final nameParts = fullName.trim().split(' ');
          _currentFirstName = nameParts.isNotEmpty ? nameParts[0] : '';
          _currentLastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          _currentEmail = user.email ?? '';
          
          _firstNameController.text = _currentFirstName;
          _lastNameController.text = _currentLastName;
          _emailController.text = _currentEmail;
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = '$firstName $lastName'.trim();
      
      // Update name in Firebase Auth
      await user.updateDisplayName(fullName);
      
      // Update email in Firebase Auth
      if (_emailController.text.trim() != _currentEmail) {
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
      // Update data in Firestore
      await FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .update({
        'firstName': firstName,
        'lastName': lastName,
        'name': fullName, // Keep for backward compatibility
        'email': _emailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update current values
      _currentFirstName = firstName;
      _currentLastName = lastName;
      _currentEmail = _emailController.text.trim();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(_newPasswordController.text);
      
      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('Error changing password: $e');
      String errorMessage = 'Error changing password';
      
      if (e.toString().contains('wrong-password')) {
        errorMessage = 'Current password is incorrect';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'New password is too weak';
      } else if (e.toString().contains('requires-recent-login')) {
        errorMessage = 'Please log out and log in again to change password';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_type');
      await prefs.remove('parent_uid');
      await prefs.remove('child_uid');
      await prefs.remove('child_name');

      // Navigate to login screen and clear navigation stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMessage;
        if (ErrorMessageHelper.isNetworkError(e)) {
          errorMessage = ErrorMessageHelper.networkErrorLogout;
        } else {
          errorMessage = 'Logout failed: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        title: const Text(
          'Settings',
          style: TextStyle(color: AppColors.black),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(mq.w(0.06)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Section
                    _buildSectionCard(
                      title: 'Profile Information',
                      icon: Icons.person,
                      children: [
                        _buildTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter first name';
                            }
                            if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                              return 'First name must contain only alphabetic characters';
                            }
                            if (value.trim().length > 50) {
                              return 'First name must not exceed 50 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: mq.h(0.02)),
                        _buildTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter last name';
                            }
                            if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                              return 'Last name must contain only alphabetic characters';
                            }
                            if (value.trim().length > 50) {
                              return 'Last name must not exceed 50 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: mq.h(0.02)),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: mq.h(0.03)),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _updateProfile,
                            icon: const Icon(Icons.save),
                            label: const Text('Update Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkCyan,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: mq.h(0.02)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: mq.h(0.03)),
                    
                    // Password Section
                    _buildSectionCard(
                      title: 'Change Password',
                      icon: Icons.lock,
                      children: [
                        _buildTextField(
                          controller: _currentPasswordController,
                          label: 'Current Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isPasswordVisible: _isPasswordVisible,
                          onTogglePassword: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter current password';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: mq.h(0.02)),
                        _buildTextField(
                          controller: _newPasswordController,
                          label: 'New Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isPasswordVisible: _isNewPasswordVisible,
                          onTogglePassword: () {
                            setState(() {
                              _isNewPasswordVisible = !_isNewPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter new password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: mq.h(0.02)),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm New Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isPasswordVisible: _isConfirmPasswordVisible,
                          onTogglePassword: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm new password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: mq.h(0.03)),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _changePassword,
                            icon: const Icon(Icons.security),
                            label: const Text('Change Password'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: mq.h(0.02)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: mq.h(0.03)),
                    
                    // Account Info Section
                    _buildSectionCard(
                      title: 'Account Information',
                      icon: Icons.info_outline,
                      children: [
                        _buildInfoRow(
                          icon: Icons.person,
                          label: 'User ID',
                          value: FirebaseAuth.instance.currentUser?.uid ?? 'N/A',
                        ),
                        SizedBox(height: mq.h(0.01)),
                        _buildInfoRow(
                          icon: Icons.email,
                          label: 'Current Email',
                          value: _currentEmail,
                        ),
                        SizedBox(height: mq.h(0.01)),
                        _buildInfoRow(
                          icon: Icons.calendar_today,
                          label: 'Account Created',
                          value: FirebaseAuth.instance.currentUser?.metadata.creationTime?.toString().split(' ')[0] ?? 'N/A',
                        ),
                      ],
                    ),
                    
                    SizedBox(height: mq.h(0.03)),
                    
                    // Logout Section
                    _buildSectionCard(
                      title: 'Account Actions',
                      icon: Icons.logout,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _logout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: mq.h(0.02)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: mq.h(0.01)),
                        Text(
                          'Logging out will sign you out of the app. Your data will remain saved and you can log in again anytime.',
                          style: TextStyle(
                            fontSize: mq.sp(0.035),
                            color: AppColors.textLight,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final mq = MQ(context);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mq.w(0.05)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(mq.w(0.03)),
                decoration: BoxDecoration(
                  color: AppColors.darkCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.darkCyan,
                  size: 24,
                ),
              ),
              SizedBox(width: mq.w(0.03)),
              Text(
                title,
                style: TextStyle(
                  fontSize: mq.sp(0.05),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: mq.h(0.02)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !isPasswordVisible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.darkCyan),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.darkCyan,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.darkCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.darkCyan, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
