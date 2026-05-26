import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/utils/app_colors.dart';

class AcademicRecordsScreen extends StatefulWidget {
  final User user;

  const AcademicRecordsScreen({super.key, required this.user});

  @override
  State<AcademicRecordsScreen> createState() => _AcademicRecordsScreenState();
}

class _AcademicRecordsScreenState extends State<AcademicRecordsScreen> {
  String selectedCategory = 'Academic';
  int? expandedAssessmentIndex;

  @override
  Widget build(BuildContext context) {
    bool isYouthCenter = selectedCategory == 'Youth Center (FFA)';

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
      body: _buildMainRecordsDashboard(isYouthCenter),
    );
  }

  Widget _buildMainRecordsDashboard(bool isYouthCenter) {
    bool isInjury = selectedCategory == 'Injury';

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
              _buildCategoryChip('Youth Center (FFA)', isSelected: selectedCategory == 'Youth Center (FFA)'),
              const SizedBox(width: 8),
              _buildCategoryChip('Injury', isSelected: selectedCategory == 'Injury'),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
          child: Text(
            isYouthCenter ? 'Youth Center Assessments' : '$selectedCategory Records',
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
                ? Center(
              key: const ValueKey('InjuryEmptyState'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 56,
                    color: AppColors.grayText.withAlpha(120),
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
                ],
              ),
            )
                : ListView.builder(
              key: ValueKey('RecordsList_$selectedCategory'),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: 2,
              itemBuilder: (context, index) {
                return isYouthCenter
                    ? _buildYouthCenterAssessmentCard(index)
                    : _buildAcademicCard();
              },
            ),
          ),
        ),
      ],
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
              color: isSelected
                  ? AppColors.tertiary
                  : AppColors.surface.withAlpha(50),
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

  Widget _buildAcademicCard() {
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MANILA SENIOR HIGH SCHOOL',
                style: TextStyle(
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
                          '2025 - 2026',
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
                          '4th',
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
                          '90.00',
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
                          '12',
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
    bool isExpanded = expandedAssessmentIndex == index;

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
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: const Text(
                  'Oral Presentation',
                  style: TextStyle(
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
                    child: const Text(
                      'PRESENTATION',
                      style: TextStyle(
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
                          const Text(
                            'Date: 05/26/26',
                            style: TextStyle(
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
                        value: 0.94,
                        backgroundColor: AppColors.scaffoldBackground,
                        color: AppColors.onTertiaryContainer,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(fontFamily: AppFonts.roboto, fontSize: 13),
                            children: [
                              TextSpan(
                                text: '94 ',
                                style: TextStyle(color: AppColors.onTertiaryContainer, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: '/ 100',
                                style: TextStyle(color: AppColors.grayText, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      )
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
}