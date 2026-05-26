import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/utils/app_colors.dart';

class ActivitiesScreen extends StatefulWidget {
  final User user;

  const ActivitiesScreen({super.key, required this.user});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  String selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> filterOptions = [
    'All',
    'Attendance',
    'Events',
    'Competitions'
  ];

  @override
  Widget build(BuildContext context) {
    bool showEmptyState = selectedFilter == 'Events' || selectedFilter == 'Competitions';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Activities',
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surface.withAlpha(40)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                            decoration: const InputDecoration(
                              hintText: 'Search',
                              hintStyle: TextStyle(
                                color: AppColors.grayText,
                                fontFamily: AppFonts.roboto,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        Icon(Icons.search, color: AppColors.surface.withAlpha(180)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surface.withAlpha(40)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedFilter,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: AppColors.surface.withAlpha(180)),
                        style: const TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.surface,
                        ),
                        dropdownColor: Colors.white,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedFilter = newValue;
                            });
                          }
                        },
                        items: filterOptions.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
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
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
            child: Text(
              selectedFilter == 'All'
                  ? 'All Activities'
                  : selectedFilter,
              style: const TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: AppColors.surface,
              ),
            ),
          ),

          Expanded(
            child: showEmptyState
                ? const Center(
              child: Text(
                'No records yet',
                style: TextStyle(
                  color: AppColors.grayText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFonts.roboto,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: 3,
              itemBuilder: (context, index) {
                return _buildActivityCard();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
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
                'Y2526-PM-JHS-EQ-SESSION',
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppFonts.roboto,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontFamily: AppFonts.roboto, fontSize: 13),
                          children: [
                            TextSpan(text: 'Date: ', style: TextStyle(color: AppColors.grayText)),
                            TextSpan(text: '05/26/26', style: TextStyle(color: AppColors.surface, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontFamily: AppFonts.roboto, fontSize: 13),
                          children: [
                            TextSpan(text: 'Teacher: ', style: TextStyle(color: AppColors.grayText)),
                            TextSpan(text: 'Daniella Pontigon', style: TextStyle(color: AppColors.surface, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'PRESENT',
                      style: TextStyle(
                        color: AppColors.onTertiaryContainer,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppFonts.roboto,
                      ),
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
}