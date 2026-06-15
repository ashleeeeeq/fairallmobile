import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'package:fairallmobile/widgets/notification_bell.dart';
import 'dart:convert';

class FFAAssessmentsScreen extends StatefulWidget {
  final User user;

  const FFAAssessmentsScreen({super.key, required this.user});

  @override
  State<FFAAssessmentsScreen> createState() => _FFAAssessmentsScreenState();
}

class _FFAAssessmentsScreenState extends State<FFAAssessmentsScreen> {
  List<dynamic> _assessments = [];
  int? _expandedIndex;

  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await ApiService.get('/beneficiary/ffa-assessments');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _assessments = data['data'] ?? [];
      }
    } catch (e) {
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
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'FFA Assessments',
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [NotificationBell(user: widget.user, role: 'beneficiary')],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? _buildError()
          : _assessments.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              itemCount: _assessments.length,
              itemBuilder: (context, index) => _buildAssessmentCard(index),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.grayText),
          const SizedBox(height: 16),
          Text(
            'Failed to load assessments',
            style: TextStyle(
              color: AppColors.grayText,
              fontSize: 16,
              fontFamily: AppFonts.roboto,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchData,
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 56,
            color: AppColors.grayText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No FFA Assessments Found',
            style: TextStyle(
              color: AppColors.grayText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: AppFonts.roboto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Youth center assessments will appear here',
            style: TextStyle(
              color: AppColors.grayText.withValues(alpha: 0.6),
              fontSize: 13,
              fontFamily: AppFonts.roboto,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(int index) {
    final assessment = _assessments[index];
    final bool isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.surface.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.tertiary, width: 6),
            ),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
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
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.surface,
                  size: 28,
                ),
                onTap: () {
                  setState(() {
                    _expandedIndex = isExpanded ? null : index;
                  });
                },
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    bottom: 20.0,
                  ),
                  child: Column(
                    children: [
                      const Divider(
                        height: 1,
                        color: AppColors.scaffoldBackground,
                      ),
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
                        value:
                            (assessment['score'] ?? 0) /
                            (assessment['max_score'] ?? 100),
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
                            style: const TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(
                                text: '${assessment['score'] ?? 0} ',
                                style: TextStyle(
                                  color: AppColors.onTertiaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: '/ ${assessment['max_score'] ?? 100}',
                                style: TextStyle(
                                  color: AppColors.grayText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
