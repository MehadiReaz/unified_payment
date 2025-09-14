import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/payment_response.dart';
import '../models/payment_config.dart';

/// Callback function types for payment events
typedef PaymentSuccessCallback = void Function(PaymentResponse response);
typedef PaymentFailureCallback = void Function(PaymentResponse response);
typedef PaymentCancelledCallback = void Function();

/// WebView widget for handling payment flows
class PaymentWebView extends StatefulWidget {
  /// The payment URL to load
  final String paymentUrl;

  /// Success callback URL pattern to detect successful payments
  final String? successUrlPattern;

  /// Cancel callback URL pattern to detect cancelled payments
  final String? cancelUrlPattern;

  /// Failure callback URL pattern to detect failed payments
  final String? failureUrlPattern;

  /// Payment provider for response parsing
  final PaymentProvider provider;

  /// Order ID for tracking
  final String? orderId;

  /// Success callback
  final PaymentSuccessCallback? onSuccess;

  /// Failure callback
  final PaymentFailureCallback? onFailure;

  /// Cancel callback
  final PaymentCancelledCallback? onCancelled;

  /// Timeout duration for the payment flow
  final Duration timeout;

  /// Custom loading widget
  final Widget? loadingWidget;

  /// Custom error widget builder
  final Widget Function(String error)? errorWidgetBuilder;

  const PaymentWebView({
    super.key,
    required this.paymentUrl,
    required this.provider,
    this.successUrlPattern,
    this.cancelUrlPattern,
    this.failureUrlPattern,
    this.orderId,
    this.onSuccess,
    this.onFailure,
    this.onCancelled,
    this.timeout = const Duration(minutes: 15),
    this.loadingWidget,
    this.errorWidgetBuilder,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress if needed
          },
          onPageStarted: (String url) {
            _handleUrlChange(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _handleUrlChange(url);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _error = 'WebView error: ${error.description}';
              _isLoading = false;
            });
            _handlePaymentFailure(
              'WebView error occurred',
              errorCode: error.errorCode.toString(),
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            _handleUrlChange(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer(widget.timeout, () {
      if (mounted) {
        _handlePaymentTimeout();
      }
    });
  }

  void _handleUrlChange(String url) {
    // Check for success URL pattern
    if (widget.successUrlPattern != null &&
        url.contains(widget.successUrlPattern!)) {
      _handlePaymentSuccess(url);
      return;
    }

    // Check for cancel URL pattern
    if (widget.cancelUrlPattern != null &&
        url.contains(widget.cancelUrlPattern!)) {
      _handlePaymentCancelled();
      return;
    }

    // Check for failure URL pattern
    if (widget.failureUrlPattern != null &&
        url.contains(widget.failureUrlPattern!)) {
      _handlePaymentFailure('Payment failed', url: url);
      return;
    }

    // Parse URL for common success/failure patterns
    _parseUrlForPaymentResult(url);
  }

  void _parseUrlForPaymentResult(String url) {
    final uri = Uri.parse(url);
    final queryParams = uri.queryParameters;

    // Common success indicators
    if (queryParams.containsKey('payment_intent') ||
        queryParams.containsKey('payment_id') ||
        queryParams.containsKey('transaction_id') ||
        queryParams.containsKey('razorpay_payment_id')) {
      String? transactionId = queryParams['payment_intent'] ??
          queryParams['payment_id'] ??
          queryParams['transaction_id'] ??
          queryParams['razorpay_payment_id'];

      if (transactionId != null) {
        _handlePaymentSuccess(url, transactionId: transactionId);
        return;
      }
    }

    // Common failure indicators
    if (queryParams.containsKey('error') ||
        queryParams.containsKey('error_code') ||
        url.contains('/cancel') ||
        url.contains('/failed')) {
      String? errorCode = queryParams['error'] ?? queryParams['error_code'];
      _handlePaymentFailure(
        'Payment failed or cancelled',
        errorCode: errorCode,
        url: url,
      );
      return;
    }

    // Stripe specific patterns
    if (url.contains('stripe.com') && url.contains('return_url')) {
      _handlePaymentSuccess(url);
      return;
    }

    // PayPal specific patterns
    if (url.contains('paypal.com') && url.contains('success')) {
      _handlePaymentSuccess(url);
      return;
    }
  }

  void _handlePaymentSuccess(String url, {String? transactionId}) {
    _timeoutTimer?.cancel();

    final response = PaymentResponse.success(
      transactionId: transactionId ?? _extractTransactionIdFromUrl(url),
      message: 'Payment completed successfully',
      orderId: widget.orderId,
      provider: widget.provider,
      rawResponse: {'url': url},
    );

    widget.onSuccess?.call(response);
  }

  void _handlePaymentFailure(String message, {String? errorCode, String? url}) {
    _timeoutTimer?.cancel();

    final response = PaymentResponse.failure(
      message: message,
      errorCode: errorCode,
      orderId: widget.orderId,
      provider: widget.provider,
      rawResponse: url != null ? {'url': url} : null,
    );

    widget.onFailure?.call(response);
  }

  void _handlePaymentCancelled() {
    _timeoutTimer?.cancel();

    final response = PaymentResponse.cancelled(
      message: 'Payment was cancelled by user',
      orderId: widget.orderId,
      provider: widget.provider,
    );

    widget.onFailure?.call(response);
    widget.onCancelled?.call();
  }

  void _handlePaymentTimeout() {
    _timeoutTimer?.cancel();

    final response = PaymentResponse.timeout(
      message: 'Payment timed out',
      orderId: widget.orderId,
      provider: widget.provider,
    );

    widget.onFailure?.call(response);
  }

  String _extractTransactionIdFromUrl(String url) {
    final uri = Uri.parse(url);
    final queryParams = uri.queryParameters;

    // Try common transaction ID parameter names
    return queryParams['payment_intent'] ??
        queryParams['payment_id'] ??
        queryParams['transaction_id'] ??
        queryParams['razorpay_payment_id'] ??
        queryParams['id'] ??
        'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _handlePaymentCancelled();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return widget.errorWidgetBuilder?.call(_error!) ??
          _buildDefaultErrorWidget(_error!);
    }

    if (_isLoading) {
      return widget.loadingWidget ?? _buildDefaultLoadingWidget();
    }

    return WebViewWidget(controller: _controller);
  }

  Widget _buildDefaultLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading payment page...'),
        ],
      ),
    );
  }

  Widget _buildDefaultErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Payment Error',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              error,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
