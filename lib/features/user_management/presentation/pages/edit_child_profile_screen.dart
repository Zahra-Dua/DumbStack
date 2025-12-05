import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../../../core/utils/error_message_helper.dart';
import '../../data/datasources/firebase_parent_service.dart';

class EditChildProfileScreen extends StatefulWidget {
  final String childId;
  final String parentId;

  const EditChildProfileScreen({
    super.key,
    required this.childId,
    required this.parentId,
  });

  @override
  State<EditChildProfileScreen> createState() => _EditChildProfileScreenState();
}

class _EditChildProfileScreenState extends State<EditChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  
  String _selectedGender = 'Male';
  final List<String> _selectedHobbies = [];
  bool _isLoading = false;
  bool _isLoadingData = true;
  
  final List<String> _availableHobbies = [
    'Reading', 'Sports', 'Music', 'Art', 'Gaming', 
    'Cooking', 'Dancing', 'Swimming', 'Cycling', 'Photography'
  ];

  final FirebaseParentService _parentService = FirebaseParentService();

  @override
  void initState() {
    super.initState();
    _loadChildData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadChildData() async {
    setState(() => _isLoadingData = true);
    
    try {
      final child = await _parentService.getChild(widget.parentId, widget.childId);
      
      if (child != null) {
        // Get child data from Firestore directly to get age, gender, hobbies, firstName, lastName
        final doc = await FirebaseFirestore.instance
            .collection('parents')
            .doc(widget.parentId)
            .collection('children')
            .doc(widget.childId)
            .get();
        
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          
          // Get firstName and lastName, or split from name field
          String firstName = data['firstName'] ?? '';
          String lastName = data['lastName'] ?? '';
          
          if (firstName.isEmpty && lastName.isEmpty) {
            // Try to split from name field
            final fullName = data['name'] ?? child.name ?? '';
            final nameParts = fullName.trim().split(' ');
            if (nameParts.isNotEmpty) {
              firstName = nameParts[0];
              lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
            }
          }
          
          setState(() {
            _firstNameController.text = firstName;
            _lastNameController.text = lastName;
            
            if (data['age'] != null) {
              _ageController.text = data['age'].toString();
            } else {
              _ageController.text = child.createdAt.year.toString();
            }
            if (data['gender'] != null) {
              _selectedGender = data['gender'];
            }
            if (data['hobbies'] != null && data['hobbies'] is List) {
              _selectedHobbies.clear();
              _selectedHobbies.addAll(List<String>.from(data['hobbies']));
            }
          });
        } else {
          // Fallback: split from child.name
          final nameParts = child.name.trim().split(' ');
          _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
          _lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          _ageController.text = child.createdAt.year.toString();
        }
      }
    } catch (e) {
      print('Error loading child data: $e');
      String errorMessage;
      if (ErrorMessageHelper.isNetworkError(e)) {
        errorMessage = ErrorMessageHelper.networkErrorRetrieval;
      } else {
        errorMessage = 'Error loading child data: ${e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _updateChildProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Get current child data
      final currentChild = await _parentService.getChild(widget.parentId, widget.childId);
      if (currentChild == null) {
        throw Exception('Child not found');
      }

      final age = int.tryParse(_ageController.text.trim());
      if (age == null || age < 3 || age > 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Child\'s age must be between 3 and 18 years.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = '$firstName $lastName'.trim();
      
      // Check for name uniqueness (excluding current child)
      final allChildren = await _parentService.getChildren(widget.parentId);
      final nameExists = allChildren.any(
        (child) => child.childId != widget.childId && 
                   child.name.toLowerCase() == fullName.toLowerCase()
      );
      
      if (nameExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A profile with this name already exists. Please choose a different name.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Update child data in Firestore
      await FirebaseFirestore.instance
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .update({
        'firstName': firstName,
        'lastName': lastName,
        'name': fullName, // Keep for backward compatibility
        'age': age,
        'gender': _selectedGender,
        'hobbies': _selectedHobbies,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update ChildModel and save using service
      final updatedChild = currentChild.copyWith(
        name: fullName,
        firstName: firstName,
        lastName: lastName,
        age: age,
        gender: _selectedGender,
        hobbies: _selectedHobbies,
        updatedAt: DateTime.now(),
      );
      
      await _parentService.updateChild(widget.parentId, updatedChild);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Child profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('Error updating child profile: $e');
      if (mounted) {
        String errorMessage;
        if (ErrorMessageHelper.isNetworkError(e)) {
          errorMessage = ErrorMessageHelper.networkErrorProfileUpdate;
        } else {
          errorMessage = 'Error updating profile: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
          'Edit Child Profile',
          style: TextStyle(color: AppColors.black),
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(mq.w(0.06)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture Section (Placeholder)
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, size: 50, color: Colors.grey),
                          ),
                          SizedBox(height: mq.h(0.01)),
                          const Text(
                            'Profile Picture',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: mq.h(0.03)),
                    
                    // First Name Field
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.darkCyan),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      textCapitalization: TextCapitalization.words,
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
                    
                    // Last Name Field
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.darkCyan),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      textCapitalization: TextCapitalization.words,
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
                    
                    // Age Field
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Child\'s Age',
                        prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.darkCyan),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter child\'s age';
                        }
                        final age = int.tryParse(value.trim());
                        if (age == null) {
                          return 'Please enter a valid number';
                        }
                        if (age < 3 || age > 18) {
                          return 'Child\'s age must be between 3 and 18 years';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: mq.h(0.02)),
                    
                    // Gender Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: const Icon(Icons.people_outline, color: AppColors.darkCyan),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: ['Male', 'Female', 'Other'].map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                    
                    SizedBox(height: mq.h(0.03)),
                    
                    // Hobbies Section
                    Text(
                      'Hobbies / Preferences',
                      style: TextStyle(
                        fontSize: mq.sp(0.05),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: mq.h(0.01)),
                    Text(
                      'Select your child\'s interests',
                      style: TextStyle(
                        fontSize: mq.sp(0.04),
                        color: AppColors.textLight,
                      ),
                    ),
                    SizedBox(height: mq.h(0.02)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableHobbies.map((hobby) {
                        final isSelected = _selectedHobbies.contains(hobby);
                        return FilterChip(
                          label: Text(hobby),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedHobbies.add(hobby);
                              } else {
                                _selectedHobbies.remove(hobby);
                              }
                            });
                          },
                          selectedColor: AppColors.darkCyan.withOpacity(0.3),
                          checkmarkColor: AppColors.darkCyan,
                        );
                      }).toList(),
                    ),
                    
                    SizedBox(height: mq.h(0.04)),
                    
                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateChildProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkCyan,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: mq.h(0.02)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Update Profile',
                                style: TextStyle(fontSize: mq.sp(0.045)),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

