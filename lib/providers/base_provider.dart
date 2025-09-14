import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_config.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';

/// Base class for payment provider implementations
abstract class BasePaymentProvider {
  /// Payment configuration
  final PaymentConfig config;

  BasePaymentProvider(this.config);

  /// Create a payment session and return the payment URL
  Future<PaymentUrlResponse> createPaymentUrl(PaymentRequest request);

  /// Verify payment status with the backend
  Future<PaymentResponse> verifyPayment(String transactionId);

  /// Parse provider-specific response into standardized PaymentResponse
  PaymentResponse parsePaymentResponse(Map<String, dynamic> response);

  /// Get provider-specific success URL patterns
  List<String> get successUrlPatterns;

  /// Get provider-specific cancel URL patterns
  List<String> get cancelUrlPatterns;

  /// Get provider-specific failure URL patterns
  List<String> get failureUrlPatterns;

  /// Make HTTP request to backend
  Future<http.Response> makeBackendRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${config.backendUrl}$endpoint');
    final requestHeaders = {
      'Content-Type': 'application/json',
      'X-Payment-Provider': config.provider.name,
      'X-Payment-Environment': config.environment.name,
      ...?config.customHeaders,
      ...?headers,
    };

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: requestHeaders);
      case 'POST':
        return await http.post(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(uri, headers: requestHeaders);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  /// Handle HTTP response and check for errors
  Map<String, dynamic> handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw PaymentProviderException(
        'Backend request failed with status ${response.statusCode}',
        statusCode: response.statusCode,
        response: response.body,
      );
    }
  }
}

/// Response model for payment URL creation
class PaymentUrlResponse {
  final String paymentUrl;
  final String? clientSecret;
  final String? transactionId;
  final Map<String, dynamic>? metadata;

  PaymentUrlResponse({
    required this.paymentUrl,
    this.clientSecret,
    this.transactionId,
    this.metadata,
  });

  factory PaymentUrlResponse.fromJson(Map<String, dynamic> json) {
    return PaymentUrlResponse(
      paymentUrl: json['payment_url'] ?? json['paymentUrl'] ?? '',
      clientSecret: json['client_secret'] ?? json['clientSecret'],
      transactionId: json['transaction_id'] ?? json['transactionId'],
      metadata: json['metadata'],
    );
  }
}

/// Exception class for payment provider errors
class PaymentProviderException implements Exception {
  final String message;
  final int? statusCode;
  final String? response;
  final String? errorCode;

  PaymentProviderException(
    this.message, {
    this.statusCode,
    this.response,
    this.errorCode,
  });

  @override
  String toString() {
    return 'PaymentProviderException: $message${errorCode != null ? ' (Code: $errorCode)' : ''}';
  }
}
