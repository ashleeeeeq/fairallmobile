import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/utils/app_colors.dart';

class ActivitiesScreen extends StatefulWidget {
  final User user;
  const ActivitiesScreen({super.key, required this.user});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  String selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> filterOptions = [
    'All',
    'Attendance',
    'Events',
    'Competitions'
  ];

  final List<Map<String, String>> _activities = const [
    {'title': 'Y2526-PM-JHS-EQ-SESSION', 'category': 'Education', 'status': 'ACTIVE'},
    {'title': 'Y2526-AM-SHS-SP-SESSION', 'category': 'Education', 'status': 'ACTIVE'},
    {'title': 'Y2526-PM-ELEM-SP-SESSION', 'category': 'Sports', 'status': 'ACTIVE'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showEmptyState =
        selectedFilter == 'Events' || selectedFilter == 'Competitions';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchAndFilter(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Text(
              showEmptyState
                  ? ''
                  : '${_activities.length} record${_activities.length != 1 ? 's' : ''} found',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.surface.withValues(alpha: 0.45),
                fontFamily: AppFonts.roboto,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: showEmptyState
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: _activities.length,
              itemBuilder: (context, index) =>
                  _buildActivityCard(context, _activities[index]),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Activities',
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: AppColors.surface,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.surface.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontFamily: AppFonts.roboto,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search activities...',
                        hintStyle: TextStyle(
                          color: AppColors.surface.withValues(alpha: 0.35),
                          fontFamily: AppFonts.roboto,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  Icon(Icons.search_rounded,
                      color: AppColors.surface.withValues(alpha: 0.4), size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.surface.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedFilter,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.surface.withValues(alpha: 0.5), size: 20),
                  style: const TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.surface,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  onChanged: (String? newValue) {
                    if (newValue != null) setState(() => selectedFilter = newValue);
                  },
                  items: filterOptions
                      .map((value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontFamily: AppFonts.roboto,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 56,
            color: AppColors.surface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 14),
          Text(
            'No records yet',
            style: TextStyle(
              color: AppColors.surface.withValues(alpha: 0.35),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: AppFonts.roboto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Records will appear here once available',
            style: TextStyle(
              color: AppColors.surface.withValues(alpha: 0.25),
              fontSize: 13,
              fontFamily: AppFonts.roboto,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, Map<String, String> activity) {
    return GestureDetector(
      onTap: () => _navigateToDetails(context, activity['title']!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.surface.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  color: AppColors.tertiary,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                activity['title']!,
                                style: const TextStyle(
                                  color: AppColors.surface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppFonts.roboto,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                activity['status']!,
                                style: const TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppFonts.roboto,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.description_outlined,
                                size: 14,
                                color: AppColors.surface.withValues(alpha: 0.4)),
                            const SizedBox(width: 5),
                            Text(
                              activity['category']!,
                              style: TextStyle(
                                color: AppColors.surface.withValues(alpha: 0.5),
                                fontSize: 12,
                                fontFamily: AppFonts.roboto,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () =>
                                _navigateToDetails(context, activity['title']!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.tertiary,
                              foregroundColor: AppColors.surface,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    fontFamily: AppFonts.roboto,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, size: 15),
                              ],
                            ),
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
      ),
    );
  }

  void _navigateToDetails(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailsScreen(activityTitle: title),
      ),
    );
  }
}

class ActivityDetailsScreen extends StatelessWidget {
  final String activityTitle;
  const ActivityDetailsScreen({super.key, required this.activityTitle});

  final List<Map<String, String>> attendanceRecords = const [
    {'date': 'May 20, 2026', 'time': '09:00 AM', 'status': 'PRESENT'},
    {'date': 'May 20, 2026', 'time': '09:00 AM', 'status': 'LATE'},
    {'date': 'May 20, 2026', 'time': '09:00 AM', 'status': 'EXCUSED'},
    {'date': 'May 20, 2026', 'time': '09:00 AM', 'status': 'ABSENT'},
    {'date': 'May 20, 2026', 'time': '09:00 AM', 'status': 'PRESENT'},
  ];

  @override
  Widget build(BuildContext context) {
    final counts = {
      'PRESENT': attendanceRecords.where((r) => r['status'] == 'PRESENT').length,
      'LATE':    attendanceRecords.where((r) => r['status'] == 'LATE').length,
      'EXCUSED': attendanceRecords.where((r) => r['status'] == 'EXCUSED').length,
      'ABSENT':  attendanceRecords.where((r) => r['status'] == 'ABSENT').length,
    };

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
          activityTitle,
          style: const TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Education • EQ Session',
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppFonts.roboto,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildSummaryChip('Present', counts['PRESENT']!, const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  _buildSummaryChip('Late', counts['LATE']!, const Color(0xFFFFF3E0), const Color(0xFFEF6C00)),
                  const SizedBox(width: 8),
                  _buildSummaryChip('Excused', counts['EXCUSED']!, const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  _buildSummaryChip('Absent', counts['ABSENT']!, const Color(0xFFFFEBEE), const Color(0xFFC62828)),
                ],
              ),
              const SizedBox(height: 24),

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
                  child: Column(
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
                        itemCount: attendanceRecords.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.surface.withValues(alpha: 0.05),
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final record = attendanceRecords[index];
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
                                          record['date']!,
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
                                          record['time']!,
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
                                    child: _buildStatusBadge(record['status']!),
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
                              'Total Records',
                              style: TextStyle(
                                color: AppColors.surface,
                                fontSize: 13,
                                fontFamily: AppFonts.roboto,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${attendanceRecords.length}',
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

  Widget _buildSummaryChip(String label, int count, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
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