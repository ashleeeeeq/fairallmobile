import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'package:fairallmobile/widgets/notification_bell.dart';
import 'dart:convert';

class ActivityDetailsScreen extends StatefulWidget {
  final int activityId;
  final User user;

  const ActivityDetailsScreen({
    super.key,
    required this.activityId,
    required this.user,
  });

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  Map<String, dynamic> _activityData = {};
  bool _isLoading = true;
  bool _hasError = false;
  bool _isRegistering = false;

  String? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _fetchActivityDetails();
  }

  Future<void> _fetchActivityDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await ApiService.get('/beneficiary/activities/${widget.activityId}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _activityData = data['data'] ?? {};
        });
      } else {
        setState(() {
          _hasError = true;
        });
      }
    } catch (e) {
      print('Error fetching activity details: $e');
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registerForActivity() async {
    setState(() {
      _isRegistering = true;
    });

    try {
      final response = await ApiService.post('/beneficiary/activities/${widget.activityId}/register', {});

      if (response.statusCode == 201) {
        _showSnackBar('Successfully registered for the activity!', Colors.green);
        await _fetchActivityDetails();
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(data['message'] ?? 'Registration failed', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Connection error. Please try again.', Colors.red);
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceSummary = _activityData['attendance_summary'] ?? {
      'present': 0, 'late': 0, 'absent': 0, 'excused': 0
    };
    final pastSessions = _activityData['past_sessions'] as List<dynamic>? ?? [];
    final upcomingSessions = _activityData['upcoming_sessions'] as List<dynamic>? ?? [];
    final rawAttendanceRecords = [...pastSessions, ...upcomingSessions];
    final isRegistered = _activityData['is_registered'] ?? false;

    final filteredAttendanceRecords = rawAttendanceRecords.where((record) {
      if (_selectedStatusFilter == null) return true;
      final recordStatus = (record['status'] ?? '').toString().toUpperCase();
      return recordStatus == _selectedStatusFilter;
    }).toList();

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
          _activityData['title'] ?? 'Activity Details',
          style: const TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: FontWeight.bold,
          ),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_activityData['program'] ?? 'Program'} • ${_activityData['category'] ?? 'Category'}',
                style: const TextStyle(
                  color: AppColors.surface,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppFonts.roboto,
                ),
              ),
              const SizedBox(height: 16),

              if (!isRegistered)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isRegistering ? null : _registerForActivity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tertiary,
                        foregroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isRegistering
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                          : const Text(
                        'Register for this Activity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),

              Row(
                children: [
                  _buildSummaryButton('Present', 'PRESENT', attendanceSummary['present'] ?? 0, const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  _buildSummaryButton('Late', 'LATE', attendanceSummary['late'] ?? 0, const Color(0xFFFFF3E0), const Color(0xFFEF6C00)),
                  const SizedBox(width: 8),
                  _buildSummaryButton('Excused', 'EXCUSED', attendanceSummary['excused'] ?? 0, const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  _buildSummaryButton('Absent', 'ABSENT', attendanceSummary['absent'] ?? 0, const Color(0xFFFFEBEE), const Color(0xFFC62828)),
                ],
              ),
              const SizedBox(height: 16),

              if (_selectedStatusFilter != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing only: $_selectedStatusFilter',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.surface),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _selectedStatusFilter = null),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('Clear Filter', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.surface.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: filteredAttendanceRecords.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No matching records found',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                      : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        color: AppColors.tertiary,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Center(
                                child: Text(
                                  'DATE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: AppColors.surface,
                                    fontFamily: AppFonts.roboto,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: Text(
                                  'TIME',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: AppColors.surface,
                                    fontFamily: AppFonts.roboto,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: Text(
                                  'STATUS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: AppColors.surface,
                                    fontFamily: AppFonts.roboto,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredAttendanceRecords.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.surface.withValues(alpha: 0.05),
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final record = filteredAttendanceRecords[index];
                          return Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 13,
                                        color: AppColors.surface.withValues(alpha: 0.35),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          record['date'] ?? '',
                                          style: const TextStyle(
                                            color: AppColors.surface,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            fontFamily: AppFonts.roboto,
                                          ),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 13,
                                        color: AppColors.surface.withValues(alpha: 0.35),
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          record['time'] ?? '',
                                          style: TextStyle(
                                            color: AppColors.surface.withValues(alpha: 0.6),
                                            fontSize: 13,
                                            fontFamily: AppFonts.roboto,
                                          ),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Center(
                                    child: _buildStatusBadge(record['status'] ?? 'ABSENT'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        color: AppColors.tertiary,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Items Listed',
                              style: TextStyle(
                                color: AppColors.surface,
                                fontSize: 13,
                                fontFamily: AppFonts.roboto,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${filteredAttendanceRecords.length}',
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontSize: 14,
                                fontFamily: AppFonts.roboto,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.grayText),
          const SizedBox(height: 16),
          Text(
            'Failed to load activity details',
            style: TextStyle(color: AppColors.grayText, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchActivityDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tertiary,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryButton(String label, String statusKey, int count, Color bgColor, Color textColor) {
    final bool isSelected = _selectedStatusFilter == statusKey;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_selectedStatusFilter == statusKey) {
              _selectedStatusFilter = null;
            } else {
              _selectedStatusFilter = statusKey;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? textColor : Colors.transparent,
              width: 2.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: AppFonts.roboto,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFonts.roboto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'PRESENT':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'LATE':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFEF6C00);
        break;
      case 'EXCUSED':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        break;
      case 'ABSENT':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: AppFonts.roboto,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}