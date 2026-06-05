import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Checkout polling
  String? _currentCheckoutId;
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
    _fetchSubscriptionPlans();
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
      print('Programs Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Programs Response Body: ${response.body}');

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
          print('Loaded ${_programs.length} programs');
        } else {
          final message = data['message'] ?? 'Unknown error';
          print('Programs error: $message');
          setState(() {
            _hasProgramsError = true;
            _isLoadingPrograms = false;
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        print('Programs HTTP ${response.statusCode}: ${errorData['message'] ?? response.body}');
        setState(() {
          _hasProgramsError = true;
          _isLoadingPrograms = false;
        });
      }
    } catch (e) {
      print('Error fetching programs: $e');
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
      print('Subscription Plans Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Subscription Plans Response Body: ${response.body}');

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
          print('Loaded ${_subscriptionPlans.length} subscription plans');
        } else {
          final message = data['message'] ?? 'Unknown error';
          print('Subscription plans error: $message');
          setState(() {
            _hasPlansError = true;
            _isLoadingPlans = false;
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        print('Subscription plans HTTP ${response.statusCode}: ${errorData['message'] ?? response.body}');
        setState(() {
          _hasPlansError = true;
          _isLoadingPlans = false;
        });
      }
    } catch (e) {
      print('Error fetching subscription plans: $e');
      setState(() {
        _hasPlansError = true;
        _isLoadingPlans = false;
      });
    }
  }

  Future<void> _handleOneTimeDonation() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('Please enter a valid amount', Colors.red);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Build data map with proper null handling
      final Map<String, dynamic> data = {
        'donation_frequency': 'one_time',
        'gateway': _paymentGateway,
        'amount': amount,
        'currency': 'PHP',
      };

      // Only add program_id if it's not empty
      if (_selectedProgramId.isNotEmpty && _selectedProgramId != '') {
        data['program_id'] = int.parse(_selectedProgramId);
      }

      // Only add description if it's not empty
      if (_messageController.text.trim().isNotEmpty) {
        data['description'] = _messageController.text.trim();
      }

      final response = await ApiService.post('/donor/checkout', data);
      print('Checkout Response: ${response.statusCode}');
      print('Checkout Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final checkoutData = responseData['data'];
          final approveUrl = checkoutData['approve_url'];
          final checkoutId = checkoutData['checkout_id'];

          _currentCheckoutId = checkoutId.toString();

          // Open the payment URL in browser
          if (await canLaunchUrl(Uri.parse(approveUrl))) {
            await launchUrl(
              Uri.parse(approveUrl),
              mode: LaunchMode.externalApplication,
            );
          } else {
            print('❌ Cannot launch URL: $approveUrl');
            _showSnackBar('Cannot open payment page', Colors.red);
            setState(() { _isSubmitting = false; });
            return;
          }

          // Start polling for payment status
          _startPolling();
        } else {
          _showSnackBar(responseData['message'] ?? 'Failed to process donation', Colors.red);
          setState(() {
            _isSubmitting = false;
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackBar(errorData['message'] ?? 'Failed to process donation', Colors.red);
        setState(() {
          _isSubmitting = false;
        });
      }
    } catch (e) {
      print('Error processing donation: $e');
      _showSnackBar('An error occurred. Please try again.', Colors.red);
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _handleSubscriptionDonation(Map<String, dynamic> plan) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final data = {
        'donation_frequency': 'subscription',
        'subscription_plan': plan['key'],
        'program_id': plan['program_name'] == 'Education' ? _getProgramIdByName(plan['program_name']) : null,
        'description': _messageController.text.isEmpty ? null : _messageController.text,
      };

      final response = await ApiService.post('/donor/checkout', data);
      print('Subscription Checkout Response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final checkoutData = responseData['data'];
          final approveUrl = checkoutData['approve_url'];
          final checkoutId = checkoutData['checkout_id'];

          _currentCheckoutId = checkoutId;

          // Open the payment URL in browser
          if (await canLaunchUrl(Uri.parse(approveUrl))) {
            await launchUrl(
              Uri.parse(approveUrl),
              mode: LaunchMode.externalApplication,
            );

            // Start polling for payment status
            _startPolling();
          } else {
            _showSnackBar('Cannot open payment page', Colors.red);
          }
        } else {
          _showSnackBar(responseData['message'] ?? 'Failed to process subscription', Colors.red);
          setState(() {
            _isSubmitting = false;
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackBar(errorData['message'] ?? 'Failed to process subscription', Colors.red);
        setState(() {
          _isSubmitting = false;
        });
      }
    } catch (e) {
      print('Error processing subscription: $e');
      _showSnackBar('An error occurred. Please try again.', Colors.red);
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _startPolling() async {
    if (_currentCheckoutId == null) return;

    setState(() {
      _isPolling = true;
    });

    // Show a dialog while polling
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3E),
        title: const Text(
          'Processing Payment',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Waiting for payment confirmation...',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(height: 8),
            Text(
              'If payment was completed, please wait a moment.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() { _isPolling = false; _isSubmitting = false; });
            },
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );

    // Poll every 3 seconds for up to 5 minutes
    int attempts = 0;
    const maxAttempts = 100; // 5 minutes

    while (attempts < maxAttempts && _isPolling) {
      await Future.delayed(const Duration(seconds: 3));

      try {
        final response = await ApiService.get('/donor/checkout/$_currentCheckoutId');
        print('Polling attempt $attempts: status ${response.statusCode}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('Polling body: ${response.body}');
          if (data['success'] == true) {
            final status = data['data']['status'];
            print('Polling checkout status: $status');

            if (status == 'completed') {
              // Payment completed successfully
              if (mounted) {
                Navigator.pop(context); // Close dialog
                _showSnackBar('Payment successful! Thank you for your donation.', Colors.green);
                setState(() {
                  _isPolling = false;
                  _isSubmitting = false;
                });
              }
              break;
            } else if (status == 'cancelled' || status == 'expired') {
              // Payment failed or cancelled
              if (mounted) {
                Navigator.pop(context);
                _showSnackBar('Payment was not completed. Please try again.', Colors.orange);
                setState(() {
                  _isPolling = false;
                  _isSubmitting = false;
                });
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
      _showSnackBar('Payment confirmation timeout. Please check your donation history.', Colors.orange);
      setState(() {
        _isPolling = false;
        _isSubmitting = false;
      });
    }
  }

  String? _getProgramIdByName(String name) {
    final program = _programs.firstWhere(
          (p) => p['name'] == name,
      orElse: () => null,
    );
    return program != null ? program['id'].toString() : null;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Donate',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUPPORT FAIRALL',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: Colors.blue.shade300,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Make a Donation',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 60,
          height: 3,
          color: const Color(0xFFFFD700),
        ),
        const SizedBox(height: 12),
        const Text(
          'Choose a program and complete checkout through a secure donation provider. Grants are handled separately by staff.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF9CA3AF),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            title: 'ONE-TIME DONATION',
            description: 'Pay via Xendit or PayPal for a single contribution.',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            title: 'PAYPAL SUBSCRIPTION',
            description: 'Set up recurring support through PayPal billing.',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2D3255),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFD1D5DB),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2D3255),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Signed in as ${widget.user.displayName}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your donation will be linked to your donor profile.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
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
        color: const Color(0xFF13183A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2D3255),
          width: 1,
        ),
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
        const Text(
          'Donation Frequency',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD1D5DB),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRadioCard(
                title: 'One-time',
                subtitle: 'Xendit or PayPal checkout',
                value: 'one_time',
                groupValue: _donationFrequency,
                onChanged: (value) {
                  setState(() {
                    _donationFrequency = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRadioCard(
                title: 'Subscription',
                subtitle: 'PayPal recurring support',
                value: 'subscription',
                groupValue: _donationFrequency,
                onChanged: (value) {
                  setState(() {
                    _donationFrequency = value!;
                  });
                },
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
          color: const Color(0xFF1A1F3E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF2D3255),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF6B7280),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFD700),
                  ),
                ),
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
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

  Widget _buildSubscriptionContent() {
    if (_isLoadingPlans) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading subscription plans...',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasPlansError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFF9CA3AF)),
              const SizedBox(height: 16),
              const Text(
                'Failed to load subscription plans',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchSubscriptionPlans,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_subscriptionPlans.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'No subscription plans available at this time.',
            style: TextStyle(color: Color(0xFF9CA3AF)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        const Text(
          'Choose your subscription plan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: _subscriptionPlans.length,
          itemBuilder: (context, index) {
            final plan = _subscriptionPlans[index];
            return _buildSubscriptionCard(plan);
          },
        ),
        const SizedBox(height: 24),
        _buildInfoFooter(),
      ],
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> plan) {
    final programName = plan['program_name'] ?? 'No Program';
    final amount = double.parse(plan['amount'].toString());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2D3255),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan['name'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                plan['description'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  height: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRICE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₱${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '/month',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Program: $programName',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _handleSubscriptionDonation(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
                  : const Text(
                'Subscribe',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentGatewaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Gateway',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD1D5DB),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRadioCard(
                title: 'Xendit',
                subtitle: 'Cards / Bank transfer / E-wallet',
                value: 'xendit',
                groupValue: _paymentGateway,
                onChanged: (value) {
                  setState(() {
                    _paymentGateway = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRadioCard(
                title: 'PayPal',
                subtitle: 'Card or PayPal balance',
                value: 'paypal',
                groupValue: _paymentGateway,
                onChanged: (value) {
                  setState(() {
                    _paymentGateway = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgramDropdown() {
    if (_isLoadingPrograms) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Program',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD1D5DB),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading programs...'),
              ],
            ),
          ),
        ],
      );
    }

    if (_hasProgramsError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Program',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD1D5DB),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF1A1F3E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Failed to load programs',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
                TextButton(
                  onPressed: _fetchPrograms,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Program',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD1D5DB),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProgramId.isEmpty ? null : _selectedProgramId,
              hint: const Text(
                'No Program',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('No Program'),
                ),
                ..._programs.map((program) {
                  return DropdownMenuItem<String>(
                    value: program['id'].toString(),
                    child: Text(
                      program['name'],
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 14,
                      ),
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedProgramId = value ?? '';
                  final selected = _programs.firstWhere(
                        (p) => p['id'].toString() == value,
                    orElse: () => null,
                  );
                  _selectedProgramName = selected != null ? selected['name'] : 'No Program';
                });
              },
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
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
        const Text(
          'Amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD1D5DB),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
          decoration: InputDecoration(
            prefixText: '₱ ',
            prefixStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Message / Purpose (optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD1D5DB),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 3,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
          decoration: InputDecoration(
            hintText: 'Tell us how you\'d like this donation used.',
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
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
    final amount = _amountController.text.isEmpty ? '0.00' : _amountController.text;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (_isSubmitting || _isPolling) ? null : _handleOneTimeDonation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: (_isSubmitting || _isPolling)
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.black,
          ),
        )
            : Text(
          'Continue to Donation',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}