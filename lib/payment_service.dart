import 'package:flutter/material.dart';
import 'models/payment_config.dart';
import 'models/payment_request.dart';
import 'models/payment_response.dart';
import 'providers/base_provider.dart';
import 'providers/stripe_provider.dart';
import 'providers/paypal_provider.dart';
import 'providers/razorpay_provider.dart';
import 'providers/paystack_provider.dart';
import 'widgets/payment_webview.dart';

/// Callback function types for payment events
typedef PaymentSuccessCallback = void Function(PaymentResponse response);
typedef PaymentFailureCallback = void Function(PaymentResponse response);

/// Main service class for unified payment processing
class PaymentService {
  static PaymentService? _instance;
  PaymentConfig? _config;
  BasePaymentProvider? _provider;

  /// Singleton instance
  static PaymentService get instance {
    _instance ??= PaymentService._internal();
    return _instance!;
  }

  PaymentService._internal();

  /// Factory constructor for easier access
  factory PaymentService() => instance;

  /// Initialize the payment service with configuration
  Future<void> init(PaymentConfig config) async {
    _config = config;
    _provider = _createProvider(config);
  }

  /// Create provider instance based on configuration
  BasePaymentProvider _createProvider(PaymentConfig config) {
    switch (config.provider) {
      case PaymentProvider.stripe:
        return StripePaymentProvider(config);
      case PaymentProvider.paypal:
        return PayPalPaymentProvider(config);
      case PaymentProvider.razorpay:
        return RazorPayPaymentProvider(config);
      case PaymentProvider.paystack:
        return PaystackPaymentProvider(config);
      case PaymentProvider.flutterwave:
        throw UnimplementedError('Flutterwave provider not yet implemented');
    }
  }

  /// Make a payment
  Future<void> pay({
    required BuildContext context,
    required PaymentRequest request,
    PaymentSuccessCallback? onSuccess,
    PaymentFailureCallback? onFailure,
    Duration? timeout,
  }) async {
    if (_config == null || _provider == null) {
      throw StateError('PaymentService not initialized. Call init() first.');
    }

    try {
      // Create payment URL via backend
      final paymentUrlResponse = await _provider!.createPaymentUrl(request);

      if (!context.mounted) return;

      // Launch WebView with payment URL
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => PaymentWebView(
            paymentUrl: paymentUrlResponse.paymentUrl,
            provider: _config!.provider,
            orderId: request.orderId,
            successUrlPattern: _getSuccessUrlPattern(),
            cancelUrlPattern: _getCancelUrlPattern(),
            failureUrlPattern: _getFailureUrlPattern(),
            timeout: timeout ?? const Duration(minutes: 15),
            onSuccess: (response) async {
              // Verify payment with backend if transaction ID is available
              if (response.transactionId != null) {
                try {
                  final verifiedResponse = await _provider!.verifyPayment(
                    response.transactionId!,
                  );
                  onSuccess?.call(verifiedResponse);
                } catch (e) {
                  // If verification fails, still call success with original response
                  onSuccess?.call(response);
                }
              } else {
                onSuccess?.call(response);
              }

              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            onFailure: (response) {
              onFailure?.call(response);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            onCancelled: () {
              onFailure?.call(PaymentResponse.cancelled(
                message: 'Payment was cancelled by user',
                orderId: request.orderId,
                provider: _config!.provider,
              ));
            },
          ),
        ),
      );
    } catch (e) {
      final errorResponse = PaymentResponse.failure(
        message: 'Failed to initiate payment: $e',
        orderId: request.orderId,
        provider: _config!.provider,
      );
      onFailure?.call(errorResponse);
    }
  }

  /// Get success URL pattern based on current provider
  String? _getSuccessUrlPattern() {
    if (_provider == null) return null;
    final patterns = _provider!.successUrlPatterns;
    return patterns.isNotEmpty ? patterns.first : null;
  }

  /// Get cancel URL pattern based on current provider
  String? _getCancelUrlPattern() {
    if (_provider == null) return null;
    final patterns = _provider!.cancelUrlPatterns;
    return patterns.isNotEmpty ? patterns.first : null;
  }

  /// Get failure URL pattern based on current provider
  String? _getFailureUrlPattern() {
    if (_provider == null) return null;
    final patterns = _provider!.failureUrlPatterns;
    return patterns.isNotEmpty ? patterns.first : null;
  }

  /// Verify a payment manually
  Future<PaymentResponse> verifyPayment(String transactionId) async {
    if (_provider == null) {
      throw StateError('PaymentService not initialized. Call init() first.');
    }

    return await _provider!.verifyPayment(transactionId);
  }

  /// Get current configuration
  PaymentConfig? get config => _config;

  /// Get current provider type
  PaymentProvider? get providerType => _config?.provider;

  /// Check if service is initialized
  bool get isInitialized => _config != null && _provider != null;

  /// Reset the service (useful for testing)
  void reset() {
    _config = null;
    _provider = null;
    _instance = null;
  }

  /// Create a payment URL without launching WebView
  /// Useful for custom implementations
  Future<PaymentUrlResponse> createPaymentUrl(PaymentRequest request) async {
    if (_provider == null) {
      throw StateError('PaymentService not initialized. Call init() first.');
    }

    return await _provider!.createPaymentUrl(request);
  }

  /// Handle payment response from external sources
  /// Useful when payment is completed outside the WebView
  PaymentResponse parsePaymentResponse(Map<String, dynamic> response) {
    if (_provider == null) {
      throw StateError('PaymentService not initialized. Call init() first.');
    }

    return _provider!.parsePaymentResponse(response);
  }

  /// Get provider-specific URL patterns
  Map<String, List<String>> getProviderUrlPatterns() {
    if (_provider == null) {
      return {};
    }

    return {
      'success': _provider!.successUrlPatterns,
      'cancel': _provider!.cancelUrlPatterns,
      'failure': _provider!.failureUrlPatterns,
    };
  }
}
