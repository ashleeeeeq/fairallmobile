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

  // controllers for data
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _birthdateController;
  late final TextEditingController _sexController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();

    final beneficiary = widget.user.beneficiary;

    _emailController = TextEditingController(text: widget.user.email);
    _passwordController = TextEditingController(text: '********');
    _birthdateController = TextEditingController(
      text: beneficiary != null
          ? '${beneficiary.birthDate.year}-${beneficiary.birthDate.month}-${beneficiary.birthDate.day}'
          : 'Not specified',
    );
    _phoneController = TextEditingController(
      text: beneficiary?.contactNumber ?? 'Not specified',
    );
    _sexController = TextEditingController(
      text: beneficiary?.sex ?? 'Not specified',
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
    _passwordController.dispose();
    _birthdateController.dispose();
    _phoneController.dispose();
    _animController.dispose();
    _sexController.dispose();
    super.dispose();
  }

  void _toggleEdit() => setState(() => _isEditing = !_isEditing);

  void _saveChanges() {
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
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _logout() {
    final authRepository = AuthRepository();
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: theme.colorScheme.secondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authRepository.logout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            },
            style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error),
            child: const Text('Log Out',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final beneficiary = widget.user.beneficiary;
    final displayName = widget.user.displayName;
    final programName = widget.user.userType == 'beneficiary' ? 'Beneficiary' : 'Donor';

    return Scaffold(
      backgroundColor: backgroundBlue,
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
                              color: primaryDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Manage your account',
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryBlue.withAlpha(178),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: primaryDark.withAlpha(76),
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
                                    color: accentYellow, width: 2.5),
                              ),
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: primaryBlue.withAlpha(89),
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
                                    displayName,
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
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: accentYellow.withAlpha(38),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: accentYellow.withAlpha(102),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.business_center_rounded,
                                            color: accentYellow, size: 11),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            programName,
                                            style: TextStyle(
                                              color: accentYellow,
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
                              _isEditing
                                  ? Icons.check_rounded
                                  : Icons.edit_rounded,
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
                              backgroundColor: _isEditing ? greenBG : accentYellow,
                              foregroundColor: _isEditing ? greenText : cardDark,
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
                      color: primaryBlue.withAlpha(153),
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
                        color: primaryDark.withAlpha(18),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildField(
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
                        label: 'EMAIL ADDRESS',
                        controller: _emailController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
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
                      _buildField(
                        icon: Icons.phone_outlined,
                        label: 'PHONE NUMBER',
                        controller: _phoneController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                        primaryBlue: primaryBlue,
                        primaryDark: primaryDark,
                        pureBlack: pureBlack,
                        accentYellow: accentYellow,
                        isFirst: false,
                        isLast: true,
                      ),
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
                        backgroundColor: red,
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

  Widget _buildDivider(Color primaryDark) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Divider(
      height: 1,
      thickness: 1,
      color: primaryDark.withAlpha(15),
    ),
  );

  Widget _buildField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required Color primaryBlue,
    required Color primaryDark,
    required Color pureBlack,
    required Color accentYellow,
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
                color: enabled ? primaryBlue : primaryDark.withAlpha(102),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: enabled ? primaryBlue : primaryDark.withAlpha(102),
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
              color: pureBlack,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: enabled ? Colors.white : Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: accentYellow.withAlpha(153), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryBlue, width: 2),
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