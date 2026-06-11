import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/widgets/notification_bell.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'activity_details_screen.dart';
import 'event_details_screen.dart';

import 'dart:convert';

class ActivitiesScreen extends StatefulWidget {
  final User user;
  const ActivitiesScreen({super.key, required this.user});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  String selectedFilter = 'All';
  String selectedCategory = 'Activities';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _homeVisitSearchController = TextEditingController();

  List<dynamic> _activeActivities = [];
  List<dynamic> _archivedActivities = [];
  bool _isLoading = true;
  bool _hasError = false;

  List<dynamic> _allHomeVisits = [];
  bool _homeVisitsLoading = false;
  bool _homeVisitsError = false;

  final List<String> filterOptions = ['All', 'Active', 'Archive'];
  final List<String> categoryOptions = ['Activities', 'Events', 'Competitions', 'Home Visits'];

  @override
  void initState() {
    super.initState();
    _fetchActivities();
    _fetchHomeVisits();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await ApiService.get('/beneficiary/activities');
      print('Activities response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Activities response: ${response.body}');

        if (data['success'] == true) {
          final responseData = data['data'];

          setState(() {
            _activeActivities = List<dynamic>.from(responseData['active'] ?? []);
            _archivedActivities = List<dynamic>.from(responseData['archived'] ?? []);
            _isLoading = false;
          });
          print('✅ Loaded ${_activeActivities.length} active, ${_archivedActivities.length} archived activities');
        } else {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          print('❌ API returned success=false');
        }
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        print('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching activities: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchHomeVisits() async {
    setState(() { _homeVisitsLoading = true; _homeVisitsError = false; });
    try {
      final response = await ApiService.get('/beneficiary/home-visits');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() { _allHomeVisits = List<dynamic>.from(data['data']); _homeVisitsLoading = false; });
        } else {
          setState(() { _homeVisitsError = true; _homeVisitsLoading = false; });
        }
      } else {
        setState(() { _homeVisitsError = true; _homeVisitsLoading = false; });
      }
    } catch (e) {
      setState(() { _homeVisitsError = true; _homeVisitsLoading = false; });
    }
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty || text == 'null' || text == 'Null') return '';
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null || dateString.toString().isEmpty) return 'Date TBD';
    try {
      final date = DateTime.parse(dateString.toString());
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      final str = dateString.toString();
      return str.contains(' ') ? str.split(' ').first : str;
    }
  }

  String _formatTime(dynamic dateTimeString) {
    if (dateTimeString == null || dateTimeString.toString().isEmpty) return 'Time TBD';
    try {
      final date = DateTime.parse(dateTimeString.toString());
      int hour = date.hour;
      final minute = date.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$hour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      final str = dateTimeString.toString();
      if (str.contains(' ')) return str.split(' ').last;
      return 'Time TBD';
    }
  }

  String _getSafeString(dynamic value, {String defaultValue = ''}) {
    if (value == null || value.toString() == 'null') return defaultValue;
    return value.toString();
  }

  List<dynamic> get _filteredActivities {
    List<dynamic> filtered = [];

    if (selectedFilter == 'Active') {
      filtered = List.from(_activeActivities);
    } else if (selectedFilter == 'Archive') {
      filtered = List.from(_archivedActivities);
    } else {
      filtered = [..._activeActivities, ..._archivedActivities];
    }

    if (selectedCategory != 'Home Visits') {
      final catLower = selectedCategory.toLowerCase();
      filtered = filtered.where((activity) {
        final category = (activity['category'] ?? '').toString().toLowerCase();
        return category.contains(catLower);
      }).toList();
    }

    final searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((activity) {
        final title = (activity['title'] ?? '').toString().toLowerCase();
        final category = (activity['category'] ?? '').toString().toLowerCase();
        final program = (activity['program'] ?? '').toString().toLowerCase();

        return title.contains(searchQuery) ||
            category.contains(searchQuery) ||
            program.contains(searchQuery);
      }).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _homeVisitSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredActivities = _filteredActivities;
    final homeVisitsCount = _allHomeVisits.length;
    final showEmptyState = selectedCategory == 'Home Visits' ? homeVisitsCount == 0 : filteredActivities.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? _buildErrorWidget()
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchAndFilter(),
          _buildCategoryChips(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Text(
              showEmptyState
                  ? ''
                  : selectedCategory == 'Home Visits'
                  ? '$homeVisitsCount record${homeVisitsCount != 1 ? 's' : ''} found'
                  : '${filteredActivities.length} record${filteredActivities.length != 1 ? 's' : ''} found',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.surface.withValues(alpha:0.45),
                fontFamily: AppFonts.roboto,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: selectedCategory == 'Home Visits'
                ? _buildHomeVisitsContent()
                : showEmptyState
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              itemCount: filteredActivities.length,
              itemBuilder: (context, index) {
                final item = filteredActivities[index];
                final cat = (item['category'] ?? '').toString();
                if (cat == 'Events') {
                  return _buildEventCard(context, item);
                } else if (cat == 'Competitions') {
                  return _buildCompetitionCard(context, item);
                }
                return _buildActivityCard(context, item);
              },
            ),
          ),
        ],
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
            'Failed to load activity history.',
            style: TextStyle(color: AppColors.grayText, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchActivities,
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Activity History',
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppColors.surface,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        NotificationBell(user: widget.user, role: 'beneficiary'),
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
                    color: AppColors.surface.withValues(alpha:0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontFamily: AppFonts.roboto,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search activities...',
                        hintStyle: TextStyle(
                          color: AppColors.surface.withValues(alpha:0.35),
                          fontFamily: AppFonts.roboto,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, size: 18, color: AppColors.surface.withValues(alpha:0.4)),
                          onPressed: () {
                            _searchController.clear();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                            : null,
                      ),
                    ),
                  ),
                  Icon(Icons.search_rounded,
                      color: AppColors.surface.withValues(alpha:0.4), size: 20),
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
                    color: AppColors.surface.withValues(alpha:0.07),
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
                      color: AppColors.surface.withValues(alpha:0.5), size: 20),
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

  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: categoryOptions.asMap().entries.map((entry) {
            final i = entry.key;
            final isSelected = selectedCategory == entry.value;
            return Padding(
              padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => selectedCategory = entry.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.tertiary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.tertiary : AppColors.surface.withAlpha(50),
                    ),
                  ),
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.surface : AppColors.grayText,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHomeVisitsContent() {
    if (_homeVisitsLoading) return const Center(child: CircularProgressIndicator());
    if (_homeVisitsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: AppColors.grayText),
            const SizedBox(height: 12),
            Text('Failed to load home visits', style: TextStyle(color: AppColors.grayText, fontSize: 16, fontFamily: AppFonts.roboto)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchHomeVisits,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.tertiary, foregroundColor: AppColors.surface),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_allHomeVisits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_work_outlined, size: 56, color: AppColors.surface.withAlpha(38)),
            const SizedBox(height: 14),
            Text('No Home Visits Found', style: TextStyle(color: AppColors.surface.withAlpha(90), fontSize: 16, fontWeight: FontWeight.w600, fontFamily: AppFonts.roboto)),
            const SizedBox(height: 4),
            Text('Home visits recorded by staff will appear here', style: TextStyle(color: AppColors.surface.withAlpha(64), fontSize: 13, fontFamily: AppFonts.roboto), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      itemCount: _allHomeVisits.length,
      itemBuilder: (context, index) => _buildHomeVisitCard(_allHomeVisits[index]),
    );
  }

  Widget _buildHomeVisitCard(dynamic visit) {
    final String rawType = _getSafeString(visit['visit_type'], defaultValue: 'Routine');
    String displayType = _capitalizeWords(rawType);
    final String purpose = _capitalizeWords(_getSafeString(visit['purpose'], defaultValue: 'Home Visit'));
    final String formattedDate = visit['formatted_date'] ?? _formatDate(visit['schedule']);
    final String formattedTime = visit['formatted_time'] ?? _formatTime(visit['schedule']);

    Color badgeBg;
    Color badgeText;
    switch (rawType.toLowerCase()) {
      case 'routine': badgeBg = const Color(0xFFE8F5E9); badgeText = const Color(0xFF2E7D32); break;
      case 'emergency': badgeBg = const Color(0xFFFFEBEE); badgeText = const Color(0xFFC62828); break;
      case 'follow-up': badgeBg = const Color(0xFFE3F2FD); badgeText = const Color(0xFF1565C0); break;
      default: badgeBg = const Color(0xFFFFF3E0); badgeText = const Color(0xFFEF6C00);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.surface.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: AppColors.tertiary),
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
                            child: Text(purpose, style: const TextStyle(color: AppColors.surface, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                            child: Text(displayType.toUpperCase(), style: TextStyle(color: badgeText, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.surface.withValues(alpha: 0.4)),
                          const SizedBox(width: 6),
                          Text(formattedDate, style: TextStyle(color: AppColors.surface.withValues(alpha: 0.5), fontSize: 14, fontFamily: AppFonts.roboto)),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time_rounded, size: 14, color: AppColors.surface.withValues(alpha: 0.4)),
                          const SizedBox(width: 6),
                          Text(formattedTime, style: TextStyle(color: AppColors.surface.withValues(alpha: 0.5), fontSize: 14, fontFamily: AppFonts.roboto)),
                        ],
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

  Widget _buildEmptyState() {
    String searchQuery = _searchController.text.trim();

    if (searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.surface.withValues(alpha:0.15),
            ),
            const SizedBox(height: 14),
            Text(
              'No matching activities',
              style: TextStyle(
                color: AppColors.surface.withValues(alpha:0.35),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppFonts.roboto,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search or filter',
              style: TextStyle(
                color: AppColors.surface.withValues(alpha:0.25),
                fontSize: 13,
                fontFamily: AppFonts.roboto,
              ),
            ),
          ],
        ),
      );
    }

    if (selectedFilter == 'Active' && _activeActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration_outlined,
              size: 56,
              color: AppColors.surface.withValues(alpha:0.15),
            ),
            const SizedBox(height: 14),
            Text(
              'No active activities',
              style: TextStyle(
                color: AppColors.surface.withValues(alpha:0.35),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppFonts.roboto,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You are not registered for any active activities',
              style: TextStyle(
                color: AppColors.surface.withValues(alpha:0.25),
                fontSize: 13,
                fontFamily: AppFonts.roboto,
              ),
            ),
          ],
        ),
      );
    }

    if (selectedFilter == 'Archive' && _archivedActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.archive_outlined,
              size: 56,
              color: AppColors.surface.withValues(alpha:0.15),
            ),
            const SizedBox(height: 14),
            Text(
              'No archived activities',
              style: TextStyle(
                color: AppColors.surface.withValues(alpha:0.35),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppFonts.roboto,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Completed activities will appear here',
              style: TextStyle(
                color: AppColors.surface.withValues(alpha:0.25),
                fontSize: 13,
                fontFamily: AppFonts.roboto,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 56,
            color: AppColors.surface.withValues(alpha:0.15),
          ),
          const SizedBox(height: 14),
          Text(
            'No activities yet',
            style: TextStyle(
              color: AppColors.surface.withValues(alpha:0.35),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: AppFonts.roboto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Activities will appear here once available',
            style: TextStyle(
              color: AppColors.surface.withValues(alpha:0.25),
              fontSize: 13,
              fontFamily: AppFonts.roboto,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, dynamic activity) {
    final isActiveValue = activity['is_active_flag'] ?? activity['is_active'] ?? 0;
    final isActive = isActiveValue == 1;

    final isRegistered = activity['is_registered'] ?? false;

    // Determine status text and color
    String statusText = isActive ? 'ACTIVE' : 'ARCHIVED';
    Color statusColor = isActive ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00);
    Color statusBgColor = isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);

    return GestureDetector(
      onTap: () => _navigateToDetails(context, activity['id'], category: activity['category'] ?? ''),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.surface.withValues(alpha:0.07),
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
                  color: isActive ? AppColors.tertiary : Colors.grey.shade400,
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
                                activity['title'] ?? 'Activity',
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
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
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
                                color: AppColors.surface.withValues(alpha:0.4)),
                            const SizedBox(width: 5),
                            Text(
                              activity['category'] ?? 'General',
                              style: TextStyle(
                                color: AppColors.surface.withValues(alpha:0.5),
                                fontSize: 16,
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
                            onPressed: () => _navigateToDetails(context, activity['id'], category: activity['category'] ?? ''),
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

  Widget _buildEventCard(BuildContext context, dynamic event) {
    final isActive = (event['is_active_flag'] ?? event['is_active'] ?? 0) == 1;
    final statusText = isActive ? 'ACTIVE' : 'ARCHIVED';
    final statusColor = isActive ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00);
    final statusBgColor = isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);

    return GestureDetector(
      onTap: () => _navigateToDetails(context, event['id'], category: 'Events'),
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
                Container(width: 6, color: const Color(0xFF7C4DFF)),
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
                                event['title'] ?? 'Event',
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
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
                            Icon(Icons.event, size: 14, color: AppColors.surface.withValues(alpha: 0.4)),
                            const SizedBox(width: 5),
                            Text(
                              event['program'] ?? 'N/A',
                              style: TextStyle(
                                color: AppColors.surface.withValues(alpha: 0.5),
                                fontSize: 13,
                                fontFamily: AppFonts.roboto,
                              ),
                            ),
                          ],
                        ),
                        if (event['location'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: AppColors.surface.withValues(alpha: 0.4)),
                              const SizedBox(width: 5),
                              Text(
                                event['location'],
                                style: TextStyle(
                                  color: AppColors.surface.withValues(alpha: 0.5),
                                  fontSize: 13,
                                  fontFamily: AppFonts.roboto,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (event['start'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: AppColors.surface.withValues(alpha: 0.4)),
                              const SizedBox(width: 5),
                              Text(
                                event['start'],
                                style: TextStyle(
                                  color: AppColors.surface.withValues(alpha: 0.5),
                                  fontSize: 13,
                                  fontFamily: AppFonts.roboto,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () => _navigateToDetails(context, event['id'], category: 'Events'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C4DFF),
                              foregroundColor: AppColors.surface,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                        ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: AppFonts.roboto)),
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

  Widget _buildCompetitionCard(BuildContext context, dynamic competition) {
    final isActive = (competition['is_active_flag'] ?? competition['is_active'] ?? 0) == 1;
    final statusText = isActive ? 'ACTIVE' : 'ARCHIVED';
    final statusColor = isActive ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00);
    final statusBgColor = isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final type = competition['type'] ?? '';
    final scale = competition['scale'] ?? '';

    return Container(
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
              Container(width: 6, color: const Color(0xFFFF6D00)),
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
                                competition['title'] ?? 'Competition',
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
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
                            Icon(Icons.emoji_events_outlined, size: 14, color: AppColors.surface.withValues(alpha: 0.4)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                competition['program'] ?? 'N/A',
                                style: TextStyle(
                                  color: AppColors.surface.withValues(alpha: 0.5),
                                  fontSize: 13,
                                  fontFamily: AppFonts.roboto,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (type.isNotEmpty || scale.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.category_outlined, size: 14, color: AppColors.surface.withValues(alpha: 0.4)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${type.isNotEmpty ? _capitalizeWords(type) : ''}${type.isNotEmpty && scale.isNotEmpty ? ' • ' : ''}${scale.isNotEmpty ? _capitalizeWords(scale) : ''}',
                                  style: TextStyle(
                                    color: AppColors.surface.withValues(alpha: 0.5),
                                    fontSize: 13,
                                    fontFamily: AppFonts.roboto,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (competition['organizer'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.business_outlined, size: 14, color: AppColors.surface.withValues(alpha: 0.4)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  competition['organizer'],
                                  style: TextStyle(
                                    color: AppColors.surface.withValues(alpha: 0.5),
                                    fontSize: 13,
                                    fontFamily: AppFonts.roboto,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events, size: 18, color: const Color(0xFFEF6C00)),
                              const SizedBox(width: 8),
                              Text(
                                competition['placement'] != null
                                    ? 'Placement: ${competition['placement']}'
                                    : 'No placement recorded',
                                style: TextStyle(
                                  color: const Color(0xFFEF6C00),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  fontFamily: AppFonts.roboto,
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

  void _navigateToDetails(BuildContext context, int itemId, {String category = ''}) {
    if (category == 'Events') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventDetailsScreen(
            eventId: itemId,
            user: widget.user,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivityDetailsScreen(
            activityId: itemId,
            user: widget.user,
          ),
        ),
      );
    }
  }

  void _navigateToEventDetails(BuildContext context, int eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(
          eventId: eventId,
          user: widget.user,
        ),
      ),
    );
  }
}