import '../models/payment_config.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import 'base_provider.dart';

/// RazorPay payment provider implementation
class RazorPayPaymentProvider extends BasePaymentProvider {
  RazorPayPaymentProvider(super.config);

  @override
  Future<PaymentUrlResponse> createPaymentUrl(PaymentRequest request) async {
    final response = await makeBackendRequest(
      endpoint: '/api/payments/create',
      method: 'POST',
      body: {
        'provider': 'razorpay',
        'amount': (request.amount * 100).round(), // Convert to paise
        'currency': request.currency.toUpperCase(),
        'description': request.description,
        'order_id': request.orderId,
        'customer_email': request.customerEmail,
        'customer_name': request.customerName,
        'customer_contact': request.customerPhone,
        'callback_url':
            request.successUrl ?? '${config.backendUrl}/api/payments/success',
        'cancel_url':
            request.cancelUrl ?? '${config.backendUrl}/api/payments/cancel',
        'notes': request.metadata,
        'key_id': config.apiKey,
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
        provider: PaymentProvider.razorpay,
      );
    }
  }

  @override
  PaymentResponse parsePaymentResponse(Map<String, dynamic> response) {
    final status = response['status']?.toString().toLowerCase();
    final transactionId = response['razorpay_payment_id'] ??
        response['payment_id'] ??
        response['id'];
    final orderId = response['razorpay_order_id'] ??
        response['order_id'] ??
        response['orderId'];

    switch (status) {
      case 'captured':
      case 'authorized':
      case 'success':
        return PaymentResponse.success(
          transactionId: transactionId,
          message: 'Payment completed successfully',
          orderId: orderId,
          provider: PaymentProvider.razorpay,
          amount: response['amount']?.toDouble(),
          currency: response['currency'],
          rawResponse: response,
        );

      case 'created':
      case 'pending':
        return PaymentResponse.pending(
          transactionId: transactionId,
          message: 'Payment is being processed',
          orderId: orderId,
          provider: PaymentProvider.razorpay,
          rawResponse: response,
        );

      case 'cancelled':
      case 'canceled':
        return PaymentResponse.cancelled(
          message: 'Payment was cancelled',
          orderId: orderId,
          provider: PaymentProvider.razorpay,
          rawResponse: response,
        );

      case 'failed':
      case 'error':
      default:
        return PaymentResponse.failure(
          message: response['error_description'] ??
              response['error']['description'] ??
              'Payment failed',
          errorCode: response['error_code'] ?? response['error']['code'],
          orderId: orderId,
          provider: PaymentProvider.razorpay,
          rawResponse: response,
        );
    }
  }

  @override
  List<String> get successUrlPatterns => [
        '/api/payments/success',
        'razorpay_payment_id',
        'razorpay_order_id',
        'razorpay_signature',
      ];

  @override
  List<String> get cancelUrlPatterns => [
        '/api/payments/cancel',
        'error=payment_cancelled',
        'cancel=true',
      ];

  @override
  List<String> get failureUrlPatterns => [
        '/api/payments/failed',
        'error=payment_failed',
        'razorpay_error',
      ];
}
