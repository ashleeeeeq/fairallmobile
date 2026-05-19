import 'package:flutter/material.dart';
<<<<<<< HEAD
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
=======

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
>>>>>>> origin/master

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

<<<<<<< HEAD
  // Controllers for editable fields
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthdateController;
  late final TextEditingController _sexController;

  final AuthRepository _authRepository = AuthRepository();
=======
  // for backend
  final Map<String, String> sampleUser = {
    'name': 'Jasmine A. Cruz',
    'program': 'Education Program',
    'email': 'jasminecruz16@gmail.com',
    'password': '****************',
    'birthdate': 'October 16, 2007',
    'sex': 'Female',
    'phone': '+63 912 345 6789',
  };

  // controllers for data
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _birthdateController;
  late final TextEditingController _sexController;
  late final TextEditingController _phoneController;
>>>>>>> origin/master

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD

    // Initialize controllers with actual user data
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
=======
    _emailController = TextEditingController(text: sampleUser['email']);
    _passwordController = TextEditingController(text: sampleUser['password']);
    _birthdateController = TextEditingController(text: sampleUser['birthdate']);
    _phoneController = TextEditingController(text: sampleUser['phone']);
    _sexController = TextEditingController(text: sampleUser['sex']);
>>>>>>> origin/master

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
<<<<<<< HEAD
    _phoneController.dispose();
    _birthdateController.dispose();
    _sexController.dispose();
    _animController.dispose();
=======
    _passwordController.dispose();
    _birthdateController.dispose();
    _phoneController.dispose();
    _animController.dispose();
    _sexController.dispose();
