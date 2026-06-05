import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/screens/donor/donor_home_screen.dart';
import 'package:fairallmobile/screens/donor/donate_screen.dart';
import 'package:fairallmobile/screens/donor/donation_history_screen.dart';
import 'package:fairallmobile/screens/donor/impact_reports_screen.dart';
import 'package:fairallmobile/screens/profile_screen.dart';
import 'package:fairallmobile/utils/app_colors.dart';

class DonorMainScreen extends StatefulWidget {
  final User user;

  const DonorMainScreen({super.key, required this.user});

  @override
  State<DonorMainScreen> createState() => _DonorMainScreenState();
}

class _DonorMainScreenState extends State<DonorMainScreen> {
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
      // DonorHomeScreen(user: _currentUser),           // index 0 - Home
      DonateScreen(user: _currentUser),              // index 1 - Donate
      DonationHistoryScreen(user: _currentUser),     // index 2 - Donation (History)
      // ImpactReportsScreen(user: _currentUser),       // index 3 - Impact
      ProfileScreen(
        user: _currentUser,
        userType: 'donor',
        onUserUpdated: (updatedUser) {
          setState(() {
            _currentUser = updatedUser;
            _buildScreens();
          });
        },
      ),                                              // index 4 - Profile
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final Color navBg = AppColors.surface;
    final Color activeColor = Colors.white;
    final Color inactiveColor = Colors.white.withAlpha(115);

    const labels = ['Home', 'Donate', 'Donations', 'Impact', 'Profile'];
    const icons = [
      Icons.home_rounded,
      Icons.volunteer_activism_rounded,
      Icons.history_rounded,
      Icons.assessment_rounded,
      Icons.person_outline_rounded,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex < _screens.length ? _currentIndex : 0,
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
                    painter: DonorBNBCustomPainter(color: navBg),
                  ),
                  // Navigation items
                  SizedBox(
                    width: size.width,
                    height: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (i) {
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

// Custom painter for curved bottom navigation bar (Donor version - straight bar)
class DonorBNBCustomPainter extends CustomPainter {
  final Color color;

  DonorBNBCustomPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path()..moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black, 5, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DonorBNBCustomPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}