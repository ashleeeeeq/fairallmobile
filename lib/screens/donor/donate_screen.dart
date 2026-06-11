import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/screens/donor/donation_history_screen.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fairallmobile/widgets/notification_bell.dart';

class DonateScreen extends StatefulWidget {
  final User user;

  const DonateScreen({super.key, required this.user});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  String _donationFrequency = 'one_time';
  String _paymentGateway = 'xendit';
  String _selectedProgramId = '';
  String _selectedProgramName = 'No Program';
  final TextEditingController _amountController = TextEditingController(text: '50.00');
  final TextEditingController _messageController = TextEditingController();

  List<dynamic> _programs = [];
  List<dynamic> _subscriptionPlans = [];
  bool _isLoadingPrograms = true;
  bool _isLoadingPlans = true;
  bool _hasProgramsError = false;
  bool _hasPlansError = false;
  bool _isSubmitting = false;

  bool _hasActiveSubscription = false;
  bool _isCheckingSubscription = true;

  String? _currentCheckoutId;
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
    _fetchSubscriptionPlans();
    _checkActiveSubscription();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrograms() async {
    setState(() {
      _isLoadingPrograms = true;
      _hasProgramsError = false;
    });

    try {
      final response = await ApiService.get('/donor/programs');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bodyData = data['data'];
        if (data['success'] == true && bodyData != null) {
          setState(() {
            if (bodyData is List) {
              _programs = bodyData;
            } else if (bodyData is Map && bodyData.containsKey('programs')) {
              _programs = bodyData['programs'] as List<dynamic>? ?? [];
            } else {
              _hasProgramsError = true;
            }
            _isLoadingPrograms = false;
          });
        } else {
          setState(() {
            _hasProgramsError = true;
            _isLoadingPrograms = false;
          });
        }
      } else {
        setState(() {
          _hasProgramsError = true;
          _isLoadingPrograms = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasProgramsError = true;
        _isLoadingPrograms = false;
      });
    }
  }

