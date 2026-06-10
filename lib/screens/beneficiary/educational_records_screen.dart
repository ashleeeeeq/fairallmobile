import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'package:fairallmobile/widgets/notification_bell.dart';
import 'dart:convert';

enum _ViewLevel { enrollments, academicRecords, academicDetail }

class EducationalRecordsScreen extends StatefulWidget {
  final User user;

  const EducationalRecordsScreen({super.key, required this.user});

  @override
  State<EducationalRecordsScreen> createState() => _EducationalRecordsScreenState();
}

class _EducationalRecordsScreenState extends State<EducationalRecordsScreen> {
  _ViewLevel _viewLevel = _ViewLevel.enrollments;

  List<dynamic> _enrollments = [];
  List<dynamic> _academicRecords = [];

  dynamic _selectedEnrollment;
  dynamic _selectedAcademicRecord;

  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() { isLoading = true; hasError = false; });

    try {
      final enrollmentResponse = await ApiService.get('/beneficiary/enrollments');
      if (enrollmentResponse.statusCode == 200) {
        final data = jsonDecode(enrollmentResponse.body);
        _enrollments = data['data'] ?? [];
      }

      final academicResponse = await ApiService.get('/beneficiary/academic-records');
      if (academicResponse.statusCode == 200) {
        final data = jsonDecode(academicResponse.body);
        _academicRecords = data['data'] ?? [];
      }
    } catch (e) {
      setState(() { hasError = true; });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  void _onEnrollmentTap(dynamic enrollment) {
    setState(() {
      _selectedEnrollment = enrollment;
      _viewLevel = _ViewLevel.academicRecords;
    });
  }

  void _onAcademicRecordTap(dynamic record) {
    setState(() {
      _selectedAcademicRecord = record;
      _viewLevel = _ViewLevel.academicDetail;
    });
  }

  void _onBack() {
    setState(() {
      if (_viewLevel == _ViewLevel.academicDetail) {
        _viewLevel = _ViewLevel.academicRecords;
        _selectedAcademicRecord = null;
      } else if (_viewLevel == _ViewLevel.academicRecords) {
        _viewLevel = _ViewLevel.enrollments;
        _selectedEnrollment = null;
      }
    });
  }

  String get _appBarTitle {
    switch (_viewLevel) {
      case _ViewLevel.enrollments:
        return 'Educational Records';
      case _ViewLevel.academicRecords:
        return _selectedEnrollment?['school_name'] ?? 'Academic Records';
      case _ViewLevel.academicDetail:
        final school = _selectedAcademicRecord?['school_name'] ?? '';
        final term = _selectedAcademicRecord?['term'] ?? '';
        return '$school - $term';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: _viewLevel != _ViewLevel.enrollments
            ? IconButton(
                icon: const Icon(Icons.keyboard_arrow_left_rounded, size: 28),
                onPressed: _onBack,
              )
            : null,
        title: Text(
          _appBarTitle,
          style: const TextStyle(fontFamily: AppFonts.roboto, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          NotificationBell(user: widget.user, role: 'beneficiary'),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? _buildError()
          : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.grayText),
          const SizedBox(height: 16),
          Text('Failed to load data', style: TextStyle(color: AppColors.grayText, fontSize: 16, fontFamily: AppFonts.roboto)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchData,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tertiary, foregroundColor: AppColors.surface),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_viewLevel) {
      case _ViewLevel.enrollments:
        return _buildEnrollmentsList();
      case _ViewLevel.academicRecords:
        return _buildAcademicRecordsList();
      case _ViewLevel.academicDetail:
        return _buildAcademicDetail();
    }
  }

  Widget _buildEnrollmentsList() {
    if (_enrollments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 56, color: AppColors.grayText.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No Enrollments Found', style: TextStyle(color: AppColors.grayText, fontSize: 16, fontWeight: FontWeight.w500, fontFamily: AppFonts.roboto)),
            const SizedBox(height: 4),
            Text('School enrollments will appear here', style: TextStyle(color: AppColors.grayText.withValues(alpha: 0.6), fontSize: 13, fontFamily: AppFonts.roboto)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      itemCount: _enrollments.length,
      itemBuilder: (context, index) => _buildEnrollmentCard(_enrollments[index]),
    );
  }

  Widget _buildEnrollmentCard(dynamic enrollment) {
    final schoolName = enrollment['school_name'] ?? 'N/A';
    final academicYear = enrollment['academic_year'] ?? 'N/A';
    final gradeLevel = enrollment['grade_level'] ?? 'N/A';
    final status = (enrollment['status'] ?? '').toString().toLowerCase();

    Color statusColor;
    String statusText;
    switch (status) {
      case 'active': statusColor = Colors.green; statusText = 'ACTIVE'; break;
      case 'completed': statusColor = Colors.blue; statusText = 'COMPLETED'; break;
      case 'transferred': statusColor = Colors.orange; statusText = 'TRANSFERRED'; break;
      case 'dropped': statusColor = Colors.red; statusText = 'DROPPED'; break;
      case 'withdrawn': statusColor = Colors.red; statusText = 'WITHDRAWN'; break;
      case 'repeated': statusColor = Colors.purple; statusText = 'REPEATED'; break;
      default: statusColor = AppColors.grayText; statusText = 'UNKNOWN';
    }

    return GestureDetector(
      onTap: () => _onEnrollmentTap(enrollment),
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
                Container(width: 6, color: AppColors.tertiary),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                schoolName,
                                style: const TextStyle(
                                  color: AppColors.surface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppFonts.roboto,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
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
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.grayText.withValues(alpha: 0.5)),
                            const SizedBox(width: 6),
                            Text(academicYear, style: TextStyle(fontSize: 13, color: AppColors.grayText, fontFamily: AppFonts.roboto)),
                            const SizedBox(width: 16),
                            Icon(Icons.grade_outlined, size: 14, color: AppColors.grayText.withValues(alpha: 0.5)),
                            const SizedBox(width: 6),
                            Text('Grade $gradeLevel', style: TextStyle(fontSize: 13, color: AppColors.grayText, fontFamily: AppFonts.roboto)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'View Records',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.tertiary,
                                fontFamily: AppFonts.roboto,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.tertiary),
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
      ),
    );
  }

  List<dynamic> get _filteredAcademicRecords {
    if (_selectedEnrollment == null) return [];
    final school = (_selectedEnrollment!['school_name'] ?? '').toString().toLowerCase();
    final year = (_selectedEnrollment!['academic_year'] ?? '').toString().toLowerCase();
    return _academicRecords.where((r) {
      final rSchool = (r['school_name'] ?? '').toString().toLowerCase();
      final rYear = (r['academic_year'] ?? '').toString().toLowerCase();
      return rSchool.contains(school) && rYear.contains(year);
    }).toList();
  }

  Widget _buildAcademicRecordsList() {
    final records = _filteredAcademicRecords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_rounded, size: 18, color: AppColors.surface),
              ),
              const SizedBox(width: 12),
              const Text(
                'Academic Records',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                  fontFamily: AppFonts.roboto,
                ),
              ),
            ],
          ),
        ),
        if (records.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined, size: 48, color: AppColors.grayText.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text('No records for this enrollment', style: TextStyle(color: AppColors.grayText, fontSize: 14, fontFamily: AppFonts.roboto)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              itemCount: records.length,
              itemBuilder: (context, index) => _buildAcademicRecordCard(records[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildAcademicRecordCard(dynamic record) {
    final academicYear = record['academic_year'] ?? 'N/A';
    final term = record['term'] ?? 'N/A';
    final gwa = record['gwa']?.toString() ?? 'N/A';

    return GestureDetector(
      onTap: () => _onAcademicRecordTap(record),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.surface.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded, size: 20, color: AppColors.surface),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(academicYear, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.surface, fontFamily: AppFonts.roboto)),
                    const SizedBox(height: 2),
                    Text('Term $term', style: TextStyle(fontSize: 12, color: AppColors.grayText, fontFamily: AppFonts.roboto)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('GWA', style: TextStyle(fontSize: 10, color: AppColors.grayText, fontFamily: AppFonts.roboto)),
                  const SizedBox(height: 2),
                  Text(gwa, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onTertiaryContainer, fontFamily: AppFonts.roboto)),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_right_rounded, color: AppColors.grayText, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcademicDetail() {
    final record = _selectedAcademicRecord;
    if (record == null) return const SizedBox.shrink();

    final schoolName = record['school_name'] ?? 'N/A';
    final academicYear = record['academic_year'] ?? 'N/A';
    final term = record['term'] ?? 'N/A';
    final gwa = record['gwa']?.toString() ?? 'N/A';

    double attendance = 0;
    if (record['school_attendance'] != null) {
      attendance = record['school_attendance'] is int
          ? (record['school_attendance'] as int).toDouble()
          : record['school_attendance'] as double;
    }

    final subjects = record['subjects'] as List<dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.school_rounded, 'School', schoolName),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.calendar_today_rounded, 'Academic Year', academicYear),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.format_list_numbered_rounded, 'Term', term),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.grade_rounded, size: 16, color: AppColors.grayText),
                    const SizedBox(width: 8),
                    Text('GWA: ', style: TextStyle(color: AppColors.grayText, fontSize: 13, fontFamily: AppFonts.roboto)),
                    Text(gwa, style: TextStyle(color: AppColors.onTertiaryContainer, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.trending_up_rounded, size: 16, color: AppColors.grayText),
                    const SizedBox(width: 8),
                    Text('Attendance: ', style: TextStyle(color: AppColors.grayText, fontSize: 13, fontFamily: AppFonts.roboto)),
                    Text('${attendance.toStringAsFixed(2)}%', style: TextStyle(color: AppColors.onTertiaryContainer, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto)),
                  ],
                ),
                if (attendance > 0) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: attendance / 100,
                    backgroundColor: AppColors.scaffoldBackground,
                    color: attendance >= 90 ? Colors.green : (attendance >= 75 ? AppColors.tertiary : Colors.orange),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.book_rounded, size: 18, color: AppColors.surface),
              ),
              const SizedBox(width: 12),
              const Text(
                'Subject Grades',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                  fontFamily: AppFonts.roboto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSubjectGrades(subjects),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grayText),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: AppColors.grayText, fontSize: 13, fontFamily: AppFonts.roboto)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.surface, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectGrades(List<dynamic>? subjects) {
    if (subjects == null || subjects.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('No subject grades available', style: TextStyle(color: AppColors.grayText, fontSize: 13, fontFamily: AppFonts.roboto)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.surface.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              color: AppColors.tertiary,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Subject',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.surface,
                        fontFamily: AppFonts.roboto,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Grade',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.surface,
                        fontFamily: AppFonts.roboto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...subjects.asMap().entries.map((entry) {
              final subject = entry.value as Map<String, dynamic>;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.scaffoldBackground.withValues(alpha: 0.6)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        subject['name'] ?? 'N/A',
                        style: const TextStyle(fontSize: 13, color: AppColors.surface, fontFamily: AppFonts.roboto),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        subject['grade']?.toString() ?? 'N/A',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.surface, fontFamily: AppFonts.roboto),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
