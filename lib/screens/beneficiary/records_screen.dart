import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'dart:convert';

class AcademicRecordsScreen extends StatefulWidget {
  final User user;

  const AcademicRecordsScreen({super.key, required this.user});

  @override
  State<AcademicRecordsScreen> createState() => _AcademicRecordsScreenState();
}

class _AcademicRecordsScreenState extends State<AcademicRecordsScreen> {
  String selectedCategory = 'Academic';
  int? expandedAssessmentIndex;

  // Data from API
  List<dynamic> academicRecords = [];
  List<dynamic> ffaAssessments = [];
  List<dynamic> injuryRecords = [];
  List<dynamic> enrollmentRecords = [];

  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchAllRecords();
  }

  Future<void> fetchAllRecords() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // Fetch academic records
      final academicResponse = await ApiService.get('/beneficiary/academic-records');
      if (academicResponse.statusCode == 200) {
        final data = jsonDecode(academicResponse.body);
        academicRecords = data['data'] ?? [];
        print('Academic records loaded: ${academicRecords.length}');
      }

      // Fetch FFA assessments
      final ffaResponse = await ApiService.get('/beneficiary/ffa-assessments');
      if (ffaResponse.statusCode == 200) {
        final data = jsonDecode(ffaResponse.body);
        ffaAssessments = data['data'] ?? [];
        print('FFA assessments loaded: ${ffaAssessments.length}');
      }

      // Fetch injury records
      final injuryResponse = await ApiService.get('/beneficiary/injury-records');
      if (injuryResponse.statusCode == 200) {
        final data = jsonDecode(injuryResponse.body);
        injuryRecords = data['data'] ?? [];
        print('Injury records loaded: ${injuryRecords.length}');
      }

      // Fetch enrollment records
      final enrollmentResponse = await ApiService.get('/beneficiary/enrollments');
      if (enrollmentResponse.statusCode == 200) {
        final data = jsonDecode(enrollmentResponse.body);
        enrollmentRecords = data['data'] ?? [];
        print('Enrollment records loaded: ${enrollmentRecords.length}');
      }

    } catch (e) {
      print('Error fetching records: $e');
      setState(() {
        hasError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isYouthCenter = selectedCategory == 'Youth Center';
    bool isInjury = selectedCategory == 'Injury';
    bool isEnrollment = selectedCategory == 'Enrollment';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Records',
          style: TextStyle(fontFamily: AppFonts.roboto, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        leading: null,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? _buildErrorWidget()
          : _buildMainRecordsDashboard(isYouthCenter, isInjury, isEnrollment),
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
            'Failed to load records',
            style: TextStyle(color: AppColors.grayText, fontSize: 16, fontFamily: AppFonts.roboto),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchAllRecords,
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

  Widget _buildMainRecordsDashboard(bool isYouthCenter, bool isInjury, bool isEnrollment) {
    return Column(
      key: ValueKey('Dashboard_$selectedCategory'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCategoryChip('Academic', isSelected: selectedCategory == 'Academic'),
              const SizedBox(width: 8),
              _buildCategoryChip('Enrollment', isSelected: selectedCategory == 'Enrollment'),
              const SizedBox(width: 8),
              _buildCategoryChip('Youth Center', isSelected: selectedCategory == 'Youth Center'),
              const SizedBox(width: 8),
              _buildCategoryChip('Injury', isSelected: selectedCategory == 'Injury'),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
          child: Text(
            isYouthCenter ? 'Youth Center Assessments' : isEnrollment ? 'Enrollment Records' : '$selectedCategory Records',
            style: const TextStyle(
              color: AppColors.surface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: AppFonts.roboto,
            ),
          ),
        ),

        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: isInjury
                ? injuryRecords.isEmpty
                ? _buildEmptyState('No Injury Recorded', Icons.inbox_outlined)
                : ListView.builder(
              key: const ValueKey('InjuryList'),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: injuryRecords.length,
              itemBuilder: (context, index) {
                return _buildInjuryCard(injuryRecords[index]);
              },
            )
                : isEnrollment
                ? enrollmentRecords.isEmpty
                ? _buildEmptyState('No Enrollments Found', Icons.school_outlined)
                : ListView.builder(
              key: const ValueKey('EnrollmentList'),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: enrollmentRecords.length,
              itemBuilder: (context, index) {
                return _buildEnrollmentCard(enrollmentRecords[index]);
              },
            )
                : isYouthCenter
                ? ffaAssessments.isEmpty
                ? _buildEmptyState('No Assessments Found', Icons.assessment_outlined)
                : ListView.builder(
                key: const ValueKey('FFAList'),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: ffaAssessments.length,
                itemBuilder: (context, index) {
                  return _buildYouthCenterAssessmentCard(index);
                }
            )
                : academicRecords.isEmpty
                ? _buildEmptyState('No Academic Records Found', Icons.school_outlined)
                : ListView.builder(
              key: const ValueKey('AcademicList'),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: academicRecords.length,
              itemBuilder: (context, index) {
                return _buildAcademicCard(academicRecords[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      key: const ValueKey('EmptyState'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.grayText.withAlpha(120)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: AppColors.grayText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: AppFonts.roboto,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String title, {required bool isSelected}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = title;
            expandedAssessmentIndex = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
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
      ),
    );
  }

  Widget _buildAcademicCard(dynamic record) {
    // Get attendance value with fallback
    double attendance = 0;
    if (record['school_attendance'] != null) {
      attendance = record['school_attendance'] is int
          ? (record['school_attendance'] as int).toDouble()
          : record['school_attendance'] as double;
    }

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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record['school_name'] ?? 'School Name',
                style: const TextStyle(
                  color: AppColors.surface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppFonts.roboto,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text('School Year: ', style: TextStyle(color: AppColors.grayText, fontSize: 13, fontFamily: AppFonts.roboto)),
                        Text(
                          record['academic_year'] ?? 'N/A',
                          style: const TextStyle(color: AppColors.surface, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Text('Term: ', style: TextStyle(color: AppColors.grayText, fontSize: 13, fontFamily: AppFonts.roboto)),
                        Text(
                          record['term'] ?? 'N/A',
                          style: const TextStyle(color: AppColors.surface, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text('GWA: ', style: TextStyle(color: AppColors.grayText, fontSize: 13, fontFamily: AppFonts.roboto)),
                        Text(
                          record['gwa']?.toString() ?? 'N/A',
                          style: TextStyle(color: AppColors.onTertiaryContainer, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Text('Grade Level: ', style: TextStyle(color: AppColors.grayText, fontSize: 13, fontFamily: AppFonts.roboto)),
                        Text(
                          record['grade_level']?.toString() ?? 'N/A',
                          style: const TextStyle(color: AppColors.surface, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // New: School Attendance Row
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text('Attendance: ', style: TextStyle(color: AppColors.grayText, fontSize: 13, fontFamily: AppFonts.roboto)),
                        Text(
                          attendance.toStringAsFixed(1),
                          style: const TextStyle(color: AppColors.tertiary, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto),
                        ),
                        const Text('%', style: TextStyle(color: AppColors.tertiary, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: attendance > 0
                        ? LinearProgressIndicator(
                      value: attendance / 100,
                      backgroundColor: AppColors.scaffoldBackground,
                      color: attendance >= 90 ? Colors.green : (attendance >= 75 ? AppColors.tertiary : Colors.orange),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnrollmentCard(dynamic record) {
    // Map to EducationEnrollment model fields
    final schoolName = record['school_name'] ?? 'N/A';
    final gradeLevel = record['grade_level'] ?? 'N/A';
    final educationLevel = record['education_level'] ?? 'N/A';
    final academicYear = record['academic_year'] ?? 'N/A';
    final enrollmentDate = record['enrollment_date'] ?? 'N/A';
    final status = (record['status'] ?? '').toString().toLowerCase();

    // Map status to badge text and color based on enrollment_status
    Map<String, dynamic> getStatusDisplay(String status) {
      switch (status) {
        case 'active':
          return {
            'text': 'ACTIVE',
            'color': Colors.green,
            'bgColor': Colors.green.withAlpha(40)
          };
        case 'completed':
          return {
            'text': 'COMPLETED',
            'color': Colors.blue,
            'bgColor': Colors.blue.withAlpha(40)
          };
        case 'transferred':
          return {
            'text': 'TRANSFERRED',
            'color': Colors.orange,
            'bgColor': Colors.orange.withAlpha(40)
          };
        case 'dropped':
          return {
            'text': 'DROPPED',
            'color': Colors.red,
            'bgColor': Colors.red.withAlpha(40)
          };
        case 'withdrawn':
          return {
            'text': 'WITHDRAWN',
            'color': Colors.red,
            'bgColor': Colors.red.withAlpha(40)
          };
        case 'repeated':
          return {
            'text': 'REPEATED',
            'color': Colors.purple,
            'bgColor': Colors.purple.withAlpha(40)
          };
        default:
          return {
            'text': 'UNKNOWN',
            'color': AppColors.grayText,
            'bgColor': AppColors.grayText.withAlpha(40)
          };
      }
    }

    final statusDisplay = getStatusDisplay(status);
    final isActive = status == 'active';

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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      schoolName,
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppFonts.roboto,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusDisplay['bgColor'],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusDisplay['text'],
                      style: TextStyle(
                        color: statusDisplay['color'],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppFonts.roboto,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.event, size: 14, color: AppColors.grayText),
                        const SizedBox(width: 4),
                        const Text('Enrolled: ', style: TextStyle(color: AppColors.grayText, fontSize: 13, fontFamily: AppFonts.roboto)),
                        Text(
                          enrollmentDate,
                          style: const TextStyle(color: AppColors.surface, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.grade, size: 14, color: AppColors.grayText),
                        const SizedBox(width: 4),
                        const Text('Level: ', style: TextStyle(color: AppColors.grayText, fontSize: 13, fontFamily: AppFonts.roboto)),
                        Text(
                          gradeLevel,
                          style: const TextStyle(color: AppColors.surface, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.school, size: 14, color: AppColors.grayText),
                        const SizedBox(width: 4),
                        const Text('Education Level: ', style: TextStyle(color: AppColors.grayText, fontSize: 13, fontFamily: AppFonts.roboto)),
                        Text(
                          educationLevel,
                          style: const TextStyle(color: AppColors.surface, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: AppColors.grayText),
                        const SizedBox(width: 4),
                        const Text('School Year: ', style: TextStyle(color: AppColors.grayText, fontSize: 13, fontFamily: AppFonts.roboto)),
                        Text(
                          academicYear,
                          style: const TextStyle(color: AppColors.surface, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AppFonts.roboto),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYouthCenterAssessmentCard(int index) {
    final assessment = ffaAssessments[index];
    bool isExpanded = expandedAssessmentIndex == index;

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
                title: Text(
                  assessment['name'] ?? 'Assessment',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppFonts.roboto,
                  ),
                ),
                subtitle: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      assessment['category']?.toUpperCase() ?? 'ASSESSMENT',
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppFonts.roboto,
                      ),
                    ),
                  ),
                ),
                trailing: Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.surface,
                  size: 28,
                ),
                onTap: () {
                  setState(() {
                    expandedAssessmentIndex = isExpanded ? null : index;
                  });
                },
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
                  child: Column(
                    children: [
                      const Divider(height: 1, color: AppColors.scaffoldBackground),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            assessment['date'] != null
                                ? 'Date: ${assessment['date']}'
                                : 'Date: N/A',
                            style: const TextStyle(
                              color: AppColors.grayText,
                              fontSize: 13,
                              fontFamily: AppFonts.roboto,
                            ),
                          ),
                          const Text(
                            'Score',
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppFonts.roboto,
                            ),
                          ),
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
                              TextSpan(
                                text: '${assessment['score'] ?? 0} ',
                                style: TextStyle(color: AppColors.onTertiaryContainer, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: '/ ${assessment['max_score'] ?? 100}',
                                style: TextStyle(color: AppColors.grayText, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (assessment['remarks'] != null && assessment['remarks'].isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            assessment['remarks'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grayText,
                              fontFamily: AppFonts.roboto,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildInjuryCard(dynamic injury) {
    // Use formatted values from API, with fallbacks to maintain original design
    final String displayInjuryType = injury['formatted_injury_type'] ??
        (injury['injury_type'] ?? 'Injury');

    final String displaySeverity = injury['formatted_severity']?.toUpperCase() ??
        (injury['severity'] ?? 'MINOR').toString().toUpperCase();

    final String displayBodyPart = injury['formatted_body_part'] ??
        (injury['body_part'] ?? '');

    final String displayStartDate = injury['formatted_start_date'] ??
        (injury['recovery_start_date'] ?? '');

    final String displayStatus = injury['formatted_status'] ??
        (injury['status'] ?? '');

    final String displayRemarks = injury['remarks'] ?? '';

    // Determine if severity is major or severe for badge color (original logic)
    final String rawSeverity = (injury['severity'] ?? 'minor').toString().toLowerCase();
    final bool isMajorOrSevere = rawSeverity == 'major' || rawSeverity == 'severe';

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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      displayInjuryType,
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppFonts.roboto,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isMajorOrSevere
                          ? AppColors.error.withAlpha(40)
                          : AppColors.tertiary.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      displaySeverity,
                      style: TextStyle(
                        color: isMajorOrSevere
                            ? AppColors.error
                            : AppColors.surface,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppFonts.roboto,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (displayBodyPart.isNotEmpty)
                Text(
                  'Body Part: $displayBodyPart',
                  style: const TextStyle(fontSize: 14, color: AppColors.grayText, fontFamily: AppFonts.roboto),
                ),
              if (displayStartDate.isNotEmpty)
                Text(
                  'Started: $displayStartDate',
                  style: const TextStyle(fontSize: 12, color: AppColors.grayText, fontFamily: AppFonts.roboto),
                ),
              if (displayStatus.isNotEmpty)
                Text(
                  'Status: $displayStatus',
                  style: const TextStyle(fontSize: 12, color: AppColors.grayText, fontFamily: AppFonts.roboto),
                ),
              if (displayRemarks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    displayRemarks,
                    style: const TextStyle(fontSize: 12, color: AppColors.grayText, fontFamily: AppFonts.roboto),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}