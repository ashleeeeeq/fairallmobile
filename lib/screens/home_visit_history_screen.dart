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


  // Pagination
  int _currentPage = 1;
  static const int _itemsPerPage = 5;


  final List<String> filterOptions = ['All', '2025', '2026', '2027', '2028'];


  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _currentPage = 1;
      });
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
            _currentPage = 1;
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
    final totalRecords = filteredVisits.length;
    final totalPages = (totalRecords / _itemsPerPage).ceil();
    final showEmptyState = filteredVisits.isEmpty && !_isLoading;


    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = startIndex + _itemsPerPage;
    final paginatedVisits = filteredVisits.sublist(
      startIndex,
      endIndex > totalRecords ? totalRecords : endIndex,
    );


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
                  : '$totalRecords record${totalRecords != 1 ? 's' : ''} found',
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              itemCount: paginatedVisits.length,
              itemBuilder: (context, index) =>
                  _buildVisitCard(context, paginatedVisits[index]),
            ),
          ),
          if (!showEmptyState && totalPages > 1)
            _buildPaginationControls(totalPages),
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
                      setState(() {
                        selectedFilter = newValue;
                        _currentPage = 1;
                      });
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
    final String rawType = _getSafeString(visit['visit_type'], defaultValue: 'Routine');
    String displayType = _capitalizeWords(rawType);


    final String purpose = _capitalizeWords(_getSafeString(visit['purpose'], defaultValue: 'Home Visit'));
    final String formattedDate = visit['formatted_date'] ?? _formatDate(visit['schedule']);
    final String formattedTime = visit['formatted_time'] ?? _formatTime(visit['schedule']);

    Color badgeBg;
    Color badgeText;

    // colors
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

    return Container(
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppFonts.roboto,
                                height: 1.5,
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
                                fontSize: 12,
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
                              fontSize: 14,
                              fontFamily: AppFonts.roboto,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time_rounded,
                              size: 15,
                              color: AppColors.surface.withAlpha(102)),
                          const SizedBox(width: 6),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              color: AppColors.surface.withAlpha(128),
                              fontSize: 14,
                              fontFamily: AppFonts.roboto,
                            ),
                          ),
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


  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          Text(
            'Page $_currentPage of $totalPages',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.surface,
              fontFamily: AppFonts.roboto,
            ),
          ),
          IconButton(
            onPressed: _currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

