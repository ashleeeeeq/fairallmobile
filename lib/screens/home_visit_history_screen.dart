import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';

class HomeVisitHistoryScreen extends StatefulWidget {
  const HomeVisitHistoryScreen({super.key});

  @override
  State<HomeVisitHistoryScreen> createState() => _HomeVisitHistoryScreenState();
}

class _HomeVisitHistoryScreenState extends State<HomeVisitHistoryScreen> {
  String selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _allVisits = [];
  bool _isLoading = true;
  bool _hasError = false;

  final List<String> filterOptions = ['All', '2025', '2026', '2027', '2028'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    _fetchHomeVisits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHomeVisits() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await ApiService.get('/beneficiary/home-visits');
      print('📋 Home Visits Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _allVisits = List<dynamic>.from(data['data']);
            _isLoading = false;
          });
          print('✅ Loaded ${_allVisits.length} home visits');
        } else {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          print('❌ API returned success=false: ${data['message']}');
        }
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        print('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching home visits: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // Helper function to capitalize first letter of each word
  String _capitalizeWords(String text) {
    if (text.isEmpty || text == 'null' || text == 'Null') return '';
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Helper function to format date nicely
  String _formatDate(dynamic dateString) {
    if (dateString == null || dateString.toString().isEmpty) return 'Date TBD';
    try {
      final date = DateTime.parse(dateString.toString());
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      final str = dateString.toString();
      return str.contains(' ') ? str.split(' ').first : str;
    }
  }

  // Helper function to format time nicely
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
      if (str.contains(' ')) {
        return str.split(' ').last;
      }
      return 'Time TBD';
    }
  }

  String _getSafeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value.toString() == 'null') return defaultValue;
    return value.toString();
  }

  List<dynamic> get _filteredVisits {
    final query = _searchController.text.trim().toLowerCase();

    return _allVisits.where((visit) {
      String yearPart = '';
      final formattedDate = _getSafeString(visit['formatted_date']);
      if (formattedDate.contains('/')) {
        yearPart = formattedDate.split('/').last;
      } else {
        final schedule = _getSafeString(visit['schedule']);
        final datePart = schedule.split(' ').first;
        if (datePart.contains('-')) {
          yearPart = datePart.split('-').first;
        }
      }

      final matchesYear = selectedFilter == 'All' || yearPart == selectedFilter;

      final matchesSearch = query.isEmpty ||
          _getSafeString(visit['purpose']).toLowerCase().contains(query) ||
          _getSafeString(visit['visit_type']).toLowerCase().contains(query) ||
          _getSafeString(visit['notes']).toLowerCase().contains(query);

      return matchesYear && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredVisits = _filteredVisits;
    final showEmptyState = filteredVisits.isEmpty && !_isLoading;

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
                  : '${filteredVisits.length} record${filteredVisits.length != 1 ? 's' : ''} found',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.surface.withAlpha(115),
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
              itemCount: filteredVisits.length,
              itemBuilder: (context, index) =>
                  _buildVisitCard(context, filteredVisits[index]),
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
            'Failed to load home visits',
            style: TextStyle(color: AppColors.grayText, fontSize: 16, fontFamily: AppFonts.roboto),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchHomeVisits,
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
        'Home Visits',
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: AppColors.surface,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchHomeVisits,
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
                    color: AppColors.surface.withAlpha(18),
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
                        hintText: 'Search visits...',
                        hintStyle: TextStyle(
                          color: AppColors.surface.withAlpha(90),
                          fontFamily: AppFonts.roboto,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  Icon(Icons.search_rounded,
                      color: AppColors.surface.withAlpha(102), size: 20),
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
                    color: AppColors.surface.withAlpha(18),
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
                      color: AppColors.surface.withAlpha(128), size: 20),
                  style: const TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.surface,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => selectedFilter = newValue);
                    }
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
            Icons.home_work_outlined,
            size: 56,
            color: AppColors.surface.withAlpha(38),
          ),
          const SizedBox(height: 14),
          Text(
            selectedFilter != 'All' ? 'No visits in year $selectedFilter' : 'No Home Visits Found',
            style: TextStyle(
              color: AppColors.surface.withAlpha(90),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: AppFonts.roboto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Home visits recorded by staff will appear here',
            style: TextStyle(
              color: AppColors.surface.withAlpha(64),
              fontSize: 13,
              fontFamily: AppFonts.roboto,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVisitCard(BuildContext context, dynamic visit) {
    // Safely extract values with null handling
    final String rawType = _getSafeString(visit['visit_type'], defaultValue: 'Routine');
    String displayType = _capitalizeWords(rawType);

    final String purpose = _capitalizeWords(_getSafeString(visit['purpose'], defaultValue: 'Home Visit'));
    final String formattedDate = visit['formatted_date'] ?? _formatDate(visit['schedule']);
    final String formattedTime = visit['formatted_time'] ?? _formatTime(visit['schedule']);
    final String notes = _getSafeString(visit['notes']);

    Color badgeBg;
    Color badgeText;

    switch (rawType.toLowerCase()) {
      case 'routine':
        badgeBg = const Color(0xFFE8F5E9);
        badgeText = const Color(0xFF2E7D32);
        break;
      case 'emergency':
        badgeBg = const Color(0xFFFFEBEE);
        badgeText = const Color(0xFFC62828);
        break;
      case 'follow-up':
        badgeBg = const Color(0xFFE3F2FD);
        badgeText = const Color(0xFF1565C0);
        break;
      default:
        badgeBg = const Color(0xFFFFF3E0);
        badgeText = const Color(0xFFEF6C00);
    }

    return GestureDetector(
      onTap: () => _navigateToDetails(context, visit),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.surface.withAlpha(18),
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
                                purpose,
                                style: const TextStyle(
                                  color: AppColors.surface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppFonts.roboto,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                displayType.toUpperCase(),
                                style: TextStyle(
                                  color: badgeText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppFonts.roboto,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 14,
                                color: AppColors.surface.withAlpha(102)),
                            const SizedBox(width: 6),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: AppColors.surface.withAlpha(128),
                                fontSize: 12,
                                fontFamily: AppFonts.roboto,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time_rounded,
                                size: 14,
                                color: AppColors.surface.withAlpha(102)),
                            const SizedBox(width: 6),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                color: AppColors.surface.withAlpha(128),
                                fontSize: 12,
                                fontFamily: AppFonts.roboto,
                              ),
                            ),
                          ],
                        ),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.description_outlined,
                                  size: 12,
                                  color: AppColors.surface.withAlpha(102)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  notes.length > 80 ? '${notes.substring(0, 80)}...' : notes,
                                  style: TextStyle(
                                    color: AppColors.surface.withAlpha(128),
                                    fontSize: 11,
                                    fontFamily: AppFonts.roboto,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
                            onPressed: () => _navigateToDetails(context, visit),
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

  void _navigateToDetails(BuildContext context, dynamic visit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeVisitDetailsScreen(visitData: visit),
      ),
    );
  }
}

