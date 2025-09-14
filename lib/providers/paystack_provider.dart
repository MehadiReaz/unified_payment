import '../models/payment_config.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import 'base_provider.dart';

/// Paystack payment provider implementation
class PaystackPaymentProvider extends BasePaymentProvider {
  PaystackPaymentProvider(super.config);

  @override
  Future<PaymentUrlResponse> createPaymentUrl(PaymentRequest request) async {
    final response = await makeBackendRequest(
      endpoint: '/api/payments/create',
      method: 'POST',
      body: {
        'provider': 'paystack',
        'amount': (request.amount * 100).round(), // Convert to kobo
        'currency': request.currency.toUpperCase(),
        'description': request.description,
        'reference': request.orderId,
        'email': request.customerEmail ?? '',
        'name': request.customerName,
        'phone': request.customerPhone,
        'callback_url':
            request.successUrl ?? '${config.backendUrl}/api/payments/success',
        'cancel_url':
            request.cancelUrl ?? '${config.backendUrl}/api/payments/cancel',
        'metadata': request.metadata,
        'public_key': config.apiKey,
        'environment': config.environment.name,
      },
    );

    final data = handleResponse(response);
    return PaymentUrlResponse.fromJson(data);
  }

  @override
  Future<PaymentResponse> verifyPayment(String transactionId) async {
    try {
      final response = await makeBackendRequest(
        endpoint: '/api/payments/verify/$transactionId',
        method: 'GET',
      );

      final data = handleResponse(response);
      return parsePaymentResponse(data);
    } catch (e) {
      return PaymentResponse.failure(
        message: 'Failed to verify payment: $e',
        provider: PaymentProvider.paystack,
      );
    }
  }

  @override
  PaymentResponse parsePaymentResponse(Map<String, dynamic> response) {
    final status = response['status']?.toString().toLowerCase();
    final transactionId =
        response['transaction_id'] ?? response['reference'] ?? response['id'];
    final orderId =
        response['reference'] ?? response['order_id'] ?? response['orderId'];

    switch (status) {
      case 'success':
      case 'successful':
      case 'completed':
        return PaymentResponse.success(
          transactionId: transactionId,
          message: 'Payment completed successfully',
          orderId: orderId,
          provider: PaymentProvider.paystack,
          amount: response['amount']?.toDouble(),
          currency: response['currency'],
          rawResponse: response,
        );

      case 'pending':
      case 'ongoing':
        return PaymentResponse.pending(
          transactionId: transactionId,
          message: 'Payment is being processed',
          orderId: orderId,
          provider: PaymentProvider.paystack,
          rawResponse: response,
        );

      case 'cancelled':
      case 'canceled':
        return PaymentResponse.cancelled(
          message: 'Payment was cancelled',
          orderId: orderId,
          provider: PaymentProvider.paystack,
          rawResponse: response,
        );

      case 'failed':
      case 'abandoned':
      default:
        return PaymentResponse.failure(
          message: response['gateway_response'] ??
              response['message'] ??
              'Payment failed',
          errorCode: response['error_code'],
          orderId: orderId,
          provider: PaymentProvider.paystack,
          rawResponse: response,
        );
    }
  }

  @override
  List<String> get successUrlPatterns => [
        '/api/payments/success',
        'trxref',
        'reference',
        'status=success',
      ];

  @override
  List<String> get cancelUrlPatterns => [
        '/api/payments/cancel',
        'status=cancelled',
        'cancel=true',
      ];

  @override
  List<String> get failureUrlPatterns => [
        '/api/payments/failed',
        'status=failed',
        'error=',
      ];
}
