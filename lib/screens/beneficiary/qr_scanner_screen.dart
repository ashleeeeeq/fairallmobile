import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'package:fairallmobile/config/app_config.dart';
import 'package:fairallmobile/screens/login_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final int beneficiaryId;

  const QRScannerScreen({super.key, required this.beneficiaryId});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _startCamera();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _startCamera() async {
    await _scannerController.start();
  }

  void _checkAuthentication() async {
    final token = await ApiService.getToken();
    final prefs = await SharedPreferences.getInstance();
    final sharedToken = prefs.getString(AppConfig.tokenKey);

    print('🔑 TOKEN IN QR SCANNER: $token');

    if (token == null || token.isEmpty) {
      print('❌ NO TOKEN FOUND!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please login again.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    }
  }

  Future<void> _handleQRCode(String qrCode) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      print('🔍 Scanning QR Code: $qrCode');
      print('📍 Beneficiary ID: ${widget.beneficiaryId}');

      // Try event first (anyone can attend)
      var response = await ApiService.post('/attendance/event/log', {
        'qr_code': qrCode,
        'beneficiary_id': widget.beneficiaryId,
      });

      print('📡 Event response status: ${response.statusCode}');

      // If event fails (404), try activity session
      if (response.statusCode == 404) {
        print('📌 Not an event, trying activity session...');
        response = await ApiService.post('/attendance/activity-session/log', {
          'qr_code': qrCode,
          'beneficiary_id': widget.beneficiaryId,
        });
        print('📡 Activity session response status: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showResult(true, data['message'] ?? 'Attendance recorded successfully!');
      } else {
        _showResult(false, data['message'] ?? 'Failed to record attendance');
      }
    } catch (e) {
      print('❌ Error: $e');
      _showResult(false, 'Connection error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showResult(bool success, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(
          success ? Icons.check_circle : Icons.error,
          color: success ? Colors.green : Colors.red,
          size: 50,
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (success) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: AppColors.surface,
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null && !_isProcessing) {
                    _handleQRCode(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  size: 50,
                  color: AppColors.surface,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Position the QR code within the frame',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        _scannerController.toggleTorch();
                      },
                      icon: const Icon(Icons.flash_on),
                      tooltip: 'Toggle Torch',
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      onPressed: () {
                        _scannerController.switchCamera();
                      },
                      icon: const Icon(Icons.cameraswitch),
                      tooltip: 'Switch Camera',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}