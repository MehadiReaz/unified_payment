import '../models/payment_config.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import 'base_provider.dart';

/// Stripe payment provider implementation
class StripePaymentProvider extends BasePaymentProvider {
  StripePaymentProvider(super.config);

  @override
  Future<PaymentUrlResponse> createPaymentUrl(PaymentRequest request) async {
    final response = await makeBackendRequest(
      endpoint: '/api/payments/create',
      method: 'POST',
      body: {
        'provider': 'stripe',
        'amount': (request.amount * 100).round(), // Convert to cents
        'currency': request.currency.toLowerCase(),
        'description': request.description,
        'order_id': request.orderId,
        'customer_email': request.customerEmail,
        'customer_name': request.customerName,
        'success_url': request.successUrl ??
            '${this.config.backendUrl}/api/payments/success',
        'cancel_url': request.cancelUrl ??
            '${this.config.backendUrl}/api/payments/cancel',
        'metadata': request.metadata,
        'api_key': this.config.apiKey,
        'environment': this.config.environment.name,
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
        provider: PaymentProvider.stripe,
      );
    }
  }

  @override
  PaymentResponse parsePaymentResponse(Map<String, dynamic> response) {
    final status = response['status']?.toString().toLowerCase();
    final transactionId = response['payment_intent_id'] ??
        response['transaction_id'] ??
        response['id'];
    final orderId = response['order_id'] ?? response['orderId'];

    switch (status) {
      case 'succeeded':
      case 'success':
      case 'completed':
        return PaymentResponse.success(
          transactionId: transactionId,
          message: 'Payment completed successfully',
          orderId: orderId,
          provider: PaymentProvider.stripe,
          amount: response['amount']?.toDouble(),
          currency: response['currency'],
          rawResponse: response,
        );

      case 'requires_action':
      case 'requires_source_action':
      case 'processing':
      case 'pending':
        return PaymentResponse.pending(
          transactionId: transactionId,
          message: 'Payment is being processed',
          orderId: orderId,
          provider: PaymentProvider.stripe,
          rawResponse: response,
        );

      case 'canceled':
      case 'cancelled':
        return PaymentResponse.cancelled(
          message: 'Payment was cancelled',
          orderId: orderId,
          provider: PaymentProvider.stripe,
          rawResponse: response,
        );

      case 'failed':
      case 'requires_payment_method':
      default:
        return PaymentResponse.failure(
          message: response['error_message'] ??
              response['failure_reason'] ??
              'Payment failed',
          errorCode: response['error_code'] ?? response['decline_code'],
          orderId: orderId,
          provider: PaymentProvider.stripe,
          rawResponse: response,
        );
    }
  }

  @override
  List<String> get successUrlPatterns => [
        '/api/payments/success',
        'payment_intent',
        'payment_intent_client_secret',
        'redirect_status=succeeded',
      ];

  @override
  List<String> get cancelUrlPatterns => [
        '/api/payments/cancel',
        'redirect_status=canceled',
        '/cancel',
      ];

  @override
  List<String> get failureUrlPatterns => [
        '/api/payments/failed',
        'redirect_status=failed',
        'error=',
        '/failed',
      ];
}
