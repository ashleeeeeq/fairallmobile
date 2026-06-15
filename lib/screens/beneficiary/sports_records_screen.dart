import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'package:fairallmobile/widgets/notification_bell.dart';
import 'dart:convert';

class SportsRecordsScreen extends StatefulWidget {
  final User user;

  const SportsRecordsScreen({super.key, required this.user});

  @override
  State<SportsRecordsScreen> createState() => _SportsRecordsScreenState();
}

class _SportsRecordsScreenState extends State<SportsRecordsScreen> {
  List<dynamic> _injuryRecords = [];
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
      final response = await ApiService.get('/beneficiary/injury-records');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _injuryRecords = data['data'] ?? [];
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
          'Sports Records',
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
          : _injuryRecords.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              itemCount: _injuryRecords.length,
              itemBuilder: (context, index) =>
                  _buildInjuryCard(_injuryRecords[index]),
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
            'Failed to load injury records',
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
            Icons.fitness_center_outlined,
            size: 56,
            color: AppColors.grayText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No Injury Recorded',
            style: TextStyle(
              color: AppColors.grayText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: AppFonts.roboto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sports injury records will appear here',
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

  Widget _buildInjuryCard(dynamic injury) {
    final String displayInjuryType =
        injury['formatted_injury_type'] ?? (injury['injury_type'] ?? 'Injury');
    final String displaySeverity =
        injury['formatted_severity']?.toUpperCase() ??
        (injury['severity'] ?? 'MINOR').toString().toUpperCase();
    final String displayBodyPart =
        injury['formatted_body_part'] ?? (injury['body_part'] ?? '');
    final String displayStartDate =
        injury['formatted_start_date'] ?? (injury['recovery_start_date'] ?? '');
    final String displayStatus =
        injury['formatted_status'] ?? (injury['status'] ?? '');
    final String displayRemarks = injury['remarks'] ?? '';

    final String rawSeverity = (injury['severity'] ?? 'minor')
        .toString()
        .toLowerCase();
    final bool isMajorOrSevere =
        rawSeverity == 'major' || rawSeverity == 'severe';

    Color severityColor = isMajorOrSevere
        ? AppColors.error
        : AppColors.onTertiaryContainer;
    Color severityBg = isMajorOrSevere
        ? AppColors.error.withValues(alpha: 0.12)
        : AppColors.onTertiaryContainer.withValues(alpha: 0.12);

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
              Container(width: 6, color: severityColor),
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
                              displayInjuryType,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: severityBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              displaySeverity,
                              style: TextStyle(
                                color: severityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppFonts.roboto,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.healing_rounded,
                            size: 14,
                            color: AppColors.grayText.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Part: $displayBodyPart',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.grayText,
                              fontFamily: AppFonts.roboto,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppColors.grayText.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Date: $displayStartDate',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.grayText,
                              fontFamily: AppFonts.roboto,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: AppColors.grayText.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              displayStatus,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.grayText,
                                fontFamily: AppFonts.roboto,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (displayRemarks.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            displayRemarks,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grayText,
                              fontFamily: AppFonts.roboto,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
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
}
