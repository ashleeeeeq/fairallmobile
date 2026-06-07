import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';

class DonorHomeScreen extends StatefulWidget {
  final User user;

  const DonorHomeScreen({super.key, required this.user});

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  String _lastDonationDate = '---';
  String _totalDonated = '---';
  String _averageDonation = '---';
  String _totalDonations = '---';

  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() { _isLoading = true; _hasError = false; });

    try {
      final response = await ApiService.get('/donor/dashboard');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final stats = data['data']['stats'];
          final recent = data['data']['recent_donations'] as List<dynamic>? ?? [];

          final totalDonated = (stats['total_donated'] ?? 0).toDouble();
          final totalCount = stats['total_donations'] ?? 0;

          if (recent.isNotEmpty) {
            final lastDate = recent[0]['transaction_date'] as String?;
            if (lastDate != null) {
              final dt = DateTime.parse(lastDate);
              _lastDonationDate = '${_monthAbbr(dt.month)} ${dt.day}, ${dt.year}';
            }
          }

          _totalDonated = '₱${_formatAmount(totalDonated)}';
          _averageDonation = totalCount > 0
              ? '₱${_formatAmount(totalDonated / totalCount)}'
              : '₱0.00';
          _totalDonations = totalCount.toString();
        }
      }
    } catch (e) {
      print('Error fetching dashboard: $e');
      _hasError = true;
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  String _monthAbbr(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E2A),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0A0E2A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _fetchDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Donation Metrics'),
                    const SizedBox(height: 12),
                    _buildMetricsGrid(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Donor Metrics',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: Colors.blue.shade300,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Key performance and activity metrics',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricCard('Last Donation', _lastDonationDate, Icons.calendar_today, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Total Donated', _totalDonated, Icons.account_balance_wallet, Colors.green)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Average Donation', _averageDonation, Icons.trending_up, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Total Donations', _totalDonations, Icons.receipt_long, AppColors.tertiary)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D3255)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
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
          const Icon(Icons.error_outline, size: 48, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 16),
          const Text(
            'Failed to load dashboard',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchDashboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
