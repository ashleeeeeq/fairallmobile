import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'package:fairallmobile/widgets/notification_bell.dart';
import 'package:fairallmobile/screens/donor/donate_screen.dart';

class DonorHomeScreen extends StatefulWidget {
  final User user;

  const DonorHomeScreen({super.key, required this.user});

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  String _totalDonated = '---';
  String _totalDonations = '---';
  String _yearToDateTotal = '---';
  String _programsSupported = '---';
  String _beneficiariesSupported = '---';
  String _activeSubscriptions = '---';
  String _nextBillingInfo = '';

  String _firstDonationDate = '';
  int _currentStreak = 0;
  List<String> _milestones = [];
  List<String> _supportedBeneficiaryNames = [];

  List<Map<String, dynamic>> _recentDonations = [];
  List<Map<String, dynamic>> _givingByProgram = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await ApiService.get('/donor/dashboard');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final dashData = data['data'];
          final stats = dashData['stats'];
          final recent =
              dashData['recent_donations'] as List<dynamic>? ?? [];
          final programs =
              dashData['giving_by_program'] as List<dynamic>? ?? [];

          // --- stats ---
          final totalDonated =
              double.tryParse(stats['total_donated']?.toString() ?? '0') ?? 0;
          final totalCount =
              int.tryParse(stats['total_donations']?.toString() ?? '0') ?? 0;
          final ytdTotal =
              double.tryParse(stats['year_to_date_total']?.toString() ?? '0') ?? 0;
          final programsCount =
              int.tryParse(stats['programs_supported']?.toString() ?? '0') ?? 0;
          final beneficiariesCount =
              int.tryParse(stats['beneficiaries_supported']?.toString() ?? '0') ?? 0;
          final activeSubs =
              int.tryParse(stats['active_subscriptions']?.toString() ?? '0') ?? 0;

          // --- recent donations ---
          final recentDonations = recent.map((item) {
            final dateStr = item['transaction_date'] as String?;
            String formattedDate = '---';
            if (dateStr != null) {
              try {
                final dt = DateTime.parse(dateStr);
                formattedDate =
                    '${_monthAbbr(dt.month)} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
              } catch (_) {}
            }
            final amount =
                double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
            return {
              'name':
                  item['organization_name'] ??
                  item['program_name'] ??
                  'Donation',
              'date': formattedDate,
              'status': item['status'] ?? 'completed',
              'amount': '₱${_formatAmount(amount)}',
            };
          }).toList();

          // --- giving by program ---
          final ordered = ['Unassigned', 'Sports', 'Education'];
          final programMap = <String, Map<String, dynamic>>{};
          for (final p in programs) {
            final name = (p['program_name'] as String?) ?? 'Unassigned';
            programMap[name] = {
              'name': name,
              'amount': '₱${_formatAmount(double.tryParse(p['total']?.toString() ?? '0') ?? 0)}',
              'progress': double.tryParse(p['progress']?.toString() ?? '0') ?? 0,
            };
          }
          for (final name in ordered) {
            programMap.putIfAbsent(name, () => {
              'name': name,
              'amount': '₱0.00',
              'progress': 0.0,
            });
          }
          final givingByProgram = ordered
              .where((name) => programMap.containsKey(name))
              .map((name) => programMap[name]!)
              .toList();

          // --- first donation date ---
          String firstDateStr = '';
          final rawFirstDate = dashData['first_donation_date'] as String?;
          if (rawFirstDate != null) {
            try {
              final dt = DateTime.parse(rawFirstDate);
              firstDateStr = '${_monthAbbr(dt.month)} ${dt.day}, ${dt.year}';
            } catch (_) {}
          }

