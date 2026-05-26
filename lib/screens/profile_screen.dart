import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/repositories/auth_repository.dart';
import 'package:fairallmobile/screens/login_screen.dart';
import 'package:fairallmobile/utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  final String userType;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.userType,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthdateController;
  late final TextEditingController _sexController;

  late final TextEditingController _gradeLevelController;
  late final TextEditingController _formGivenController;
  late final TextEditingController _disabilityController;

  final AuthRepository _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(
      text: widget.user.userType == 'beneficiary'
          ? widget.user.beneficiary?.contactNumber ?? ''
          : widget.user.donor?.contactNumber ?? '',
    );
    _birthdateController = TextEditingController(
      text: widget.user.userType == 'beneficiary' && widget.user.beneficiary != null
          ? '${widget.user.beneficiary!.birthDate.year}-${widget.user.beneficiary!.birthDate.month}-${widget.user.beneficiary!.birthDate.day}'
          : '',
    );
    _sexController = TextEditingController(
      text: widget.user.userType == 'beneficiary' && widget.user.beneficiary != null
          ? widget.user.beneficiary!.sex
          : '',
    );

    _gradeLevelController = TextEditingController(
      text: widget.user.beneficiary?.gradeLevel ?? '',
    );
    _formGivenController = TextEditingController(
      text: widget.user.beneficiary?.formGiven ?? '',
    );
    _disabilityController = TextEditingController(
      text: widget.user.beneficiary?.withDisability == 'yes' ? 'Yes' :
      (widget.user.beneficiary?.withDisability == 'no' ? 'No' : widget.user.beneficiary?.withDisability ?? ''),
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
    _animController.dispose();
    super.dispose();
  }

  void _toggleEdit() => setState(() => _isEditing = !_isEditing);

  void _saveChanges() {
    setState(() => _isEditing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Profile updated successfully!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.onTertiaryContainer,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.grayText,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authRepository.logout();

              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(
              'Log Out',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final beneficiary = widget.user.beneficiary;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        leading: null,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
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
                      color: AppColors.surface.withAlpha(76),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
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
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: AppColors.surface.withAlpha(89),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white70,
                                size: 38,
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.user.displayName,
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
                                    color: AppColors.tertiary.withAlpha(38),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.tertiary.withAlpha(102),
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
                                          widget.user.userType?.toUpperCase() ?? 'USER',
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
                      Divider(
                        color: Colors.white.withAlpha(20),
                        thickness: 1,
                        height: 28,
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _isEditing ? _saveChanges : _toggleEdit,
                          icon: Icon(
                            _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _isEditing ? 'Save Changes' : 'Edit Profile',
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
                child: Text(
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
                      color: AppColors.surface.withAlpha(18),
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
                        icon: Icons.cake,
                        label: 'BIRTH DATE',
                        controller: _birthdateController,
                        enabled: _isEditing,
                        isFirst: false,
                        isLast: false,
                      ),
                      _buildDivider(),
                      _buildField(
                        icon: Icons.female,
                        label: 'SEX',
                        controller: _sexController,
                        enabled: _isEditing,
                        isFirst: false,
                        isLast: false,
                      ),
                      if (beneficiary?.gradeLevel != null) ...[
                        _buildDivider(),
                        _buildField(
                          icon: Icons.school,
                          label: 'GRADE LEVEL',
                          controller: TextEditingController(
                            text: beneficiary!.gradeLevel,
                          ),
                          enabled: false,
                          isFirst: false,
                          isLast: false,
                        ),
                      ],
                      if (beneficiary?.formGiven != null) ...[
                        _buildDivider(),
                        _buildField(
                          icon: Icons.assignment,
                          label: 'FORM GIVEN',
                          controller: TextEditingController(
                            text: beneficiary!.formGiven,
                          ),
                          enabled: false,
                          isFirst: false,
                          isLast: false,
                        ),
                      ],
                      if (beneficiary?.withDisability != null) ...[
                        _buildDivider(),
                        _buildField(
                          icon: Icons.hearing,
                          label: 'WITH DISABILITY',
                          controller: TextEditingController(
                            text: beneficiary!.withDisability == 'yes'
                                ? 'Yes'
                                : beneficiary!.withDisability == 'no'
                                ? 'No'
                                : beneficiary!.withDisability,
                          ),
                          enabled: false,
                          isFirst: false,
                          isLast: true,
                        ),
                      ],
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

  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Divider(
      height: 1,
      thickness: 1,
      color: AppColors.scaffoldBackground,
    ),
  );

  Widget _buildField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isFirst,
    required bool isLast,
    bool enabled = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final topRadius = isFirst ? const Radius.circular(20) : Radius.zero;
    final bottomRadius = isLast ? const Radius.circular(20) : Radius.zero;

    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : AppColors.scaffoldBackground.withAlpha(100),
        borderRadius: BorderRadius.only(
          topLeft: topRadius,
          topRight: topRadius,
          bottomLeft: bottomRadius,
          bottomRight: bottomRadius,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: enabled ? AppColors.surface : AppColors.grayText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: enabled ? AppColors.surface : AppColors.grayText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: enabled,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              filled: true,
              fillColor: enabled ? Colors.white : Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.secondary.withAlpha(100),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.surface,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}