import 'package:flutter/material.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/utils/media_query_helpers.dart';
import 'package:parental_control_app/core/design_system/app_design_system.dart';
import 'package:parental_control_app/core/widgets/modern_text_field.dart';
import 'package:parental_control_app/core/widgets/modern_button.dart';
import 'package:parental_control_app/core/widgets/modern_app_bar.dart';
import '../../presentation/widgets/responsive_logo.dart';
import 'parent_qr_screen.dart';

class AddChildFormScreen extends StatefulWidget {
  const AddChildFormScreen({super.key});

  @override
  State<AddChildFormScreen> createState() => _AddChildFormScreenState();
}

class _AddChildFormScreenState extends State<AddChildFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedGender = 'Male';
  final List<String> _selectedHobbies = [];
  final List<String> _availableHobbies = [
    'Reading', 'Sports', 'Music', 'Art', 'Gaming', 'Dancing',
    'Cooking', 'Photography', 'Swimming', 'Cycling', 'Drawing',
  ];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _toggleHobby(String hobby) {
    setState(() {
      if (_selectedHobbies.contains(hobby)) {
        _selectedHobbies.remove(hobby);
      } else {
        _selectedHobbies.add(hobby);
      }
    });
  }

  void _generateQR() {
    if (_formKey.currentState?.validate() ?? false) {
      final childData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'gender': _selectedGender,
        'hobbies': _selectedHobbies,
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ParentQRScreen(childData: childData),
        ),
      );
    }
  }

  Widget _buildAnimatedField({
    required Widget child,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: const ModernAppBar(title: 'Add Child'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.lightCyan,
              AppColors.lightCyan.withOpacity(0.8),
              Colors.white,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Logo
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.darkCyan.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: ResponsiveLogo(sizeFactor: 0.12),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Title
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        'Add Child Information',
                        style: AppDesignSystem.headline1.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Fill in your child\'s details to generate QR code',
                      style: AppDesignSystem.bodyMedium.copyWith(
                        color: AppColors.textLight,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.darkCyan.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildAnimatedField(
                            index: 0,
                            child: ModernTextField(
                              controller: _firstNameController,
                              label: 'First Name',
                              hint: 'Enter first name',
                              prefixIcon: Icons.person_outline_rounded,
                              textCapitalization: TextCapitalization.words,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter first name';
                                }
                                return null;
                              },
                            ),
                          ),
                          
                          const SizedBox(height: AppDesignSystem.spacingM),
                          
                          _buildAnimatedField(
                            index: 1,
                            child: ModernTextField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              hint: 'Enter last name',
                              prefixIcon: Icons.person_outline_rounded,
                              textCapitalization: TextCapitalization.words,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter last name';
                                }
                                return null;
                              },
                            ),
                          ),
                          
                          const SizedBox(height: AppDesignSystem.spacingM),
                          
                          _buildAnimatedField(
                            index: 2,
                            child: ModernTextField(
                              controller: _nameController,
                              label: 'Display Name',
                              hint: 'Enter display name',
                              prefixIcon: Icons.badge_outlined,
                              textCapitalization: TextCapitalization.words,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter display name';
                                }
                                return null;
                              },
                            ),
                          ),
                          
                          const SizedBox(height: AppDesignSystem.spacingM),
                          
                          _buildAnimatedField(
                            index: 3,
                            child: ModernTextField(
                              controller: _ageController,
                              label: 'Age',
                              hint: 'Enter age',
                              prefixIcon: Icons.cake_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter age';
                                }
                                final age = int.tryParse(v.trim());
                                if (age == null || age < 1 || age > 18) {
                                  return 'Please enter valid age (1-18)';
                                }
                                return null;
                              },
                            ),
                          ),
                          
                          const SizedBox(height: AppDesignSystem.spacingM),
                          
                          // Gender Selection
                          _buildAnimatedField(
                            index: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gender',
                                  style: AppDesignSystem.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildGenderOption('Male', Icons.male),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildGenderOption('Female', Icons.female),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildGenderOption('Other', Icons.person),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: AppDesignSystem.spacingM),
                          
                          // Hobbies Selection
                          _buildAnimatedField(
                            index: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hobbies (Optional)',
                                  style: AppDesignSystem.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _availableHobbies.map((hobby) {
                                    final isSelected = _selectedHobbies.contains(hobby);
                                    return FilterChip(
                                      label: Text(hobby),
                                      selected: isSelected,
                                      onSelected: (_) => _toggleHobby(hobby),
                                      selectedColor: AppColors.darkCyan.withOpacity(0.2),
                                      checkmarkColor: AppColors.darkCyan,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Generate QR Button
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.darkCyan.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ModernButton(
                          text: 'Generate QR Code',
                          icon: Icons.qr_code_rounded,
                          onPressed: _generateQR,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.darkCyan.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.darkCyan : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.darkCyan : AppColors.textLight,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              gender,
              style: TextStyle(
                color: isSelected ? AppColors.darkCyan : AppColors.textLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

