import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'package:fairallmobile/widgets/notification_bell.dart';
import 'dart:convert';

class EventDetailsScreen extends StatefulWidget {
  final int eventId;
  final User user;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    required this.user,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  Map<String, dynamic> _eventData = {};
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
  }

  Future<void> _fetchEventDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await ApiService.get(
        '/beneficiary/events/${widget.eventId}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _eventData = data['data'] ?? {};
        });
      } else {
        setState(() {
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          _eventData['title'] ?? 'Event Details',
          style: const TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [NotificationBell(user: widget.user, role: 'beneficiary')],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? _buildErrorWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_eventData['is_registered'] == true) ...[
                    _buildAttendanceBanner(),
                    const SizedBox(height: 24),
                  ],

                  // event Details Card
                  _buildSectionLabel('Event Details'),
                  const SizedBox(height: 12),
                  _buildDetailsCard(),
                ],
              ),
            ),
    );
  }

  // attendance banner
  Widget _buildAttendanceBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
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
              Icons.check_circle_rounded,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Attendance Recorded',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              fontFamily: AppFonts.roboto,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your participation has been confirmed.',
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

  // section label with left accent bar
  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF7C4DFF),
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
          // Program
          _buildDetailTile(
            icon: Icons.event_outlined,
            iconColor: AppColors.mutedevents,
            label: 'Event Name',
            value: _eventData['title'] ?? 'N/A',
          ),
          _buildDetailTile(
            icon: Icons.class_outlined,
            iconColor: AppColors.program,
            label: 'Program / Category',
            value: _eventData['program'] ?? 'Program',
          ),
          _buildDetailTile(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFFBF6B2E),
            label: 'Location',
            value: _eventData['location'] ?? 'N/A',
          ),
          _buildDetailTile(
            icon: Icons.play_circle_outline_rounded,
            iconColor: const Color(0xFF2E7D32),
            label: 'Start',
            value: _eventData['start'] ?? 'N/A',
          ),
          _buildDetailTile(
            icon: Icons.stop_circle_outlined,
            iconColor: const Color(0xFFAD7A7A),
            label: 'End',
            value: _eventData['end'] ?? 'N/A',
            isLast: true,
          ),
          _buildDetailTile(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF5B7FA6),
            label: 'Description',
            value: _eventData['description'] ?? 'No description available',
          ),
        ],
      ),
    );
  }

  // detail row
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
              height: 1,
              color: AppColors.surface.withValues(alpha: 0.07),
            ),
          ),
      ],
    );
  }

  // error
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.surface.withValues(alpha: 0.08),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.grayText,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Failed to load event details',
            style: TextStyle(
              color: AppColors.grayText,
              fontSize: 16,
              fontFamily: AppFonts.roboto,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please check your connection and try again.',
            style: TextStyle(
              color: AppColors.grayText.withValues(alpha: 0.6),
              fontSize: 13,
              fontFamily: AppFonts.roboto,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchEventDetails,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Try Again',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tertiary,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
