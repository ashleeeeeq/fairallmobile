import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/repositories/auth_repository.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/services/photo_service.dart';
import 'package:fairallmobile/screens/login_screen.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'package:fairallmobile/config/app_config.dart';
import 'package:fairallmobile/screens/notification_screen.dart';


class ProfileScreen extends StatefulWidget {
  final User user;
  final String userType;
  final Function(User)? onUserUpdated;


  const ProfileScreen({
    super.key,
    required this.user,
    required this.userType,
    this.onUserUpdated,
  });


  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}


class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  bool _isSaving = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;


  late User _currentUser;


  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthdateController;
  late final TextEditingController _sexController;


  late final TextEditingController _gradeLevelController;
  late final TextEditingController _formGivenController;
  late final TextEditingController _disabilityController;
  late final TextEditingController _enrolledProgramController;
  late final TextEditingController _addressController;


  final AuthRepository _authRepository = AuthRepository();
  late String _originalEmail;
  late String _originalPhone;
  late String _originalGradeLevel;
  late String _originalFormGiven;
  late String _originalDisability;
  late String _originalAddress;


  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;


    _originalEmail = _currentUser.email;
    _originalPhone = _currentUser.userType == 'beneficiary'
        ? _currentUser.beneficiary?.contactNumber ?? ''
        : _currentUser.donor?.contactNumber ?? '';
    _originalGradeLevel = _currentUser.beneficiary?.gradeLevel ?? '';
    _originalFormGiven = _currentUser.beneficiary?.formGiven ?? '';
    _originalDisability = _currentUser.beneficiary?.withDisability ?? '';
    _originalAddress = _currentUser.beneficiary?.address ?? '';


    _emailController = TextEditingController(text: _currentUser.email);
    _phoneController = TextEditingController(
      text: _currentUser.userType == 'beneficiary'
          ? _currentUser.beneficiary?.contactNumber ?? ''
          : _currentUser.donor?.contactNumber ?? '',
    );
    _birthdateController = TextEditingController(
      text: _currentUser.userType == 'beneficiary' && _currentUser.beneficiary != null
          ? '${_currentUser.beneficiary!.birthDate.year}-${_currentUser.beneficiary!.birthDate.month}-${_currentUser.beneficiary!.birthDate.day}'
          : '',
    );
    _sexController = TextEditingController(
      text: _currentUser.userType == 'beneficiary' && _currentUser.beneficiary != null
          ? _currentUser.beneficiary!.sex
          : '',
    );


    _gradeLevelController = TextEditingController(
      text: _currentUser.beneficiary?.gradeLevel ?? '',
    );
    _formGivenController = TextEditingController(
      text: _currentUser.beneficiary?.formGiven ?? '',
    );
    _disabilityController = TextEditingController(
      text: _currentUser.beneficiary?.withDisability == 'yes' ? 'Yes' :
      (_currentUser.beneficiary?.withDisability == 'no' ? 'No' : _currentUser.beneficiary?.withDisability ?? ''),
    );
    _enrolledProgramController = TextEditingController(
      text: _currentUser.beneficiary?.schoolName ?? 'Education',
    );
    _addressController = TextEditingController(
      text: _currentUser.beneficiary?.address ?? '',
    );


    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }


  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _birthdateController.dispose();
    _sexController.dispose();
    _gradeLevelController.dispose();
    _formGivenController.dispose();
    _disabilityController.dispose();
    _enrolledProgramController.dispose();
    _addressController.dispose();
    _animController.dispose();
    super.dispose();
  }


  void _toggleEdit() => setState(() => _isEditing = !_isEditing);


  void _updateLocalUser(User updatedUser) {
    setState(() {
      _currentUser = updatedUser;


      _originalEmail = _currentUser.email;
      _originalPhone = _currentUser.userType == 'beneficiary'
          ? _currentUser.beneficiary?.contactNumber ?? ''
          : _currentUser.donor?.contactNumber ?? '';
      _originalGradeLevel = _currentUser.beneficiary?.gradeLevel ?? '';
      _originalFormGiven = _currentUser.beneficiary?.formGiven ?? '';
      _originalDisability = _currentUser.beneficiary?.withDisability ?? '';
      _originalAddress = _currentUser.beneficiary?.address ?? '';


      _emailController.text = _currentUser.email;
      _phoneController.text = _currentUser.userType == 'beneficiary'
          ? _currentUser.beneficiary?.contactNumber ?? ''
          : _currentUser.donor?.contactNumber ?? '';


      if (_currentUser.beneficiary != null) {
        _gradeLevelController.text = _currentUser.beneficiary?.gradeLevel ?? '';
        _formGivenController.text = _currentUser.beneficiary?.formGiven ?? '';
        _disabilityController.text = _currentUser.beneficiary?.withDisability == 'yes' ? 'Yes' :
        (_currentUser.beneficiary?.withDisability == 'no' ? 'No' : _currentUser.beneficiary?.withDisability ?? '');
        _enrolledProgramController.text = _currentUser.beneficiary?.schoolName ?? 'Education';
        _addressController.text = _currentUser.beneficiary?.address ?? '';
      }
    });


    if (widget.onUserUpdated != null) {
      widget.onUserUpdated!(updatedUser);
    }
  }


  Future<void> _saveChanges() async {
    final newEmail = _emailController.text.trim();
    final newPhone = _phoneController.text.trim();
    final newGradeLevel = _gradeLevelController.text.trim();
    final newFormGiven = _formGivenController.text.trim();
    final newDisability = _disabilityController.text.trim();
    final newAddress = _addressController.text.trim();


    final bool emailChanged = newEmail != _originalEmail;
    final bool phoneChanged = newPhone != _originalPhone;
    final bool gradeLevelChanged = newGradeLevel != _originalGradeLevel;
    final bool formGivenChanged = newFormGiven != _originalFormGiven;
    final bool disabilityChanged = newDisability != _originalDisability;
    final bool addressChanged = newAddress != _originalAddress;


    if (!emailChanged && !phoneChanged && !gradeLevelChanged && !formGivenChanged && !disabilityChanged && !addressChanged) {
      setState(() => _isEditing = false);
      _showSnackBar('No changes were made to your profile.', AppColors.grayText);
      return;
    }


    setState(() => _isSaving = true);


    try {
      List<String> updatedFields = [];


      if (emailChanged) {
        final response = await ApiService.put('/profile', {
          'email': newEmail,
        });
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          updatedFields.add('Email');
          _originalEmail = newEmail;
        }
      }


      if (widget.userType == 'beneficiary') {
        final Map<String, dynamic> updateData = {};
        if (phoneChanged) updateData['contact_number'] = newPhone;
        if (gradeLevelChanged) updateData['grade_level'] = newGradeLevel;
        if (formGivenChanged) updateData['form_given'] = newFormGiven;
        if (disabilityChanged) updateData['with_disability'] = newDisability;
        if (addressChanged) updateData['address'] = newAddress;


        if (updateData.isNotEmpty) {
          final response = await ApiService.put('/profile/beneficiary', updateData);
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            if (phoneChanged) updatedFields.add('Phone Number');
            if (gradeLevelChanged) updatedFields.add('Grade Level');
            if (formGivenChanged) updatedFields.add('Form Given');
            if (disabilityChanged) updatedFields.add('Disability Status');
            if (addressChanged) updatedFields.add('Address');
          }
        }
      }


      if (widget.userType == 'donor' && phoneChanged) {
        final response = await ApiService.put('/profile/donor', {
          'contact_number': newPhone,
        });
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          updatedFields.add('Phone Number');
        }
      }


      setState(() => _isEditing = false);


      if (updatedFields.isNotEmpty) {
        final changeList = updatedFields.join(' and ');
        final message = updatedFields.length == 1
            ? 'Your $changeList has been updated successfully.'
            : 'Your $changeList have been updated successfully.';
        _showSnackBar(message, AppColors.onTertiaryContainer);


        final updatedUser = await _authRepository.refreshUserData();
        if (updatedUser != null) {
          _updateLocalUser(updatedUser);
        }
      }
    } catch (e) {
      _showSnackBar('Failed to update profile. Please try again.', AppColors.error);
    } finally {
      setState(() => _isSaving = false);
    }
  }


  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }


  Future<void> _updateAvatar(File imageFile) async {
    setState(() => _isSaving = true);


    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}${AppConfig.uploadAvatar}'),
      );


      final token = await ApiService.getToken();
      request.headers['Authorization'] = 'Bearer $token';


      request.files.add(
        await http.MultipartFile.fromPath('avatar', imageFile.path),
      );


      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var data = jsonDecode(responseBody);


      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackBar('Profile picture updated!', AppColors.onTertiaryContainer);


        final updatedUser = await _authRepository.refreshUserData();
        if (updatedUser != null) {
          _updateLocalUser(updatedUser);
        }
      } else {
        _showSnackBar(data['message'] ?? 'Failed to update', AppColors.error);
      }
    } catch (e) {
      _showSnackBar('Error: $e', AppColors.error);
    } finally {
      setState(() => _isSaving = false);
    }
  }


  Future<void> _deleteAvatar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove your profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );


    if (confirm != true) return;


    setState(() => _isSaving = true);


    try {
      final response = await ApiService.delete(AppConfig.deleteAvatar);
      final data = jsonDecode(response.body);


      if (data['success'] == true) {
        _showSnackBar('Profile picture removed', AppColors.onTertiaryContainer);


        final updatedUser = await _authRepository.refreshUserData();
        if (updatedUser != null) {
          _updateLocalUser(updatedUser);
        }
      } else {
        _showSnackBar('Failed to remove', AppColors.error);
      }
    } catch (e) {
      _showSnackBar('Error: $e', AppColors.error);
    } finally {
      setState(() => _isSaving = false);
    }
  }


  Future<void> _pickImageFromGallery() async {
    final imageFile = await PhotoService.pickImageFromGallery();
    if (imageFile != null) {
      await _updateAvatar(imageFile);
    }
  }


  Future<void> _takePhoto() async {
    final imageFile = await PhotoService.takePhoto();
    if (imageFile != null) {
      await _updateAvatar(imageFile);
    }
  }


  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _takePhoto();
              },
            ),
            if (_currentUser.avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteAvatar();
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }


  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.surface,
          ),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.grayText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );


    if (shouldLogout == true) {
      await _authRepository.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final beneficiary = _currentUser.beneficiary;


    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        leading: null,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(user: _currentUser),
                ),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.surface.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _showAvatarOptions,
                                child: Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.tertiary,
                                          width: 2.5,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: _currentUser.avatarPath != null
                                            ? Image.network(
                                          _currentUser.getAvatarUrl()!,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        )
                                            : Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: AppColors.surface.withValues(alpha: 0.35),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.person_rounded,
                                            color: Colors.white70,
                                            size: 38,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.tertiary,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 14,
                                          color: AppColors.surface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentUser.displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.tertiary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.tertiary.withValues(alpha: 0.4),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.business_center_rounded,
                                            color: AppColors.tertiary,
                                            size: 11,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              _currentUser.userType?.toUpperCase() ?? 'USER',
                                              style: TextStyle(
                                                color: AppColors.tertiary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        thickness: 1,
                        height: 28,
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: (_isEditing && !_isSaving) ? _saveChanges : (!_isEditing ? _toggleEdit : null),
                          icon: _isSaving
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Icon(
                            _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _isSaving ? 'Saving...' : (_isEditing ? 'Save Changes' : 'Edit Profile'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isEditing ? AppColors.onTertiaryContainer : AppColors.tertiary,
                            foregroundColor: _isEditing ? Colors.white : AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              const SizedBox(height: 28),


              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'ACCOUNT DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grayText,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),


              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.surface.withValues(alpha: 0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildField(
                      icon: Icons.email_outlined,
                      label: 'EMAIL ADDRESS',
                      controller: _emailController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.emailAddress,
                      isFirst: true,
                      isLast: false,
                    ),
                    _buildDivider(),
                    _buildField(
                      icon: Icons.phone_outlined,
                      label: 'PHONE NUMBER',
                      controller: _phoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      isFirst: false,
                      isLast: widget.userType != 'beneficiary',
                    ),
                    if (widget.userType == 'beneficiary') ...[
                      _buildDivider(),
                      _buildField(
                        icon: Icons.cake_outlined,
                        label: 'BIRTH DATE',
                        controller: _birthdateController,
                        enabled: false,
                        isFirst: false,
                        isLast: false,
                      ),
                      _buildDivider(),
                      _buildField(
                        icon: Icons.person_outline_rounded,
                        label: 'SEX',
                        controller: _sexController,
                        enabled: false,
                        isFirst: false,
                        isLast: false,
                      ),
                      if (beneficiary?.gradeLevel != null) ...[
                        _buildDivider(),
                        _buildField(
                          icon: Icons.school_outlined,
                          label: 'GRADE LEVEL',
                          controller: _gradeLevelController,
                          enabled: _isEditing,
                          isFirst: false,
                          isLast: false,
                        ),
                      ],
                      if (beneficiary?.formGiven != null) ...[
                        _buildDivider(),
                        _buildField(
                          icon: Icons.assignment_outlined,
                          label: 'FORM GIVEN',
                          controller: _formGivenController,
                          enabled: _isEditing,
                          isFirst: false,
                          isLast: false,
                        ),
                      ],
                      if (beneficiary?.withDisability != null) ...[
                        _buildDivider(),
                        _buildField(
                          icon: Icons.accessibility_new_rounded,
                          label: 'WITH DISABILITY',
                          controller: _disabilityController,
                          enabled: _isEditing,
                          isFirst: false,
                          isLast: false,
                        ),
                      ],
                      _buildDivider(),
                      _buildField(
                        icon: Icons.class_outlined,
                        label: 'ENROLLED PROGRAM',
                        controller: _enrolledProgramController,
                        enabled: false,
                        isFirst: false,
                        isLast: false,
                      ),
                      _buildDivider(),
                      _buildField(
                        icon: Icons.location_on_outlined,
                        label: 'ADDRESS',
                        controller: _addressController,
                        enabled: _isEditing,
                        isFirst: false,
                        isLast: true,
                      ),
                    ],
                  ],
                ),
              ),




              const SizedBox(height: 28),


              if (!_isEditing)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text(
                      'LOG OUT',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final bool isLockedField = label == 'BIRTH DATE' ||
        label == 'SEX' ||
        label == 'ENROLLED PROGRAM' ||
        label == 'FORM GIVEN';
    final bool showEditBorder = _isEditing && !isLockedField;
    final bool showLockState = _isEditing && isLockedField;


    return Container(
      decoration: BoxDecoration(
        color: showLockState ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? 20 : 0),
          topRight: Radius.circular(isFirst ? 20 : 0),
          bottomLeft: Radius.circular(isLast ? 20 : 0),
          bottomRight: Radius.circular(isLast ? 20 : 0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: showLockState ? Colors.grey.shade400 : AppColors.grayText,
                letterSpacing: 0.8,
              ),
            ),
          ),
          TextField(
            controller: controller,
            enabled: enabled && !isLockedField,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: showLockState ? Colors.grey.shade500 : Colors.black87,
            ),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: Icon(
                icon,
                color: showLockState ? Colors.grey.shade400 : AppColors.surface,
                size: 20,
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 0),
              suffixIcon: showLockState
                  ? Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 18)
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: showLockState,
              fillColor: Colors.grey.shade50,
              border: InputBorder.none,
              disabledBorder: showLockState
                  ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              )
                  : InputBorder.none,
              enabledBorder: showEditBorder
                  ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.tertiary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              )
                  : InputBorder.none,
              focusedBorder: showEditBorder
                  ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.tertiary,
                  width: 2,
                ),
              )
                  : InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.withValues(alpha: 0.1),
      thickness: 1,
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }


}

