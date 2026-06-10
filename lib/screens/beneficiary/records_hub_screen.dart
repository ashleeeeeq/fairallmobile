import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'package:fairallmobile/widgets/notification_bell.dart';
import 'dart:convert';

enum _EnrollmentViewLevel { enrollments, academicRecords, academicDetail }

class RecordsHubScreen extends StatefulWidget {
  final User user;

  const RecordsHubScreen({super.key, required this.user});

  @override
  State<RecordsHubScreen> createState() => _RecordsHubScreenState();
}

class _RecordsHubScreenState extends State<RecordsHubScreen> {
  String selectedCategory = 'Enrollment';
  int? _expandedIndex;

  _EnrollmentViewLevel _enrollmentViewLevel = _EnrollmentViewLevel.enrollments;
  dynamic _selectedEnrollment;
  dynamic _selectedAcademicRecord;

  List<dynamic> _enrollments = [];
  List<dynamic> _academicRecords = [];
  List<dynamic> _ffaAssessments = [];
  List<dynamic> _injuryRecords = [];

  bool isLoading = true;
  bool hasError = false;

  bool get _hasSports => _injuryRecords.isNotEmpty;
  bool get _isEnrollmentDrillDown => _enrollmentViewLevel != _EnrollmentViewLevel.enrollments;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() { isLoading = true; hasError = false; });

    try {
      final enrollmentRes = await ApiService.get('/beneficiary/enrollments');
      if (enrollmentRes.statusCode == 200) {
        final data = jsonDecode(enrollmentRes.body);
        _enrollments = data['data'] ?? [];
      }

      final academicRes = await ApiService.get('/beneficiary/academic-records');
      if (academicRes.statusCode == 200) {
        final data = jsonDecode(academicRes.body);
        _academicRecords = data['data'] ?? [];
      }

      final ffaRes = await ApiService.get('/beneficiary/ffa-assessments');
      if (ffaRes.statusCode == 200) {
        final data = jsonDecode(ffaRes.body);
        _ffaAssessments = data['data'] ?? [];
      }

      final injuryRes = await ApiService.get('/beneficiary/injury-records');
      if (injuryRes.statusCode == 200) {
        final data = jsonDecode(injuryRes.body);
        _injuryRecords = data['data'] ?? [];
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
      _enrollmentViewLevel = _EnrollmentViewLevel.academicRecords;
    });
  }

  void _onAcademicRecordTap(dynamic record) {
    setState(() {
      _selectedAcademicRecord = record;
      _enrollmentViewLevel = _EnrollmentViewLevel.academicDetail;
    });
  }

  void _onBack() {
    setState(() {
      if (_enrollmentViewLevel == _EnrollmentViewLevel.academicDetail) {
        _enrollmentViewLevel = _EnrollmentViewLevel.academicRecords;
        _selectedAcademicRecord = null;
      } else if (_enrollmentViewLevel == _EnrollmentViewLevel.academicRecords) {
        _enrollmentViewLevel = _EnrollmentViewLevel.enrollments;
        _selectedEnrollment = null;
      }
    });
  }

  String get _appBarTitle {
    if (_isEnrollmentDrillDown) {
      if (_enrollmentViewLevel == _EnrollmentViewLevel.academicRecords) {
        return _selectedEnrollment?['school_name'] ?? 'Academic Records';
      }
      final record = _selectedAcademicRecord;
      final school = record?['school_name'] ?? '';
      final term = record?['term'] ?? '';
      return '$school - $term';
    }
    return 'Records';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: _isEnrollmentDrillDown
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
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.grayText),
          const SizedBox(height: 16),
          Text('Failed to load records', style: TextStyle(color: AppColors.grayText, fontSize: 16, fontFamily: AppFonts.roboto)),
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

  Widget _buildContent() {
    if (_isEnrollmentDrillDown) {
      return _buildEnrollmentDrillDown();
    }

    final chips = <String>['Enrollment', 'Youth Center'];
    if (_hasSports) chips.add('Injury');

    return Column(
      key: ValueKey('Dashboard_$selectedCategory'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: chips.asMap().entries.map((entry) {
              final i = entry.key;
              return Padding(
                padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
                child: _buildChip(entry.value, isSelected: selectedCategory == entry.value),
              );
            }).toList(),
          ),
        ),
        Expanded(child: _buildRecordsList()),
      ],
    );
  }

  Widget _buildEnrollmentDrillDown() {
    switch (_enrollmentViewLevel) {
      case _EnrollmentViewLevel.academicRecords:
        return _buildAcademicRecordsList();
      case _EnrollmentViewLevel.academicDetail:
        return _buildAcademicDetail();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChip(String title, {required bool isSelected}) {
    return GestureDetector(
      onTap: () => setState(() { selectedCategory = title; _expandedIndex = null; }),
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
          title,
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
    );
  }

  Widget _buildRecordsList() {
    switch (selectedCategory) {
      case 'Enrollment':
        return _buildEnrollmentsList();
      case 'Youth Center':
        return _buildFFAList();
      case 'Injury':
        return _buildInjuryList();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEnrollmentsList() {
    if (_enrollments.isEmpty) {
      return _buildEmpty('No Enrollments Found', Icons.school_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.surface.withAlpha(15), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.tertiary, width: 6)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(schoolName, style: const TextStyle(color: AppColors.surface, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withAlpha(40), borderRadius: BorderRadius.circular(20)),
                      child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.grayText.withAlpha(100)),
                  const SizedBox(width: 6),
                  Text(academicYear, style: TextStyle(fontSize: 13, color: AppColors.grayText, fontFamily: AppFonts.roboto)),
                  const SizedBox(width: 16),
                  Icon(Icons.grade_outlined, size: 14, color: AppColors.grayText.withAlpha(100)),
                  const SizedBox(width: 6),
                  Text('Grade $gradeLevel', style: TextStyle(fontSize: 13, color: AppColors.grayText, fontFamily: AppFonts.roboto)),
                ]),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View Records',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.tertiary, fontFamily: AppFonts.roboto),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.tertiary),
                  ],
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
                  color: AppColors.surface.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_rounded, size: 18, color: AppColors.surface),
              ),
              const SizedBox(width: 12),
              const Text(
                'Academic Records',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.surface, fontFamily: AppFonts.roboto),
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
                  Icon(Icons.assignment_outlined, size: 48, color: AppColors.grayText.withAlpha(100)),
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
            BoxShadow(color: AppColors.surface.withAlpha(15), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withAlpha(40),
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
                BoxShadow(color: AppColors.surface.withAlpha(15), blurRadius: 12, offset: const Offset(0, 4)),
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
                  color: AppColors.surface.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.book_rounded, size: 18, color: AppColors.surface),
              ),
              const SizedBox(width: 12),
              const Text(
                'Subject Grades',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.surface, fontFamily: AppFonts.roboto),
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
          BoxShadow(color: AppColors.surface.withAlpha(15), blurRadius: 10, offset: const Offset(0, 3)),
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
                  Expanded(flex: 3, child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.surface, fontFamily: AppFonts.roboto))),
                  Expanded(flex: 1, child: Text('Grade', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.surface, fontFamily: AppFonts.roboto))),
                ],
              ),
            ),
            ...subjects.asMap().entries.map((entry) {
              final subject = entry.value as Map<String, dynamic>;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.scaffoldBackground.withAlpha(150))),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(subject['name'] ?? 'N/A', style: const TextStyle(fontSize: 13, color: AppColors.surface, fontFamily: AppFonts.roboto))),
                    Expanded(flex: 1, child: Text(subject['grade']?.toString() ?? 'N/A', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.surface, fontFamily: AppFonts.roboto))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFFAList() {
    if (_ffaAssessments.isEmpty) {
      return _buildEmpty('No FFA Assessments Found', Icons.assessment_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      itemCount: _ffaAssessments.length,
      itemBuilder: (context, index) => _buildFFACard(index),
    );
  }

  Widget _buildFFACard(int index) {
    final assessment = _ffaAssessments[index];
    final bool isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.surface.withAlpha(15), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppColors.tertiary, width: 6)),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(assessment['name'] ?? 'Assessment', style: const TextStyle(color: AppColors.surface, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto)),
                subtitle: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.tertiary.withAlpha(40), borderRadius: BorderRadius.circular(20)),
                    child: Text(assessment['category']?.toUpperCase() ?? 'ASSESSMENT', style: const TextStyle(color: AppColors.surface, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto)),
                  ),
                ),
                trailing: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.surface, size: 28),
                onTap: () => setState(() { _expandedIndex = isExpanded ? null : index; }),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Column(
                    children: [
                      const Divider(height: 1, color: AppColors.scaffoldBackground),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(assessment['date'] != null ? 'Date: ${assessment['date']}' : 'Date: N/A', style: const TextStyle(color: AppColors.grayText, fontSize: 13, fontFamily: AppFonts.roboto)),
                          const Text('Score', style: TextStyle(color: AppColors.surface, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (assessment['score'] ?? 0) / (assessment['max_score'] ?? 100),
                        backgroundColor: AppColors.scaffoldBackground,
                        color: AppColors.onTertiaryContainer,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontFamily: AppFonts.roboto, fontSize: 13),
                            children: [
                              TextSpan(text: '${assessment['score'] ?? 0} ', style: TextStyle(color: AppColors.onTertiaryContainer, fontWeight: FontWeight.bold)),
                              TextSpan(text: '/ ${assessment['max_score'] ?? 100}', style: TextStyle(color: AppColors.grayText, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInjuryList() {
    if (_injuryRecords.isEmpty) {
      return _buildEmpty('No Injury Recorded', Icons.inbox_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      itemCount: _injuryRecords.length,
      itemBuilder: (context, index) => _buildInjuryCard(_injuryRecords[index]),
    );
  }

  Widget _buildInjuryCard(dynamic injury) {
    final String displayInjuryType = injury['formatted_injury_type'] ?? (injury['injury_type'] ?? 'Injury');
    final String displaySeverity = injury['formatted_severity']?.toUpperCase() ?? (injury['severity'] ?? 'MINOR').toString().toUpperCase();
    final String displayBodyPart = injury['formatted_body_part'] ?? (injury['body_part'] ?? '');
    final String displayStartDate = injury['formatted_start_date'] ?? (injury['recovery_start_date'] ?? '');
    final String displayStatus = injury['formatted_status'] ?? (injury['status'] ?? '');
    final String displayRemarks = injury['remarks'] ?? '';

    final String rawSeverity = (injury['severity'] ?? 'minor').toString().toLowerCase();
    final bool isMajorOrSevere = rawSeverity == 'major' || rawSeverity == 'severe';
    Color severityColor = isMajorOrSevere ? AppColors.error : AppColors.onTertiaryContainer;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.surface.withAlpha(15), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: severityColor, width: 6)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(displayInjuryType, style: const TextStyle(color: AppColors.surface, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(displaySeverity, style: TextStyle(color: severityColor, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.healing_rounded, size: 14, color: AppColors.grayText.withAlpha(100)),
                const SizedBox(width: 6),
                Text('Part: $displayBodyPart', style: TextStyle(fontSize: 13, color: AppColors.grayText, fontFamily: AppFonts.roboto)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.grayText.withAlpha(100)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('$displayStartDate  •  $displayStatus', style: TextStyle(fontSize: 13, color: AppColors.grayText, fontFamily: AppFonts.roboto), overflow: TextOverflow.ellipsis),
                ),
              ]),
              if (displayRemarks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.scaffoldBackground, borderRadius: BorderRadius.circular(10)),
                  child: Text(displayRemarks, style: const TextStyle(fontSize: 12, color: AppColors.grayText, fontFamily: AppFonts.roboto, height: 1.4)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.grayText.withAlpha(120)),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: AppColors.grayText, fontSize: 16, fontWeight: FontWeight.w500, fontFamily: AppFonts.roboto)),
        ],
      ),
    );
  }
}
