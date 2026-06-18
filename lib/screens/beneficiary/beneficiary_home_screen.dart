import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'package:fairallmobile/widgets/notification_bell.dart';

class BeneficiaryHomeScreen extends StatefulWidget {
  final User user;

  const BeneficiaryHomeScreen({super.key, required this.user});

  @override
  State<BeneficiaryHomeScreen> createState() => _BeneficiaryHomeScreenState();
}

class _BeneficiaryHomeScreenState extends State<BeneficiaryHomeScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _hasError = false;

  String _eqAttendance = 'N/A';
  String _tutorialAttendance = 'N/A';
  String _gwaScore = 'N/A';
  String _socioEmotional = 'N/A';

  List<dynamic> _upcomingActivities = [];

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
    WidgetsBinding.instance.addObserver(this);
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, 1, 1);
    _dateTo = now;
    _appliedQuery = 'year=${now.year}';
    _fetchDashboard();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchDashboard();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
    final initial = isFrom
        ? (_dateFrom ?? DateTime.now())
        : (_dateTo ?? DateTime.now());
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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    final lowercaseWords = {'in', 'of', 'the', 'a', 'an', 'and', 'or', 'for', 'to', 'with', 'on', 'at', 'by'};
    final words = text.split(' ');
    return words.asMap().entries.map((entry) {
      final raw = entry.value;
      if (raw.isEmpty) return raw;
      final lower = raw.toLowerCase();
      if (entry.key > 0 && lowercaseWords.contains(lower)) return lower;
      if (lower.contains('-')) {
        return lower.split('-').map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1);
        }).join('-');
      }
      return lower[0].toUpperCase() + lower.substring(1);
    }).join(' ');
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final queryParams = '$_appliedQuery&category=$_appliedCategory';
      final results = await Future.wait([
        ApiService.get('/beneficiary/dashboard?$queryParams'),
        ApiService.get('/beneficiary/activities'),
        ApiService.get('/beneficiary/home-visits'),
      ]);
      final response = results[0];
      final activitiesResponse = results[1];
      final homeVisitsResponse = results[2];

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final metrics = data['data']['metrics'] ?? data['data'];

          final eqAttendance = _formatPercentage(metrics['eq_attendance']);
          final tutorialAttendance = _formatPercentage(
            metrics['tutorial_attendance'],
          );
          final gwaScore = metrics['gwa']?.toString() ?? 'N/A';
          final socioEmotional =
              metrics['socio_emotional']?.toString() ?? 'N/A';

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final List<Map<String, dynamic>> combined = [];

          final raw = data['data']['upcoming_activities'] ?? <dynamic>[];
          for (final item in raw) {
            if (item is! Map) continue;
            final dateStr = item['date'] as String?;
            if (dateStr == null || dateStr.isEmpty) continue;
            DateTime? parsed;
            for (final fmt in ['MMM d, yyyy', 'MMMM d, yyyy', 'yyyy-MM-dd', 'M/d/yyyy']) {
              try {
                parsed = DateFormat(fmt).parse(dateStr);
                break;
              } catch (_) {}
            }
            if (parsed == null || parsed.isBefore(today)) continue;
            combined.add({
              ...Map<String, dynamic>.from(item),
              '_type': 'session',
            });
          }

          if (activitiesResponse.statusCode == 200) {
            final actData = jsonDecode(activitiesResponse.body);
            if (actData['success'] == true) {
              final active = List<dynamic>.from(actData['data']['active'] ?? []);
              for (final item in active) {
                if (item is! Map || item['category']?.toString() != 'Events') continue;
                final start = item['start'] as String?;
                if (start == null || start.isEmpty) continue;
                try {
                  final date = DateTime.parse(start);
                  final sDate = DateTime(date.year, date.month, date.day);
                  if (!sDate.isBefore(today)) {
                    combined.add({
                      ...Map<String, dynamic>.from(item),
                      '_type': 'event',
                      'date': '${_months[date.month - 1]} ${date.day}, ${date.year}',
                    });
                  }
                } catch (_) {}
              }
            }
          }

          if (homeVisitsResponse.statusCode == 200) {
            final hvData = jsonDecode(homeVisitsResponse.body);
            if (hvData['success'] == true) {
              final visits = List<dynamic>.from(hvData['data'] ?? []);
              for (final item in visits) {
                if (item is! Map) continue;
                final schedule = item['schedule'] as String?;
                if (schedule == null || schedule.isEmpty) continue;
                try {
                  final date = DateTime.parse(schedule);
                  final sDate = DateTime(date.year, date.month, date.day);
                  if (!sDate.isBefore(today)) {
                    final purpose = _capitalize(item['purpose']?.toString() ?? 'Home Visit');
                    combined.add({
                      ...Map<String, dynamic>.from(item),
                      '_type': 'home_visit',
                      'title': purpose,
                      'date': item['formatted_date'] ?? '${_months[date.month - 1]} ${date.day}, ${date.year}',
                    });
                  }
                } catch (_) {}
              }
            }
          }

          combined.sort((a, b) {
            final aDate = a['date']?.toString() ?? '';
            final bDate = b['date']?.toString() ?? '';
            return aDate.compareTo(bDate);
          });

          setState(() {
            _eqAttendance = eqAttendance;
            _tutorialAttendance = tutorialAttendance;
            _gwaScore = gwaScore;
            _socioEmotional = socioEmotional;
            _upcomingActivities = combined;
            _isLoading = false;
          });
        } else {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [NotificationBell(user: widget.user, role: 'beneficiary')],
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
              const SizedBox(height: 32),
              _buildSectionHeader(Icons.analytics_rounded, 'Performance Analytics'),
              const SizedBox(height: 10),
              _buildMetricsGrid(),
              const SizedBox(height: 32),
              _buildSectionHeader(Icons.history_rounded, 'Upcoming Activities'),
              const SizedBox(height: 10),
              _buildUpcomingActivitiesSection(),
            ],
          ),
        ),
      ),
    );
  }

  static const _welcomePadding = EdgeInsets.all(20);
  static const _welcomeIconPadding = EdgeInsets.all(12);
  static const _welcomeBorderRadius = BorderRadius.all(Radius.circular(20));
  static const _welcomeIconBorderRadius = BorderRadius.all(Radius.circular(16));
  static const _filterPadding = EdgeInsets.all(18);
  static const _filterBorderRadius = BorderRadius.all(Radius.circular(20));
  static const _fieldBorderRadius = BorderRadius.all(Radius.circular(14));

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: _welcomePadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: _welcomeBorderRadius,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
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
            padding: _welcomeIconPadding,
            decoration: BoxDecoration(
              color: AppColors.tertiary.withAlpha(45),
              border: Border.all(
                color: AppColors.tertiary.withAlpha(80),
                width: 1.5,
              ),
              borderRadius: _welcomeIconBorderRadius,
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
      padding: _filterPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: _filterBorderRadius,
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
              borderRadius: _fieldBorderRadius,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _dropdownYear,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF9CA3AF),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                items: _presetYears.map((opt) {
                  return DropdownMenuItem(value: opt, child: Text(opt));
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
              borderRadius: _fieldBorderRadius,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _dropdownCategory,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF9CA3AF),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
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
                        borderRadius: _fieldBorderRadius,
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: _fieldBorderRadius,
                      ),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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
        borderRadius: _fieldBorderRadius,
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
              border: Border(left: BorderSide(color: Colors.grey.shade200)),
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
                Container(height: 1, color: Colors.grey.shade200),
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

  Widget _buildDateField({
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: _fieldBorderRadius,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: date != null
                  ? const Color(0xFF1F2937)
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                date != null ? _formatDate(date) : 'Select date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: date != null
                      ? const Color(0xFF1F2937)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface.withAlpha(25), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.surface),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'EQ Attendance',
                _eqAttendance,
                const Color(0xFFDCFCE7),
                const Color(0xFF16A34A),
                Icons.checklist_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Tutorial Attendance',
                _tutorialAttendance,
                const Color(0xFFE8F0FE),
                const Color(0xFF1A56DB),
                Icons.menu_book_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'GWA Score',
                _gwaScore,
                const Color(0xFFFFF9DB),
                const Color(0xFFC68A00),
                Icons.grade_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Socio-Emotional',
                _socioEmotional,
                const Color(0xFFFFF0E6),
                AppColors.orangeAccent,
                Icons.favorite_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color iconBg, Color iconColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.surface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.grayText),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingActivitiesSection() {
    if (_upcomingActivities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECF5)),
        ),
        child: const Column(
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Color(0xFFCBD5E0)),
            SizedBox(height: 8),
            Text(
              'No upcoming activities yet',
              style: TextStyle(color: AppColors.grayText, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _upcomingActivities
          .map((item) => _buildActivityCard(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final String itemType = activity['_type'] ?? 'session';

    Color indicatorColor = AppColors.orangeAccent;
    IconData leadingIcon = Icons.class_rounded;
    String badgeText = 'SESSION';
    Color badgeBg = AppColors.tertiaryContainer;
    Color badgeTextCol = AppColors.onTertiaryContainer;

    switch (itemType) {
      case 'event':
        indicatorColor = const Color(0xFF9333EA);
        leadingIcon = Icons.event_rounded;
        badgeText = 'EVENT';
        badgeBg = const Color(0xFFF3E8FF);
        badgeTextCol = const Color(0xFF7E22CE);
        break;
      case 'home_visit':
        indicatorColor = const Color(0xFF1A56DB);
        leadingIcon = Icons.home_rounded;
        badgeText = 'VISIT';
        badgeBg = const Color(0xFFE8F0FE);
        badgeTextCol = const Color(0xFF1E40AF);
        break;
      default:
        final String sessionType = activity['type'] ?? 'tutorial';
        if (sessionType == 'eq') {
          indicatorColor = const Color(0xFF16A34A);
          leadingIcon = Icons.psychology_rounded;
        }
    }

    final title = activity['title'] ?? activity['name'] ?? 'Activity Item';
    final dateStr = activity['date'] ?? '---';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _toTitleCase(title.toString()),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: AppColors.grayText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateStr.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grayText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (itemType != 'home_visit')
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeTextCol,
                  letterSpacing: 0.5,
                ),
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