>>>>>>> origin/master
    super.dispose();
  }

  void _toggleEdit() => setState(() => _isEditing = !_isEditing);

  void _saveChanges() {
<<<<<<< HEAD
    // TODO: Implement API call to save profile changes
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Profile updated successfully!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
=======
    setState(() => _isEditing = false);
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile updated successfully!',
          style: TextStyle(
            color: theme.colorScheme.onTertiaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.tertiaryContainer,
>>>>>>> origin/master
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

<<<<<<< HEAD
  Future<void> _logout() async {
=======
  void _logout() {
    final theme = Theme.of(context);
>>>>>>> origin/master
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
<<<<<<< HEAD
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
=======
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.bold)),
>>>>>>> origin/master
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
<<<<<<< HEAD
            child: const Text('Cancel'),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
=======
            child: Text('Cancel',
                style: TextStyle(color: theme.colorScheme.secondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error),
            child: const Text('Log Out',
                style: TextStyle(fontWeight: FontWeight.bold)),
>>>>>>> origin/master
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final beneficiary = widget.user.beneficiary;
    final donor = widget.user.donor;

    return Scaffold(
      backgroundColor: Colors.white,
=======
    final theme = Theme.of(context);
    final Color backgroundBlue = theme.scaffoldBackgroundColor;
    final Color primaryDark = theme.colorScheme.primary;
    final Color primaryBlue = theme.colorScheme.secondary;
    final Color cardDark = theme.colorScheme.surface;
    final Color accentYellow = theme.colorScheme.tertiary;
    final Color pureBlack = theme.colorScheme.shadow;
    final Color red = theme.colorScheme.error;
    final Color greenBG = theme.colorScheme.tertiaryContainer;
    final Color greenText = theme.colorScheme.onTertiaryContainer;

    return Scaffold(
      backgroundColor: backgroundBlue,
>>>>>>> origin/master
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
<<<<<<< HEAD
                              color: AppColors.navy,
=======
                              color: primaryDark,
>>>>>>> origin/master
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Manage your account',
                            style: TextStyle(
                              fontSize: 12,
<<<<<<< HEAD
                              color: AppColors.navy.withAlpha(178),
=======
                              color: primaryBlue.withAlpha(178),
>>>>>>> origin/master
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
<<<<<<< HEAD
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navy.withAlpha(25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.notifications_none_rounded,
                                size: 24, color: AppColors.navy),
                            Positioned(
                              right: 9,
                              top: 9,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.yellow,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                          ],
=======
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: primaryDark.withAlpha(25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.notifications_none_rounded,
                                  size: 24, color: primaryDark),
                              Positioned(
                                right: 9,
                                top: 9,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: accentYellow,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
>>>>>>> origin/master
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
<<<<<<< HEAD
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withAlpha(76),
=======
                    color: cardDark,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: primaryDark.withAlpha(76),
>>>>>>> origin/master
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
<<<<<<< HEAD
                                border: Border.all(color: AppColors.yellow, width: 2.5),
=======
                                border: Border.all(
                                    color: accentYellow, width: 2.5),
>>>>>>> origin/master
                              ),
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
<<<<<<< HEAD
                                  color: AppColors.navy.withAlpha(89),
=======
                                  color: primaryBlue.withAlpha(89),
>>>>>>> origin/master
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
<<<<<<< HEAD
                                    widget.user.displayName,
=======
                                    sampleUser['name']!,
>>>>>>> origin/master
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
<<<<<<< HEAD
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.yellow.withAlpha(38),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.yellow.withAlpha(102),
=======
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: accentYellow.withAlpha(38),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: accentYellow.withAlpha(102),
>>>>>>> origin/master
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.business_center_rounded,
<<<<<<< HEAD
                                            color: AppColors.yellow, size: 11),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            widget.user.userType?.toUpperCase() ?? 'USER',
                                            style: TextStyle(
                                              color: AppColors.yellow,
=======
                                            color: accentYellow, size: 11),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            sampleUser['program']!,
                                            style: TextStyle(
                                              color: accentYellow,
>>>>>>> origin/master
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
<<<<<<< HEAD
                              _isEditing ? Icons.check_rounded : Icons.edit_rounded,
=======
                              _isEditing
                                  ? Icons.check_rounded
                                  : Icons.edit_rounded,
>>>>>>> origin/master
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
<<<<<<< HEAD
                              backgroundColor: _isEditing ? Colors.green : AppColors.yellow,
                              foregroundColor: _isEditing ? Colors.white : AppColors.navy,
=======
                              backgroundColor: _isEditing ? greenBG : accentYellow,
                              foregroundColor: _isEditing ? greenText : cardDark,
>>>>>>> origin/master
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

                // Section Label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ACCOUNT DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
<<<<<<< HEAD
                      color: AppColors.navy.withAlpha(153),
=======
                      color: primaryBlue.withAlpha(153),
>>>>>>> origin/master
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Fields Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
<<<<<<< HEAD
                        color: AppColors.navy.withAlpha(18),
=======
                        color: primaryDark.withAlpha(18),
>>>>>>> origin/master
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildField(
<<<<<<< HEAD
                        icon: Icons.email_outlined,
=======
                        icon: Icons.calendar_month_rounded,
                        label: 'BIRTHDATE',
                        controller: _birthdateController,
                        enabled: _isEditing,
                        primaryBlue: primaryBlue,
                        primaryDark: primaryDark,
                        pureBlack: pureBlack,
                        accentYellow: accentYellow,
                        isFirst: true,
                        isLast: false,
                      ),
                      _buildDivider(primaryDark),
                      _buildField(
                        icon: Icons.female_rounded,
                        label: 'SEX',
                        controller: _sexController,
                        enabled: _isEditing,
                        primaryBlue: primaryBlue,
                        primaryDark: primaryDark,
                        pureBlack: pureBlack,
                        accentYellow: accentYellow,
                        isFirst: false,
                        isLast: false,
                      ),
                      _buildDivider(primaryDark),
                      _buildField(
                        icon: Icons.mail_outline_rounded,
>>>>>>> origin/master
                        label: 'EMAIL ADDRESS',
                        controller: _emailController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
<<<<<<< HEAD
                        isFirst: true,
                        isLast: false,
                      ),
                      _buildDivider(),
=======
                        primaryBlue: primaryBlue,
                        primaryDark: primaryDark,
                        pureBlack: pureBlack,
                        accentYellow: accentYellow,
                        isFirst: false,
                        isLast: false,
                      ),
                      _buildDivider(primaryDark),
                      _buildField(
                        icon: Icons.lock_outline_rounded,
                        label: 'PASSWORD',
                        controller: _passwordController,
                        enabled: _isEditing,
                        obscureText: !_isEditing,
                        primaryBlue: primaryBlue,
                        primaryDark: primaryDark,
                        pureBlack: pureBlack,
                        accentYellow: accentYellow,
                        isFirst: false,
                        isLast: false,
                      ),
                      _buildDivider(primaryDark),
>>>>>>> origin/master
                      _buildField(
                        icon: Icons.phone_outlined,
                        label: 'PHONE NUMBER',
                        controller: _phoneController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
<<<<<<< HEAD
                        isFirst: false,
                        isLast: false,
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
                          isLast: true,
                        ),
                      ],
=======
                        primaryBlue: primaryBlue,
                        primaryDark: primaryDark,
                        pureBlack: pureBlack,
                        accentYellow: accentYellow,
                        isFirst: false,
                        isLast: true,
                      ),
>>>>>>> origin/master
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Log out Button
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
<<<<<<< HEAD
                        backgroundColor: Colors.red,
=======
                        backgroundColor: red,
>>>>>>> origin/master
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
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildDivider() => Padding(
=======
  Widget _buildDivider(Color primaryDark) => Padding(
>>>>>>> origin/master
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Divider(
      height: 1,
      thickness: 1,
<<<<<<< HEAD
      color: AppColors.navy.withAlpha(15),
=======
      color: primaryDark.withAlpha(15),
>>>>>>> origin/master
    ),
  );

  Widget _buildField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
<<<<<<< HEAD
=======
    required Color primaryBlue,
    required Color primaryDark,
    required Color pureBlack,
    required Color accentYellow,
>>>>>>> origin/master
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
        color: enabled ? Colors.white : const Color(0xFFF8FAFC),
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
<<<<<<< HEAD
                color: enabled ? AppColors.navy : AppColors.navy.withAlpha(102),
=======
                color: enabled ? primaryBlue : primaryDark.withAlpha(102),
>>>>>>> origin/master
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
<<<<<<< HEAD
                  color: enabled ? AppColors.navy : AppColors.navy.withAlpha(102),
=======
                  color: enabled ? primaryBlue : primaryDark.withAlpha(102),
>>>>>>> origin/master
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
            style: TextStyle(
              fontSize: 15,
<<<<<<< HEAD
              color: Colors.black,
=======
              color: pureBlack,
>>>>>>> origin/master
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
<<<<<<< HEAD
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
=======
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
>>>>>>> origin/master
              filled: true,
              fillColor: enabled ? Colors.white : Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
<<<<<<< HEAD
                borderSide: BorderSide(color: AppColors.yellow.withAlpha(153), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.navy, width: 2),
=======
                borderSide: BorderSide(
                    color: accentYellow.withAlpha(153), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryBlue, width: 2),
>>>>>>> origin/master
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