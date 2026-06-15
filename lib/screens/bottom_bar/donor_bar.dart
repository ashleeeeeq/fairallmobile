import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/screens/donor/donor_home_screen.dart';
import 'package:fairallmobile/screens/donor/donate_screen.dart';
import 'package:fairallmobile/screens/donor/donation_history_screen.dart';
import 'package:fairallmobile/screens/beneficiary/profile_screen.dart';
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
  final Map<int, Widget> _screens = {};

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  Widget _screen(int index) {
    if (!_screens.containsKey(index)) {
      _screens[index] = _buildScreen(index);
    }
    return _screens[index]!;
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return DonorHomeScreen(user: _currentUser);
      case 1:
        return DonateScreen(user: _currentUser);
      case 2:
        return DonationHistoryScreen(user: _currentUser);
      case 3:
        return ProfileScreen(
          user: _currentUser,
          userType: 'donor',
          onUserUpdated: (updatedUser) {
            setState(() {
              _currentUser = updatedUser;
            });
          },
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final Color navBg = AppColors.surface;
    final Color activeColor = Colors.white;
    final Color inactiveColor = Colors.white.withAlpha(115);

    const labels = ['Home', 'Donate', 'Donations', 'Profile'];
    const icons = [
      Icons.home_rounded,
      Icons.volunteer_activism_rounded,
      Icons.history_rounded,
      Icons.person_outline_rounded,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex < 4 ? _currentIndex : 0,
              children: [_screen(0), _screen(1), _screen(2), _screen(3)],
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
                      children: List.generate(4, (i) {
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
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isActive
                                        ? activeColor
                                        : inactiveColor,
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