          // --- beneficiaries ---
          final beneficiaryNames = (dashData['supported_beneficiaries'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];

          // --- milestones ---
          final milestones = (dashData['milestones'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];

          // --- streak ---
          final streak =
              int.tryParse(dashData['current_streak']?.toString() ?? '0') ?? 0;

          // --- next billing ---
          String nextBillingStr = '';
          if (dashData['next_billing'] != null) {
            final nb = dashData['next_billing'];
            final nbDate = nb['date'] as String?;
            if (nbDate != null) {
              try {
                final dt = DateTime.parse(nbDate);
                nextBillingStr =
                    '${_monthAbbr(dt.month)} ${dt.day}, ${dt.year}';
              } catch (_) {}
            }
          }

          setState(() {
            _totalDonated = '₱${_formatAmount(totalDonated)}';
            _totalDonations = totalCount.toString();
            _yearToDateTotal = '₱${_formatAmount(ytdTotal)}';
            _programsSupported = programsCount.toString();
            _beneficiariesSupported = beneficiariesCount.toString();
            _activeSubscriptions = activeSubs.toString();
            _nextBillingInfo = nextBillingStr;
            _firstDonationDate = firstDateStr;
            _currentStreak = streak;
            _milestones = milestones;
            _supportedBeneficiaryNames = beneficiaryNames;
            _recentDonations = recentDonations;
            _givingByProgram = givingByProgram;
            _isLoading = false;
          });
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching dashboard: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  String _monthAbbr(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  static const _metricTotalDonated = _MetricStyle(
    iconBg: Color(0xFFDCFCE7),
    iconColor: Color(0xFF16A34A),
    icon: Icons.account_balance_wallet,
  );
  static const _metricTotal = _MetricStyle(
    iconBg: Color(0xFFFFF9DB),
    iconColor: Color(0xFFC68A00),
    icon: Icons.receipt_long,
  );
  static const _metricYtd = _MetricStyle(
    iconBg: Color(0xFFE0F2FE),
    iconColor: Color(0xFF0284C7),
    icon: Icons.calendar_view_month_rounded,
  );
  static const _metricPrograms = _MetricStyle(
    iconBg: Color(0xFFDBEAFE),
    iconColor: Color(0xFF2563EB),
    icon: Icons.house_rounded,
  );
  static const _metricBeneficiaries = _MetricStyle(
    iconBg: Color(0xFFFFF0E6),
    iconColor: AppColors.orangeAccent,
    icon: Icons.people_rounded,
  );
  static const _metricSubscriptions = _MetricStyle(
    iconBg: Color(0xFFF3E8FF),
    iconColor: Color(0xFF9333EA),
    icon: Icons.autorenew_rounded,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [NotificationBell(user: widget.user, role: 'donor')],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _fetchDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 12),
                    _buildDonateButton(),

                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      Icons.analytics_rounded,
                      'Donor Metrics',
                    ),
                    const SizedBox(height: 10),
                    _buildMetricsGrid(),

                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      Icons.emoji_events_rounded,
                      'Impact & Streak',
                    ),
                    const SizedBox(height: 10),
                    _buildImpactStreakSection(),

                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      Icons.handshake_rounded,
                      'Giving by Program',
                    ),
                    const SizedBox(height: 10),
                    _buildGivingByProgramSection(),

