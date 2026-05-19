import 'package:flutter/material.dart';

// modify basedd on the created pages
import 'package:fairallmobile/screens/home_screen.dart';
import 'package:tara_capstone_fairall/acts.dart';
import 'package:tara_capstone_fairall/programs.dart';
import 'package:tara_capstone_fairall/profile_screen.dart';

class BeneficiaryMainScreen extends StatefulWidget {
  const BeneficiaryMainScreen({super.key});

  @override
  State<BeneficiaryMainScreen> createState() => _BeneficiaryMainScreenState();
}

class _BeneficiaryMainScreenState extends State<BeneficiaryMainScreen> {
  int _currentIndex = 0;

  // actual screens mapped to each tab index (modify based on created classes)
  final List<Widget> _screens = const [
    HomeScreen(), // index 0 — Home
    ActivitiesScreen(), // index 1 — Activities
    SizedBox(), // index 2 — QR placeholder space
    ProgramScreen(), // index 3 — Programs
    ProfileScreen(), // index 4 — Profile
  ];

  void _onQRPressed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(
          child: Text(
            'QR Code Scanner',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final Color navBg = theme.colorScheme.surface;
    final Color accentYellow = theme.colorScheme.tertiary;
    final Color activeColor = Colors.white;
    final Color inactiveColor = Colors.white.withAlpha(115);

    const labels = ['Home', 'Activities', 'QR', 'Programs', 'Profile'];
    const icons = [
      Icons.home_rounded,
      Icons.sports_basketball_outlined,
      null,
      Icons.school_outlined,
      Icons.person_outline_rounded,
    ];

    return Scaffold(
      backgroundColor: Colors.white10,
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

                  CustomPaint(
                    size: Size(size.width, 80),
                    painter: BNBCustomPainter(color: navBg),
                  ),

                  Center(
                    heightFactor: 0.35, // height of circle
                    child: SizedBox( // circle size
                      width: 65,
                      height: 65,
                      child: FloatingActionButton(
                        onPressed: _onQRPressed,
                        backgroundColor: accentYellow,
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

                  SizedBox(
                    width: size.width,
                    height: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (i) {
                        if (i == 2) {
                          return Container(width: size.width * 0.20);
                        }

                        final isActive = _currentIndex == i;
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

// custom painter for curve bar
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
      Offset(size.width * 0.60, 12), // 12 - higher or lower curve
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