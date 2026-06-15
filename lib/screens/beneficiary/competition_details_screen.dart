import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'package:fairallmobile/widgets/notification_bell.dart';

class CompetitionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> competition;
  final User user;

  const CompetitionDetailsScreen({
    super.key,
    required this.competition,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final placement = competition['placement'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          competition['title'] ?? 'Competition Details',
          style: const TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          NotificationBell(user: user, role: 'beneficiary'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (placement != null) ...[
              _buildPlacementBanner(placement.toString()),
              const SizedBox(height: 24),
            ],
            _buildSectionLabel('Competition Details'),
            const SizedBox(height: 12),
            _buildDetailsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacementBanner(String placement) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF6D00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE65100).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            placement,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
              fontFamily: AppFonts.roboto,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Placement',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
              fontFamily: AppFonts.roboto,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFFF3C00),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: AppColors.surface.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: AppFonts.roboto,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
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
          _buildDetailTile(
            icon: Icons.emoji_events_outlined,
            iconColor: const Color(0xFFFF3C00),
            label: 'Competition Name',
            value: competition['title'] ?? 'N/A',
          ),
          _buildDetailTile(
            icon: Icons.class_outlined,
            iconColor: AppColors.program,
            label: 'Program',
            value: competition['program'] ?? 'N/A',
          ),
          _buildDetailTile(
            icon: Icons.category_outlined,
            iconColor: const Color(0xFF7C4DFF),
            label: 'Type',
            value: competition['type'] ?? 'N/A',
          ),
          _buildDetailTile(
            icon: Icons.public_outlined,
            iconColor: const Color(0xFF0288D1),
            label: 'Scale',
            value: competition['scale'] ?? 'N/A',
          ),
          _buildDetailTile(
            icon: Icons.business_outlined,
            iconColor: const Color(0xFFBF6B2E),
            label: 'Organizer',
            value: competition['organizer'] ?? 'N/A',
          ),
          _buildDetailTile(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFFE53935),
            label: 'Location',
            value: competition['location'] ?? 'N/A',
          ),
          _buildDetailTile(
            icon: Icons.calendar_today_outlined,
            iconColor: const Color(0xFF2E7D32),
            label: 'Date',
            value: competition['date'] ?? competition['start'] ?? 'N/A',
          ),
          _buildDetailTile(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF5B7FA6),
            label: 'Description',
            value: competition['description'] ?? 'No description available',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.surface.withValues(alpha: 0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFonts.roboto,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFonts.roboto,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Divider(
                height: 1, color: AppColors.surface.withValues(alpha: 0.07)),
          ),
      ],
    );
  }
}