                    if (_supportedBeneficiaryNames.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        Icons.people_rounded,
                        'Beneficiaries Supported',
                      ),
                      const SizedBox(height: 10),
                      _buildBeneficiariesSection(),
                    ],

                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      Icons.history_rounded,
                      'Recent Donations',
                    ),
                    const SizedBox(height: 10),
                    _buildRecentDonationsList(),
                  ],
                ),
              ),
            ),
    );
  }

  // welcome card
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withAlpha(45),
              border: Border.all(
                color: AppColors.tertiary.withAlpha(80),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: AppColors.tertiary,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonateButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DonateScreen(user: widget.user),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.tertiary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: Colors.black87,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Make a Donation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Support a program today',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_circle, color: Colors.black38, size: 25),
          ],
        ),
      ),
    );
  }

  static const _programColors = [
    Color(0xFF007A53),
    Color(0xFF1D3F8A),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
    Color(0xFF0891B2),
    Color(0xFFBE185D),
    Color(0xFF65A30D),
  ];

  Widget _buildGivingByProgramSection() {
    final programs = _givingByProgram;

    if (programs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECF5)),
        ),
        child: const Center(
          child: Text(
            'No program data yet',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Column(
        children: programs
            .asMap()
            .entries
            .map(
              (e) => _buildProgramRow(
                e.value['name'] as String,
                e.value['amount'] as String,
                (e.value['progress'] as num).toDouble(),
                _programColors[e.key % _programColors.length],
                isLast: e.key == programs.length - 1,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildProgramRow(
    String name,
    String amount,
    double progress,
    Color barColor, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A6A85),
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface.withAlpha(25), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.surface),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: AppFonts.roboto,
              color: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Donated',
                _totalDonated,
                _metricTotalDonated,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Donations Made',
                _totalDonations,
                _metricTotal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Year-to-Date',
                _yearToDateTotal,
                _metricYtd,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Programs Supported',
                _programsSupported,
                _metricPrograms,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Beneficiaries Supported',
                _beneficiariesSupported,
                _metricBeneficiaries,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSubscriptionsCard(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubscriptionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _metricSubscriptions.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _metricSubscriptions.icon,
              size: 18,
              color: _metricSubscriptions.iconColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _activeSubscriptions,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.surface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Active Subscriptions',
            style: const TextStyle(fontSize: 12, color: AppColors.grayText),
          ),
          if (_nextBillingInfo.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Next: $_nextBillingInfo',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.grayText.withAlpha(180),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, _MetricStyle style) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: style.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(style.icon, size: 18, color: style.iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.surface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.grayText),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStreakSection() {
    final hasFirstDonation = _firstDonationDate.isNotEmpty;
    final hasStreak = _currentStreak > 0;
    final hasMilestones = _milestones.isNotEmpty;

    if (!hasFirstDonation && !hasStreak && !hasMilestones) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECF5)),
        ),
        child: const Center(
          child: Text(
            'Start donating to build your impact!',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasFirstDonation) ...[
            _buildImpactRow(Icons.timer_outlined, 'First Donation',
                _firstDonationDate),
            const SizedBox(height: 14),
          ],
          if (hasStreak) ...[
            _buildImpactRow(Icons.local_fire_department_rounded,
                'Giving Streak', '$_currentStreak month${_currentStreak > 1 ? 's' : ''}'),
            const SizedBox(height: 14),
          ],
          if (hasMilestones) ...[
            const Text(
              'Milestones',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.grayText,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _milestones.map((m) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFE08A),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          size: 14, color: Color(0xFFB8860B)),
                      const SizedBox(width: 6),
                      Text(
                        m,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B6914),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImpactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1A56DB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grayText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBeneficiariesSection() {
    const int maxDisplay = 12;
    final displayNames = _supportedBeneficiaryNames.take(maxDisplay).toList();
    final overflow = _supportedBeneficiaryNames.length - maxDisplay;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...displayNames.map((name) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.tertiary.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5A6A85),
                  ),
                ),
              )),
          if (overflow > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECF5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+$overflow more',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grayText,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // no recent donations
  Widget _buildRecentDonationsList() {
    if (_recentDonations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECF5)),
        ),
        child: const Column(
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Color(0xFFCBD5E0)),
            SizedBox(height: 8),
            Text(
              'No recent donations yet',
              style: TextStyle(color: AppColors.grayText, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recentDonations
          .map((d) => _buildRecentDonationCard(d))
          .toList(),
    );
  }

  Widget _buildRecentDonationCard(Map<String, dynamic> donation) {
    final status = (donation['status'] as String).toLowerCase();
    final isCompleted = status == 'completed';

    final Color statusBg = isCompleted
        ? AppColors.tertiaryContainer
        : const Color(0xFFFFF9DB);
    final Color statusText = isCompleted
        ? AppColors.onTertiaryContainer
        : const Color(0xFF92400E);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: AppColors.orangeAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation['name'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: AppColors.grayText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      donation['date'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grayText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusText,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                donation['amount'] as String? ?? '---',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grayText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.grayText),
          const SizedBox(height: 16),
          const Text(
            'Failed to load dashboard',
            style: TextStyle(color: AppColors.grayText, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchDashboard,
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
}

class _MetricStyle {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;

  const _MetricStyle({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
  });
}
