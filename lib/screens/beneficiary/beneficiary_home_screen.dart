import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'package:fairallmobile/screens/beneficiary/notification_screen.dart';

class BeneficiaryHomeScreen extends StatefulWidget {
  final User user;

  const BeneficiaryHomeScreen({super.key, required this.user});

  @override
  State<BeneficiaryHomeScreen> createState() => _BeneficiaryHomeScreenState();
}

class _BeneficiaryHomeScreenState extends State<BeneficiaryHomeScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  String _eqAttendance = 'N/A';
  String _tutorialAttendance = 'N/A';
  String _gwaScore = 'N/A';
  String _socioEmotional = 'N/A';

  // State variable to store recent activity data items
  List<dynamic> _recentActivities = [];

  final List<String> _presetYears = ['Year', 'Custom'];
  String _dropdownYear = 'Year';
  bool get _isCustom => _dropdownYear == 'Custom';

  int _yearValue = DateTime.now().year;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  String _dropdownCategory = 'Education';
  final List<String> _categories = ['Education', 'Sports'];

  String _appliedQuery = '';
  String _appliedCategory = 'Education';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, 1, 1);
    _dateTo = now;
    _appliedQuery = 'year=${now.year}';
    _fetchDashboard();
  }

  void _applyFilters() {
    setState(() {
      _appliedCategory = _dropdownCategory;
      if (_isCustom) {
        final from = _dateFrom != null
            ? '${_dateFrom!.year}-${_dateFrom!.month.toString().padLeft(2, '0')}-${_dateFrom!.day.toString().padLeft(2, '0')}'
            : '';
        final to = _dateTo != null
            ? '${_dateTo!.year}-${_dateTo!.month.toString().padLeft(2, '0')}-${_dateTo!.day.toString().padLeft(2, '0')}'
            : '';
        _appliedQuery = 'date_from=$from&date_to=$to';
      } else {
        _appliedQuery = 'year=$_yearValue';
      }
    });
    _fetchDashboard();
  }

  void _resetFilters() {
    final now = DateTime.now();
    setState(() {
      _dropdownYear = 'Year';
      _yearValue = now.year;
      _dateFrom = DateTime(now.year, 1, 1);
      _dateTo = now;
      _dropdownCategory = 'Education';
      _appliedQuery = 'year=${now.year}';
      _appliedCategory = 'Education';
    });
    _fetchDashboard();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? (_dateFrom ?? DateTime.now()) : (_dateTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.tertiary,
              onPrimary: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
          if (_dateTo != null && _dateTo!.isBefore(picked)) {
            _dateTo = picked;
          }
        } else {
          _dateTo = picked;
          if (_dateFrom != null && _dateFrom!.isAfter(picked)) {
            _dateFrom = picked;
          }
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final queryParams = '$_appliedQuery&category=$_appliedCategory';
      final response = await ApiService.get('/beneficiary/dashboard?$queryParams');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final metrics = data['data']['metrics'] ?? data['data'];

          setState(() {
            _eqAttendance = _formatPercentage(metrics['eq_attendance']);
            _tutorialAttendance = _formatPercentage(metrics['tutorial_attendance']);
            _gwaScore = metrics['gwa']?.toString() ?? 'N/A';
            _socioEmotional = metrics['socio_emotional']?.toString() ?? 'N/A';

            // Extracts activity array from backend if present, fallback to local mock data matching image properties
            _recentActivities = data['data']['recent_activities'] ?? [
              {'title': 'EQ Session attended', 'date': 'June 9, 2026', 'type': 'eq'},
              {'title': 'Tutorial Session attended', 'date': 'June 10, 2026', 'type': 'tutorial'},
              {'title': 'Tutorial Session attended', 'date': 'June 8, 2026', 'type': 'tutorial'},
            ];

            _isLoading = false;
          });
        } else {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      } else {
        try {
          final errData = jsonDecode(response.body);
          print('❌ Dashboard API ${response.statusCode}: $errData');
        } catch (_) {
          print('❌ Dashboard API ${response.statusCode}: ${response.body}');
        }
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Dashboard exception: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  String _formatPercentage(dynamic value) {
    if (value == null) return 'N/A';
    final num = double.tryParse(value.toString());
    if (num == null) return value.toString();
    return '${num.toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        leading: null,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(user: widget.user),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? _buildError()
          : RefreshIndicator(
        onRefresh: _fetchDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 24),
              _buildFilters(),
              const SizedBox(height: 24),
              _buildSectionTitle(),
              const SizedBox(height: 16),
              _buildMetricsGrid(),
              const SizedBox(height: 28),
              // Appended layout section for recent logs
              _buildRecentActivitiesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surface.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.tertiary,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Period'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _dropdownYear,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                items: _presetYears.map((opt) {
                  return DropdownMenuItem(
                    value: opt,
                    child: Text(opt),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _dropdownYear = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (!_isCustom) ...[
            _buildFieldLabel('Enter Year'),
            const SizedBox(height: 8),
            _buildYearStepper(),
          ],
          if (_isCustom) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('From'),
                      const SizedBox(height: 8),
                      _buildDateField(
                        date: _dateFrom,
                        onTap: () => _pickDate(isFrom: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('To'),
                      const SizedBox(height: 8),
                      _buildDateField(
                        date: _dateTo,
                        onTap: () => _pickDate(isFrom: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          _buildFieldLabel('Category'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _dropdownCategory,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _dropdownCategory = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      foregroundColor: const Color(0xFF1F2937),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildYearStepper() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _yearValue.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 44,
                  width: 44,
                  child: IconButton(
                    onPressed: () {
                      final maxYear = DateTime.now().year;
                      if (_yearValue < maxYear) {
                        setState(() => _yearValue++);
                      }
                    },
                    icon: const Icon(Icons.keyboard_arrow_up_rounded),
                    color: const Color(0xFF1F2937),
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    tooltip: 'Increase',
                  ),
                ),
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                SizedBox(
                  height: 44,
                  width: 44,
                  child: IconButton(
                    onPressed: () {
                      if (_yearValue > 1900) {
                        setState(() => _yearValue--);
                      }
                    },
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    color: const Color(0xFF1F2937),
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    tooltip: 'Decrease',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({required DateTime? date, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: date != null ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                date != null ? _formatDate(date) : 'Select date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: date != null ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.analytics_rounded,
            size: 20,
            color: AppColors.surface,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Performance Analytics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildMetricCard(
              'EQ Attendance',
              _eqAttendance,
              Icons.checklist_rounded,
              const Color(0xFF4CAF50),
              null,
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard(
              'Tutorial Attendance',
              _tutorialAttendance,
              Icons.menu_book_rounded,
              const Color(0xFF2196F3),
              null,
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildMetricCard(
              'GWA Score',
              _gwaScore,
              Icons.grade_rounded,
              const Color(0xFFFF9800),
              null,
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard(
              'Socio-Emotional',
              _socioEmotional,
              Icons.favorite_rounded,
              const Color(0xFFE91E63),
              null,
            )),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color iconColor, double? progress) {
    final bool hasValue = value != 'N/A';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.surface.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const Spacer(),
              if (hasValue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    value.contains('%') ? '%' : value,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: iconColor.withAlpha(150),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.surface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.grayText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (progress != null && hasValue) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: iconColor,
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- RECENT ACTIVITIES UI BUILDERS ---

  Widget _buildRecentActivitiesSection() {
    if (_recentActivities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with custom icon from mockup
        Row(
          children: [
            const Icon(
              Icons.business_center_outlined, // Matches the suitcase logo icon safely
              size: 24,
              color: AppColors.surface,
            ),
            const SizedBox(width: 12),
            const Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.surface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Grouped dynamic list setup
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _recentActivities.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _recentActivities[index];
            return _buildActivityCard(item);
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    // Dynamic indicator dot styling parsed down from 'type'
    final String type = activity['type'] ?? 'tutorial';
    final Color indicatorColor = type == 'eq' ? Colors.orange : const Color(0xFF00E676);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Styled bullet marker dot
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 14),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content metadata column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppColors.grayText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activity['date'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grayText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.grayText),
          const SizedBox(height: 16),
          const Text(
            'Failed to load dashboard',
            style: TextStyle(color: AppColors.grayText, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchDashboard,
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
}