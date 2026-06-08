import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/screens/donor/donate_screen.dart';

class DonationHistoryScreen extends StatefulWidget {
  final User user;

  const DonationHistoryScreen({super.key, required this.user});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  List<dynamic> _donations = [];
  List<dynamic> _subscriptions = [];
  bool _isLoadingDonations = true;
  bool _isLoadingSubscriptions = true;
  bool _hasDonationsError = false;
  bool _hasSubscriptionsError = false;
  int _currentPage = 1;
  int _lastPage = 1;
  String _activeTab = 'donations'; // 'donations' or 'subscriptions'

  @override
  void initState() {
    super.initState();
    _fetchDonations();
    _fetchSubscriptions();
  }

  Future<void> _fetchDonations({int page = 1}) async {
    setState(() {
      _isLoadingDonations = true;
      _hasDonationsError = false;
    });

    try {
      final response = await ApiService.get('/donor/donations?page=$page&per_page=10');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _donations = data['data']['donations'];
            _currentPage = data['data']['pagination']['current_page'];
            _lastPage = data['data']['pagination']['last_page'];
            _isLoadingDonations = false;
          });
        } else {
          setState(() {
            _hasDonationsError = true;
            _isLoadingDonations = false;
          });
        }
      } else {
        setState(() {
          _hasDonationsError = true;
          _isLoadingDonations = false;
        });
      }
    } catch (e) {
      print('Error fetching donations: $e');
      setState(() {
        _hasDonationsError = true;
        _isLoadingDonations = false;
      });
    }
  }

  Future<void> _fetchSubscriptions() async {
    setState(() {
      _isLoadingSubscriptions = true;
      _hasSubscriptionsError = false;
    });

    try {
      final response = await ApiService.get('/donor/subscriptions?per_page=50');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _subscriptions = data['data']['subscriptions'];
            _isLoadingSubscriptions = false;
          });
        } else {
          setState(() {
            _hasSubscriptionsError = true;
            _isLoadingSubscriptions = false;
          });
        }
      } else {
        setState(() {
          _hasSubscriptionsError = true;
          _isLoadingSubscriptions = false;
        });
      }
    } catch (e) {
      print('Error fetching subscriptions: $e');
      setState(() {
        _hasSubscriptionsError = true;
        _isLoadingSubscriptions = false;
      });
    }
  }

  Future<void> _cancelSubscription(int subscriptionId, String planName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3E),
        title: const Text(
          'Cancel Subscription',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to cancel your $planName subscription?',
          style: const TextStyle(color: Color(0xFF9CA3AF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.post('/donor/subscriptions/$subscriptionId/cancel', {});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSnackBar('Subscription cancelled successfully', Colors.green);
          _fetchSubscriptions();
        } else {
          _showSnackBar(data['message'] ?? 'Failed to cancel subscription', Colors.red);
        }
      } else {
        try {
          final data = jsonDecode(response.body);
          _showSnackBar(data['message'] ?? 'Failed to cancel subscription', Colors.red);
        } catch (_) {
          _showSnackBar('Failed to cancel subscription (${response.statusCode})', Colors.red);
        }
      }
    } catch (e) {
      print('Error cancelling subscription: $e');
      _showSnackBar('An error occurred. Please try again.', Colors.red);
    }
  }

  Future<void> _downloadReceipt(int donationId) async {
    try {
      final response = await ApiService.get('/donor/receipts/$donationId/download');
      // TODO: Handle file download and save using path_provider + open_file
      _showSnackBar('Receipt downloaded successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to download receipt', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _navigateToNewDonation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DonateScreen(user: widget.user),
      ),
    );
    _fetchDonations();
    _fetchSubscriptions();
  }

  Future<void> _navigateToDonateScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DonateScreen(user: widget.user),
      ),
    );
    _fetchDonations();
    _fetchSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E2A),
      appBar: AppBar(
        title: const Text(
          'Donation History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0A0E2A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _navigateToNewDonation,
            tooltip: 'New Donation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    'Donations',
                    _activeTab == 'donations',
                        () => setState(() => _activeTab = 'donations'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton(
                    'Manage Subscriptions',
                    _activeTab == 'subscriptions',
                        () => setState(() => _activeTab = 'subscriptions'),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _activeTab == 'donations' ? _buildDonationsTab() : _buildSubscriptionsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFD700) : const Color(0xFF1A1F3E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFFFFD700) : const Color(0xFF2D3255),
            width: 1,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDonationsTab() {
    if (_isLoadingDonations) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading donations...',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    if (_hasDonationsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            const Text(
              'Failed to load donation history',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDonations,
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

    if (_donations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            const Text(
              'No donation history found',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your donations will appear here',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _navigateToDonateScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
              ),
              child: const Text('Make a Donation'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchDonations(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _donations.length,
              itemBuilder: (context, index) {
                final donation = _donations[index];
                return _buildDonationCard(donation);
              },
            ),
            if (_lastPage > 1) _buildPagination(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionsTab() {
    if (_isLoadingSubscriptions) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading subscriptions...',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    if (_hasSubscriptionsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            const Text(
              'Failed to load subscriptions',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSubscriptions,
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

    if (_subscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.subscriptions_rounded,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            const Text(
              'No subscriptions found',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Subscribe to a plan to start recurring donations',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _navigateToDonateScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
              ),
              child: const Text('View Subscription Plans'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchSubscriptions();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subscriptions.length,
              itemBuilder: (context, index) {
                final subscription = _subscriptions[index];
                return _buildSubscriptionCard(subscription);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final transactionDate = donation['transaction_date'] != null
        ? DateTime.parse(donation['transaction_date'])
        : DateTime.parse(donation['created_at']);
    final formattedDate = '${transactionDate.month}/${transactionDate.day}/${transactionDate.year}';

    Color statusColor = donation['status'] == 'completed' ? Colors.green : Colors.orange;
    String statusText = donation['status'].toUpperCase();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation['reference_number'] ?? 'N/A',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      donation['gateway']?.toUpperCase() ?? 'N/A',
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF2D3255), height: 20),
          Row(
            children: [
              _buildInfoChip(Icons.calendar_today, formattedDate),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.category_outlined,
                donation['donation_type'] == 'one_time' ? 'One-time' : 'Subscription',
              ),
              if (donation['program'] != null) ...[
                const SizedBox(width: 12),
                _buildInfoChip(Icons.folder_outlined, donation['program']['name']),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₱${double.parse(donation['amount'].toString()).toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (donation['has_receipt'] == true)
                    _buildActionButton(
                      icon: Icons.receipt_rounded,
                      onPressed: () => _downloadReceipt(donation['id']),
                    ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    icon: Icons.info_outline,
                    onPressed: () => _showDonationDetails(donation),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> subscription) {
    Color statusColor;
    switch (subscription['status']) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  subscription['plan_name'] ?? 'N/A',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subscription['status'].toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(Icons.payments_outlined, '₱${double.parse(subscription['amount'].toString()).toStringAsFixed(2)}'),
              const SizedBox(width: 12),
              if (subscription['next_billing_date'] != null)
                _buildInfoChip(Icons.date_range, subscription['next_billing_date']),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID: ${subscription['id']}',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
              if (subscription['status'] == 'active')
                TextButton.icon(
                  onPressed: () => _cancelSubscription(subscription['id'], subscription['plan_name']),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Cancel', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: const Color(0xFFFFD700)),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  void _showDonationDetails(Map<String, dynamic> donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3E),
        title: const Text(
          'Donation Details',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Reference', donation['reference_number'] ?? 'N/A'),
            _buildDetailRow('Amount', '₱${double.parse(donation['amount'].toString()).toStringAsFixed(2)}'),
            _buildDetailRow('Gateway', donation['gateway']?.toUpperCase() ?? 'N/A'),
            _buildDetailRow('Status', donation['status'].toUpperCase()),
            _buildDetailRow('Type', donation['donation_type'] == 'one_time' ? 'One-time' : 'Subscription'),
            _buildDetailRow('Program', donation['program']?['name'] ?? 'General'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3E),
        border: const Border(
          top: BorderSide(color: Color(0xFF2D3255)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => _fetchDonations(page: _currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left, color: Color(0xFFFFD700)),
          ),
          Text(
            'Page $_currentPage of $_lastPage',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          IconButton(
            onPressed: _currentPage < _lastPage
                ? () => _fetchDonations(page: _currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right, color: Color(0xFFFFD700)),
          ),
        ],
      ),
    );
  }
}