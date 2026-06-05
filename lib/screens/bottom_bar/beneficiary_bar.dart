import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/screens/beneficiary/beneficiary_home_screen.dart';
import 'package:fairallmobile/screens/beneficiary/activities_screen.dart';
import 'package:fairallmobile/screens/beneficiary/records_screen.dart';
import 'package:fairallmobile/screens/beneficiary/qr_scanner_screen.dart';
import 'package:fairallmobile/screens/profile_screen.dart';
import 'package:fairallmobile/utils/app_colors.dart';

class BeneficiaryMainScreen extends StatefulWidget {
  final User user;

  const BeneficiaryMainScreen({super.key, required this.user});

  @override
  State<BeneficiaryMainScreen> createState() => _BeneficiaryMainScreenState();
}

class _BeneficiaryMainScreenState extends State<BeneficiaryMainScreen> {
  int _currentIndex = 0;
  late User _currentUser;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _buildScreens();
  }

  void _buildScreens() {
    _screens = [
      BeneficiaryHomeScreen(user: _currentUser),      // index 0 - Home
      ActivitiesScreen(user: _currentUser),           // index 1 - Activities
      const SizedBox(),                               // index 2 - QR placeholder
      AcademicRecordsScreen(user: _currentUser),      // index 3 - Records
      ProfileScreen(
        user: _currentUser,
        userType: 'beneficiary',
        onUserUpdated: (updatedUser) {
          setState(() {
            _currentUser = updatedUser;
            _buildScreens(); // Rebuild screens with updated user
          });
        },
      ),
    ];
  }

  void _onQRPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: QRScannerScreen(
          beneficiaryId: _currentUser.beneficiary?.id ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final Color navBg = AppColors.surface;
    final Color activeColor = Colors.white;
    final Color inactiveColor = Colors.white.withAlpha(115);

    const labels = ['Home', 'Activities', 'QR', 'Records', 'Profile'];
    const icons = [
      Icons.home_rounded,
      Icons.school_outlined,
      null,
      Icons.assignment,
      Icons.person_outline_rounded,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex == 2 ? 0 : _currentIndex,
              children: _screens,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: SizedBox(
              width: size.width,
              height: 80,
              child: Stack(
                children: [
                  // Custom curved background
                  CustomPaint(
                    size: Size(size.width, 80),
                    painter: BNBCustomPainter(color: navBg),
                  ),
                  // Center QR button
                  Center(
                    heightFactor: 0.35,
                    child: SizedBox(
                      width: 65,
                      height: 65,
                      child: FloatingActionButton(
                        onPressed: _onQRPressed,
                        backgroundColor: AppColors.tertiary,
                        elevation: 4.0,
                        shape: const CircleBorder(),
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          size: 32,
                          color: navBg,
                        ),
                      ),
                    ),
                  ),
                  // Navigation items
                  SizedBox(
                    width: size.width,
                    height: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (i) {
                        if (i == 2) {
                          return Container(width: size.width * 0.20);
                        }
                        final bool isActive = _currentIndex == i;
                        return Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _currentIndex = i),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icons[i],
                                  size: 24,
                                  color: isActive ? activeColor : inactiveColor,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  labels[i],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                    color: isActive ? activeColor : inactiveColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for curved bottom navigation bar
class BNBCustomPainter extends CustomPainter {
  final Color color;

  BNBCustomPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path()..moveTo(0, 0);
    path.lineTo(size.width * 0.35, 0);
    path.quadraticBezierTo(size.width * 0.40, 0, size.width * 0.40, 12);
    path.arcToPoint(
      Offset(size.width * 0.60, 12),
      radius: const Radius.circular(10.0),
      clockwise: false,
    );
    path.quadraticBezierTo(size.width * 0.60, 0, size.width * 0.65, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black, 5, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BNBCustomPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}