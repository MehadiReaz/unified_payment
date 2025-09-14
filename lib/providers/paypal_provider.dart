import '../models/payment_config.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import 'base_provider.dart';

/// PayPal payment provider implementation
class PayPalPaymentProvider extends BasePaymentProvider {
  PayPalPaymentProvider(super.config);

  @override
  Future<PaymentUrlResponse> createPaymentUrl(PaymentRequest request) async {
    final response = await makeBackendRequest(
      endpoint: '/api/payments/create',
      method: 'POST',
      body: {
        'provider': 'paypal',
        'amount': request.amount,
        'currency': request.currency.toUpperCase(),
        'description': request.description,
        'order_id': request.orderId,
        'customer_email': request.customerEmail,
        'customer_name': request.customerName,
        'return_url':
            request.successUrl ?? '${config.backendUrl}/api/payments/success',
        'cancel_url':
            request.cancelUrl ?? '${config.backendUrl}/api/payments/cancel',
        'metadata': request.metadata,
        'client_id': config.apiKey,
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
        provider: PaymentProvider.paypal,
      );
    }
  }

  @override
  PaymentResponse parsePaymentResponse(Map<String, dynamic> response) {
    final status = response['status']?.toString().toLowerCase();
    final transactionId =
        response['transaction_id'] ?? response['payment_id'] ?? response['id'];
    final orderId = response['order_id'] ?? response['orderId'];

    switch (status) {
      case 'completed':
      case 'approved':
      case 'success':
        return PaymentResponse.success(
          transactionId: transactionId,
          message: 'Payment completed successfully',
          orderId: orderId,
          provider: PaymentProvider.paypal,
          amount: response['amount']?.toDouble(),
          currency: response['currency'],
          rawResponse: response,
        );

      case 'pending':
      case 'in_progress':
        return PaymentResponse.pending(
          transactionId: transactionId,
          message: 'Payment is being processed',
          orderId: orderId,
          provider: PaymentProvider.paypal,
          rawResponse: response,
        );

      case 'cancelled':
      case 'canceled':
        return PaymentResponse.cancelled(
          message: 'Payment was cancelled',
          orderId: orderId,
          provider: PaymentProvider.paypal,
          rawResponse: response,
        );

      case 'failed':
      case 'declined':
      case 'error':
      default:
        return PaymentResponse.failure(
          message: response['error_description'] ??
              response['failure_reason'] ??
              'Payment failed',
          errorCode: response['error_code'] ?? response['error'],
          orderId: orderId,
          provider: PaymentProvider.paypal,
          rawResponse: response,
        );
    }
  }

  @override
  List<String> get successUrlPatterns => [
        '/api/payments/success',
        'paymentId',
        'PayerID',
        'success=true',
      ];

  @override
  List<String> get cancelUrlPatterns => [
        '/api/payments/cancel',
        'cancel=true',
        'cancelled=true',
      ];

  @override
  List<String> get failureUrlPatterns => [
        '/api/payments/failed',
        'error=',
        'failed=true',
      ];
}