class HomeVisitDetailsScreen extends StatelessWidget {
  final dynamic visitData;

  const HomeVisitDetailsScreen({super.key, required this.visitData});

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
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
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
      if (str.contains(' ')) {
        return str.split(' ').last;
      }
      return 'Time TBD';
    }
  }

  String _getSafeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value.toString() == 'null') return defaultValue;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Safely extract values with null checks
    final String rawVisitType = _getSafeString(visitData['visit_type'], defaultValue: 'Home Visit');
    final String visitType = _capitalizeWords(rawVisitType);
    final String purpose = _capitalizeWords(_getSafeString(visitData['purpose'], defaultValue: 'Home Visit'));
    final String formattedDate = visitData['formatted_date'] ?? _formatDate(visitData['schedule']);
    final String formattedTime = visitData['formatted_time'] ?? _formatTime(visitData['schedule']);
    final String notes = _getSafeString(visitData['notes'], defaultValue: 'No additional notes provided');
    final String staffName = _getSafeString(visitData['assigned_staff_name']);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          visitType,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: AppFonts.roboto,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.surface.withAlpha(13),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Purpose/Center Title - Full width
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withAlpha(26),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  purpose,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.surface,
                    fontFamily: AppFonts.roboto,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Date and Time Row - Full width with equal distribution
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DATE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grayText.withAlpha(179),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.surface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TIME',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grayText.withAlpha(179),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.surface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Visit Type - Full width container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VISIT TYPE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grayText.withAlpha(179),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      visitType,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.surface,
                      ),
                    ),
                  ],
                ),
              ),

              // Staff Name (if available) - Full width container
              if (staffName.isNotEmpty && staffName != 'null') ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASSIGNED STAFF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grayText.withAlpha(179),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _capitalizeWords(staffName),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.surface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Notes - Full width expandable container
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOTES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grayText.withAlpha(179),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notes,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grayText,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}