import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'activity_details_screen.dart';
import 'dart:convert';

class ActivitiesScreen extends StatefulWidget {
  final User user;
  const ActivitiesScreen({super.key, required this.user});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  String selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _activities = [];
  bool _isLoading = true;
  bool _hasError = false;

  final List<String> filterOptions = ['All', 'Registered', 'Available'];

  @override
  void initState() {
    super.initState();
    _fetchActivities();
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _activities = data['data'] ?? [];
        });
      } else {
        setState(() {
          _hasError = true;
        });
      }
    } catch (e) {
      print('Error fetching activities: $e');
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredActivities {
    List<dynamic> filtered = _activities;

    // Apply filter (All, Registered, Available)
    if (selectedFilter == 'Registered') {
      filtered = filtered.where((a) => a['is_registered'] == true).toList();
    } else if (selectedFilter == 'Available') {
      filtered = filtered.where((a) => a['is_registered'] == false).toList();
    }

    // Apply search filter
    final searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((activity) {
        final title = (activity['title'] ?? '').toLowerCase();
        final category = (activity['category'] ?? '').toLowerCase();
        final program = (activity['program'] ?? '').toLowerCase();

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredActivities = _filteredActivities;
    final showEmptyState = filteredActivities.isEmpty;

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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Text(
              showEmptyState
                  ? ''
                  : '${filteredActivities.length} record${filteredActivities.length != 1 ? 's' : ''} found',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.surface.withOpacity(0.45),
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
              itemCount: filteredActivities.length,
              itemBuilder: (context, index) =>
                  _buildActivityCard(context, filteredActivities[index]),
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
            'Failed to load activities',
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
                    color: AppColors.surface.withOpacity(0.07),
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
                          color: AppColors.surface.withOpacity(0.35),
                          fontFamily: AppFonts.roboto,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, size: 18, color: AppColors.surface.withOpacity(0.4)),
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
                      color: AppColors.surface.withOpacity(0.4), size: 20),
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
                    color: AppColors.surface.withOpacity(0.07),
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
                      color: AppColors.surface.withOpacity(0.5), size: 20),
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
    String searchQuery = _searchController.text.trim();

    if (searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.surface.withOpacity(0.15),
            ),
            const SizedBox(height: 14),
            Text(
              'No matching activities',
              style: TextStyle(
                color: AppColors.surface.withOpacity(0.35),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppFonts.roboto,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search or filter',
              style: TextStyle(
                color: AppColors.surface.withOpacity(0.25),
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
            color: AppColors.surface.withOpacity(0.15),
          ),
          const SizedBox(height: 14),
          Text(
            selectedFilter == 'Registered' ? 'No registered activities' : 'No activities yet',
            style: TextStyle(
              color: AppColors.surface.withOpacity(0.35),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: AppFonts.roboto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            selectedFilter == 'Registered'
                ? 'Register for activities to see them here'
                : 'Activities will appear here once available',
            style: TextStyle(
              color: AppColors.surface.withOpacity(0.25),
              fontSize: 13,
              fontFamily: AppFonts.roboto,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, dynamic activity) {
    final isRegistered = activity['is_registered'] ?? false;

    return GestureDetector(
      onTap: () => _navigateToDetails(context, activity['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.surface.withOpacity(0.07),
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
                  color: isRegistered ? AppColors.tertiary : Colors.grey.shade300,
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
                                color: isRegistered
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isRegistered ? 'REGISTERED' : 'AVAILABLE',
                                style: TextStyle(
                                  color: isRegistered
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFEF6C00),
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
                                color: AppColors.surface.withOpacity(0.4)),
                            const SizedBox(width: 5),
                            Text(
                              activity['category'] ?? 'General',
                              style: TextStyle(
                                color: AppColors.surface.withOpacity(0.5),
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
                            onPressed: () => _navigateToDetails(context, activity['id']),
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

  void _navigateToDetails(BuildContext context, int activityId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailsScreen(
          activityId: activityId,
          user: widget.user,
        ),
      ),
    );
  }
}