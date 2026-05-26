import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/screens/beneficiary/home_screen.dart';
import 'package:fairallmobile/screens/beneficiary/activities_screen.dart';
import 'package:fairallmobile/screens/beneficiary/records_screen.dart';
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

  // Screens mapped to each tab index
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      BeneficiaryHomeScreen(user: widget.user),      // index 0 - Home
      ActivitiesScreen(user: widget.user),           // index 1 - Activities
      const SizedBox(),                              // index 2 - QR placeholder
      AcademicRecordsScreen(user: widget.user),      // index 3 - Records
      ProfileScreen(                                 // index 4 - Profile
        user: widget.user,
        userType: 'beneficiary',
      ),
    ];
  }

  void _onQRPressed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, size: 50, color: AppColors.tertiary),
              SizedBox(height: 16),
              Text(
                'QR Code Scanner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Point camera at QR code',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
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