  Future<void> _fetchSubscriptionPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _hasPlansError = false;
    });

    try {
      final response = await ApiService.get('/donor/subscription-plans');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bodyData = data['data'];
        if (data['success'] == true && bodyData != null) {
          setState(() {
            if (bodyData is List) {
              _subscriptionPlans = bodyData;
            } else if (bodyData is Map && bodyData.containsKey('plans')) {
              _subscriptionPlans = bodyData['plans'] as List<dynamic>? ?? [];
            } else {
              _hasPlansError = true;
            }
            _isLoadingPlans = false;
          });
        } else {
          setState(() {
            _hasPlansError = true;
            _isLoadingPlans = false;
          });
        }
      } else {
        setState(() {
          _hasPlansError = true;
          _isLoadingPlans = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasPlansError = true;
        _isLoadingPlans = false;
      });
    }
  }

  Future<void> _checkActiveSubscription() async {
    try {
      final response = await ApiService.get('/donor/subscriptions?per_page=50');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final subscriptions = data['data']['subscriptions'] as List<dynamic>? ?? [];
          _hasActiveSubscription = subscriptions.any((s) => s['status'] == 'active');
        }
      }
    } catch (e) {
      print('Error checking active subscription: $e');
    } finally {
      setState(() { _isCheckingSubscription = false; });
    }
  }

  Future<void> _handleOneTimeDonation() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('Please enter a valid amount', AppColors.error);
      return;
    }

    setState(() { _isSubmitting = true; });

    try {
      final Map<String, dynamic> data = {
        'donation_frequency': 'one_time',
        'gateway': _paymentGateway,
        'amount': amount,
        'currency': 'PHP',
      };

      if (_selectedProgramId.isNotEmpty) {
        data['program_id'] = int.parse(_selectedProgramId);
      }

      if (_messageController.text.trim().isNotEmpty) {
        data['description'] = _messageController.text.trim();
      }

      final response = await ApiService.post('/donor/checkout', data);
      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final checkoutData = responseData['data'];
          final approveUrl = checkoutData['approve_url'];
          _currentCheckoutId = checkoutData['checkout_id'].toString();

          if (await canLaunchUrl(Uri.parse(approveUrl))) {
            await launchUrl(Uri.parse(approveUrl), mode: LaunchMode.externalApplication);
          } else {
            _showSnackBar('Cannot open payment page', AppColors.error);
            setState(() { _isSubmitting = false; });
            return;
          }
          _startPolling();
        } else {
          _showSnackBar(responseData['message'] ?? 'Failed to process donation', AppColors.error);
          setState(() { _isSubmitting = false; });
        }
      } else {
        setState(() { _isSubmitting = false; });
        _showSnackBar('Failed to process donation', AppColors.error);
      }
    } catch (e) {
      _showSnackBar('An error occurred. Please try again.', AppColors.error);
      setState(() { _isSubmitting = false; });
    }
  }

  Future<void> _handleSubscriptionDonation(Map<String, dynamic> plan) async {
    setState(() { _isSubmitting = true; });

    try {
      final data = {
        'donation_frequency': 'subscription',
        'subscription_plan': plan['key'],
        'program_id': plan['program_name'] == 'Education' ? _getProgramIdByName(plan['program_name']) : null,
        'description': _messageController.text.isEmpty ? null : _messageController.text,
      };

      final response = await ApiService.post('/donor/checkout', data);
      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final checkoutData = responseData['data'];
          final approveUrl = checkoutData['approve_url'];
          _currentCheckoutId = checkoutData['checkout_id'].toString();

          if (await canLaunchUrl(Uri.parse(approveUrl))) {
            await launchUrl(Uri.parse(approveUrl), mode: LaunchMode.externalApplication);
            _startPolling();
          } else {
            _showSnackBar('Cannot open payment page', AppColors.error);
          }
        } else {
          _showSnackBar(responseData['message'] ?? 'Failed to process subscription', AppColors.error);
          setState(() { _isSubmitting = false; });
        }
      } else {
        _showSnackBar('Failed to process subscription', AppColors.error);
        setState(() { _isSubmitting = false; });
      }
    } catch (e) {
      _showSnackBar('An error occurred. Please try again.', AppColors.error);
      setState(() { _isSubmitting = false; });
    }
  }

  Future<void> _startPolling() async {
    if (_currentCheckoutId == null) return;

    setState(() { _isPolling = true; });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Processing Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tertiary)),
            const SizedBox(height: 20),
            const Text('Waiting for payment confirmation...', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Please don\'t close the app.', style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() { _isPolling = false; _isSubmitting = false; });
            },
            child: const Text('Cancel', style: TextStyle(color: AppColors.grayText)),
          ),
        ],
      ),
    );

    int attempts = 0;
    const maxAttempts = 60;

    while (attempts < maxAttempts && _isPolling) {
      await Future.delayed(const Duration(seconds: 3));

      try {
        final response = await ApiService.get('/donor/checkout/$_currentCheckoutId');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final status = data['data']['status'];

            if (['completed', 'paid', 'success', 'settled'].contains(status.toLowerCase())) {
              if (mounted) {
                Navigator.pop(context);
                _showSnackBar('Payment successful! Thank you for your donation.', AppColors.onTertiaryContainer);
                setState(() { _isPolling = false; _isSubmitting = false; });
              }
              break;
            } else if (status == 'cancelled' || status == 'expired') {
              if (mounted) {
                Navigator.pop(context);
                _showSnackBar('Payment was not completed.', AppColors.orangeAccent);
                setState(() { _isPolling = false; _isSubmitting = false; });
              }
              break;
            }
          }
        }
      } catch (e) {
        print('Polling error: $e');
      }
      attempts++;
    }

    if (attempts >= maxAttempts && mounted) {
      Navigator.pop(context);
      _showSnackBar('Confirmation timeout. Please verify donation logs.', AppColors.orangeAccent);
      setState(() { _isPolling = false; _isSubmitting = false; });
    }
  }

  String? _getProgramIdByName(String name) {
    final program = _programs.firstWhere((p) => p['name'] == name, orElse: () => null);
    return program != null ? program['id'].toString() : null;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontWeight: FontWeight.w600, color: color == AppColors.tertiaryContainer || color == AppColors.lightredbg ? AppColors.surface : Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Donate', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          NotificationBell(user: widget.user, role: 'donor'),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildInfoCards(),
            const SizedBox(height: 16),
            _buildUserStatusBanner(),
            const SizedBox(height: 24),
            _buildFormContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
              size: 24,
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Choose a program and complete checkout through a secure donation provider. Grants are handled separately by staff.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            title: 'ONE-TIME',
            description: 'Support instantly via credit cards or e-wallets.',
            icon: Icons.bolt_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            title: 'SUBSCRIPTION',
            description: 'Provide sustainable care with reliable regular support.',
            icon: Icons.autorenew_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required String description, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface.withAlpha(35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.tertiary, size: 20),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.white)),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(fontSize: 12, color: AppColors.grayText, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildUserStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(40),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_circle_rounded, color: AppColors.grayText, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Signed in as ${widget.user.displayName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.surface)),
                const SizedBox(height: 2),
                const Text('Linked securely to your dynamic dashboard logs.', style: TextStyle(fontSize: 12, color: AppColors.grayText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContainer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFrequencySection(),
          const SizedBox(height: 24),
          _donationFrequency == 'one_time' ? _buildOneTimeContent() : _buildSubscriptionContent(),
        ],
      ),
    );
  }

  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Donation Frequency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRadioCard(
                title: 'One-time',
                subtitle: 'Single Checkout',
                value: 'one_time',
                groupValue: _donationFrequency,
                onChanged: (value) => setState(() => _donationFrequency = value!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRadioCard(
                title: 'Subscription',
                subtitle: 'Monthly Plan',
                value: 'subscription',
                groupValue: _donationFrequency,
                onChanged: (value) => setState(() => _donationFrequency = value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioCard({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    final isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF252B54) : const Color(0xFF131732),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.tertiary : Colors.transparent,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? AppColors.tertiary : AppColors.grayText, width: 2),
              ),
              child: isSelected
                  ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.tertiary)))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOneTimeContent() {
    return Column(
      children: [
        _buildPaymentGatewaySection(),
        const SizedBox(height: 24),
        _buildProgramDropdown(),
        const SizedBox(height: 20),
        _buildAmountInput(),
        const SizedBox(height: 20),
        _buildMessageInput(),
        const SizedBox(height: 24),
        _buildInfoFooter(),
        const SizedBox(height: 24),
        _buildDonateButton(),
      ],
    );
  }

  Widget _buildPaymentGatewaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Gateway', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRadioCard(
                title: 'Xendit',
                subtitle: 'Cards & E-Wallets',
                value: 'xendit',
                groupValue: _paymentGateway,
                onChanged: (value) => setState(() => _paymentGateway = value!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRadioCard(
                title: 'PayPal',
                subtitle: 'Global Safe Wallet',
                value: 'paypal',
                groupValue: _paymentGateway,
                onChanged: (value) => setState(() => _paymentGateway = value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgramDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Program', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        _isLoadingPrograms
            ? const LinearProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tertiary))
            : Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF131732),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: AppColors.surface,
              isExpanded: true,
              value: _selectedProgramId.isEmpty ? null : _selectedProgramId,
              hint: const Text('General Donation (No Specific Program)', style: TextStyle(color: AppColors.grayText, fontSize: 14)),
              items: [
                const DropdownMenuItem<String>(value: '', child: Text('General Donation (No Specific Program)', style: TextStyle(color: Colors.white, fontSize: 14))),
                ..._programs.map((program) {
                  return DropdownMenuItem<String>(
                    value: program['id'].toString(),
                    child: Text(program['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedProgramId = val ?? '';
                  final currentProg = _programs.firstWhere((p) => p['id'].toString() == val, orElse: () => null);
                  _selectedProgramName = currentProg != null ? currentProg['name'] : 'No Program';
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Amount (PHP)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          decoration: InputDecoration(
            prefixText: '₱ ',
            prefixStyle: const TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.bold, fontSize: 16),
            filled: true,
            fillColor: const Color(0xFF131732),
            hintText: '0.00',
            hintStyle: TextStyle(color: Colors.white.withAlpha(100)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.tertiary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Message / Purpose (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        TextField(
          controller: _messageController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF131732),
            hintText: 'Tell us how you would like this donations used...',
            hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 13),
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.tertiary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What happens next?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You\'ll be redirected to the provider to complete checkout. We\'ll generate a receipt after the donation clears.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleOneTimeDonation,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tertiary,
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface)))
            : const Text('Continue to Donation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSubscriptionContent() {
    if (_isLoadingPlans) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tertiary)),
        ),
      );
    }

    if (_hasPlansError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.grayText),
              const SizedBox(height: 16),
              const Text('Failed to load subscription plans', style: TextStyle(color: AppColors.grayText)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchSubscriptionPlans,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.tertiary, foregroundColor: AppColors.surface),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_subscriptionPlans.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No subscription plans configuration online.', style: TextStyle(color: AppColors.grayText))));
    }

    if (_isCheckingSubscription) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tertiary))));
    }

    if (_hasActiveSubscription) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded, size: 54, color: Colors.green),
              const SizedBox(height: 16),
              const Text('Subscription Active', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              const Text('Only one rolling account tier configuration is permitted.', style: TextStyle(fontSize: 13, color: AppColors.grayText), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DonationHistoryScreen(user: widget.user))),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.tertiary, foregroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Manage Logs'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Plan tier', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _subscriptionPlans.length,
          itemBuilder: (context, index) => _buildSubscriptionCard(_subscriptionPlans[index]),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> plan) {
    final amount = double.parse(plan['amount'].toString());
    final description = plan['description'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131732),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(fontSize: 13, color: AppColors.grayText)),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₱${amount.toStringAsFixed(2)} / month',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.tertiary),
              ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _handleSubscriptionDonation(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tertiary,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Subscribe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}