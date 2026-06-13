import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String checkoutId;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.checkoutId,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isCompleted = false;
  bool _isClosing = false;
  Timer? _pollTimer;

  static const _successStatuses = ['completed', 'paid', 'success', 'settled'];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() => _isLoading = true);
            _handleUrl(url);
          },
          onPageFinished: (url) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            _handleUrl(url);
          },
          onNavigationRequest: (request) {
            if (_handleUrl(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            _hasError = true;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));

    _startPolling();
  }

  bool _handleUrl(String url) {
    if (_isCompleted) return true;

    if (url.startsWith('fairall://payment/success')) {
      _handleDone('success');
      return true;
    } else if (url.startsWith('fairall://payment/cancel')) {
      _handleDone('cancel');
      return true;
    }
    return false;
  }

  void _handleDone(String result) {
    _isCompleted = true;
    _pollTimer?.cancel();
    if (mounted) {
      Navigator.pop(context, result);
    }
  }

  Future<void> _checkStatusAndClose() async {
    if (_isCompleted || _isClosing) return;
    setState(() => _isClosing = true);

    try {
      final response =
          await ApiService.get('/donor/checkout/${widget.checkoutId}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final status = data['data']['status'].toString().toLowerCase();
          if (_successStatuses.contains(status)) {
            _handleDone('success');
            return;
          }
          if (status == 'cancelled' || status == 'expired') {
            _handleDone('cancel');
            return;
          }
        }
      }
    } catch (_) {}

    _isCompleted = true;
    _pollTimer?.cancel();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _startPolling() {
    int attempts = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isCompleted || !mounted) {
        timer.cancel();
        return;
      }

      attempts++;
      if (attempts > 60) {
        timer.cancel();
        return;
      }

      try {
        final response =
            await ApiService.get('/donor/checkout/${widget.checkoutId}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final status = data['data']['status'].toString().toLowerCase();
            if (_successStatuses.contains(status)) {
              _handleDone('success');
            } else if (status == 'cancelled' || status == 'expired') {
              _handleDone('cancel');
            }
          }
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Secure Payment'),
            backgroundColor: AppColors.surface,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _checkStatusAndClose,
            ),
          ),
          body: _hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.grayText),
                      const SizedBox(height: 16),
                      const Text('Failed to load payment page',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        'The payment page could not be loaded.\nPlease try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withAlpha(180)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _isLoading = true;
                          });
                          _controller.loadRequest(Uri.parse(widget.paymentUrl));
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tertiary,
                          foregroundColor: AppColors.surface,
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          color: AppColors.tertiary,
                        ),
                      ),
                  ],
                ),
        ),
        if (_isClosing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
