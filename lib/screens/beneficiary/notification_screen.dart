import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/utils/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  final User user;

  const NotificationScreen({
    super.key,
    required this.user,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool showAll = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_left, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Notification',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton(
                            title: 'All',
                            isActive: showAll,
                            onTap: () => setState(() => showAll = true)
                        ),
                        _buildTabButton(
                            title: 'Unread',
                            isActive: !showAll,
                            badgeCount: 3,
                            onTap: () => setState(() => showAll = false)
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.done_all, size: 18, color: AppColors.surface),
                    label: const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        fontFamily: AppFonts.roboto,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildNotificationCard(),
              const SizedBox(height: 12),
              _buildNotificationCard(),
              const SizedBox(height: 12),
              _buildNotificationCard(),

              const SizedBox(height: 110),
            ],
          ),
        ),
      );
    }

  Widget _buildTabButton({required String title, required bool isActive, int? badgeCount, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.tertiary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: AppFonts.roboto,
                color: AppColors.surface,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: AppColors.grayText, shape: BoxShape.circle),
                child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_rounded, color: AppColors.orangeAccent, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ATTENDANCE ALERT',
                          style: TextStyle(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.w900,
                            fontFamily: AppFonts.roboto,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '10 mins ago',
                          style: const TextStyle(color: AppColors.grayText, fontSize: 11, fontFamily: AppFonts.roboto),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Beneficiary X has 60% attendance rate, which is below minimum att.',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: AppFonts.roboto),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightredbg,
                    foregroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () {},
                  child: const Text('Delete',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: AppFonts.roboto)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tertiaryContainer,
                    foregroundColor: AppColors.onTertiaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () {},
                  child: const Text('Mark as read',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: AppFonts.roboto)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}