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
    setState(() { _isLoading = true; _hasError = false; });

    try {
      final response = await ApiService.get('/beneficiary/events/${widget.eventId}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() { _eventData = data['data'] ?? {}; });
      } else {
        setState(() { _hasError = true; });
      }
    } catch (e) {
      setState(() { _hasError = true; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

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
        title: Text(
          _eventData['title'] ?? 'Event Details',
          style: const TextStyle(fontFamily: AppFonts.roboto, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          NotificationBell(user: widget.user, role: 'beneficiary'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? _buildErrorWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event, size: 20, color: AppColors.surface),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_eventData['program'] ?? 'Program'} • ${_eventData['category'] ?? 'Event'}',
                          style: const TextStyle(color: AppColors.surface, fontSize: 17, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_eventData['is_registered'] == true)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 18, color: Color(0xFF2E7D32)),
                          SizedBox(width: 8),
                          Text('Attendance Recorded', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: AppFonts.roboto)),
                        ],
                      ),
                    ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.surface.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.description_outlined, 'Description', _eventData['description'] ?? 'No description available'),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
                        _buildInfoRow(Icons.location_on_outlined, 'Location', _eventData['location'] ?? 'N/A'),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
                        _buildInfoRow(Icons.calendar_today_outlined, 'Start', _eventData['start'] ?? 'N/A'),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
                        _buildInfoRow(Icons.event_busy_outlined, 'End', _eventData['end'] ?? 'N/A'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.surface.withValues(alpha: 0.5)),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: AppColors.surface.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w600, fontFamily: AppFonts.roboto)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: AppColors.surface, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto)),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.grayText),
          const SizedBox(height: 16),
          Text('Failed to load event details', style: TextStyle(color: AppColors.grayText, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchEventDetails,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tertiary, foregroundColor: AppColors.surface),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
