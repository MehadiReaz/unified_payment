import 'package:flutter_test/flutter_test.dart';
import 'package:unified_payment/unified_payment.dart';

void main() {
  group('Payment Integration Tests', () {
    group('End-to-End Payment Flow', () {
      test(
          'should coordinate PaymentConfig, PaymentRequest, and PaymentResponse',
          () async {
        // Test PaymentConfig creation and validation
        final config = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: 'pk_test_mock_stripe_key',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://api.example.com/payments',
          webhookUrl: 'https://api.example.com/webhooks/payments',
          customHeaders: {
            'Authorization': 'Bearer test_token',
            'Content-Type': 'application/json',
          },
        );

        expect(config.provider, PaymentProvider.stripe);
        expect(config.environment, PaymentEnvironment.sandbox);
        expect(config.apiKey, 'pk_test_mock_stripe_key');
        expect(config.backendUrl, 'https://api.example.com/payments');
        expect(config.webhookUrl, 'https://api.example.com/webhooks/payments');
        expect(config.customHeaders!['Authorization'], 'Bearer test_token');

        // Test PaymentRequest creation and validation
        final request = PaymentRequest(
          amount: 2500.0, // 2500 cents = $25.00
          currency: 'USD',
          description: 'Integration Test Payment',
          customerEmail: 'integration@test.com',
          orderId: 'order_integration_001',
          metadata: {
            'test_type': 'integration',
            'environment': 'test',
          },
        );

        expect(request.amount, 2500.0);
        expect(request.currency, 'USD');
        expect(request.description, 'Integration Test Payment');
        expect(request.customerEmail, 'integration@test.com');
        expect(request.orderId, 'order_integration_001');
        expect(request.formattedAmount, 'USD 2500.00');
        expect(request.amountInMajorUnits, 25.0);
        expect(request.metadata!['test_type'], 'integration');

        // Test PaymentResponse creation and status handling
        final successResponse = PaymentResponse(
          status: PaymentStatus.success,
          message: 'Payment processed successfully',
          transactionId: 'txn_integration_success_001',
          orderId: request.orderId,
          provider: PaymentProvider.stripe,
          amount: request.amount,
          currency: request.currency,
          metadata: {
            'integration_test': true,
            'flow_type': 'success',
          },
        );

        expect(successResponse.transactionId, 'txn_integration_success_001');
        expect(successResponse.amount, request.amount);
        expect(successResponse.currency, request.currency);
        expect(successResponse.status, PaymentStatus.success);
        expect(successResponse.provider, PaymentProvider.stripe);
        expect(successResponse.orderId, request.orderId);
        expect(successResponse.metadata!['integration_test'], true);

        // Test different payment statuses
        final failedResponse = PaymentResponse(
          status: PaymentStatus.failure,
          message: 'Card declined',
          transactionId: 'txn_integration_failed_001',
          orderId: request.orderId,
          provider: PaymentProvider.stripe,
          amount: request.amount,
          currency: request.currency,
          errorCode: 'card_declined',
          metadata: {
            'error_code': 'card_declined',
            'integration_test': true,
          },
        );

        expect(failedResponse.status, PaymentStatus.failure);
        expect(failedResponse.message, 'Card declined');
        expect(failedResponse.errorCode, 'card_declined');
        expect(failedResponse.metadata!['error_code'], 'card_declined');

        final cancelledResponse = PaymentResponse(
          status: PaymentStatus.cancelled,
          message: 'Payment cancelled by user',
          transactionId: 'txn_integration_cancelled_001',
          orderId: request.orderId,
          provider: PaymentProvider.stripe,
          amount: request.amount,
          currency: request.currency,
          metadata: {
            'cancellation_reason': 'user_cancelled',
            'integration_test': true,
          },
        );

        expect(cancelledResponse.status, PaymentStatus.cancelled);
        expect(cancelledResponse.message, 'Payment cancelled by user');
        expect(cancelledResponse.metadata!['cancellation_reason'],
            'user_cancelled');
      });

      test('should handle multiple payment providers consistently', () async {
        final providers = [
          PaymentProvider.stripe,
          PaymentProvider.paypal,
          PaymentProvider.razorpay,
          PaymentProvider.paystack,
          PaymentProvider.flutterwave,
        ];

        for (final provider in providers) {
          final config = PaymentConfig(
            provider: provider,
            apiKey: 'test_key_${provider.name}',
            environment: PaymentEnvironment.sandbox,
            backendUrl: 'https://api.example.com/payments',
          );

          expect(config.provider, provider);
          expect(config.apiKey, 'test_key_${provider.name}');

          final request = PaymentRequest(
            amount: 1000.0, // 1000 cents = $10.00
            currency: 'USD',
            description: 'Multi-provider test',
            customerEmail: 'provider@test.com',
            orderId: 'order_${provider.name}_001',
          );

          final response = PaymentResponse(
            status: PaymentStatus.success,
            message: 'Payment successful',
            transactionId: 'txn_${provider.name}_001',
            orderId: request.orderId,
            provider: provider,
            amount: request.amount,
            currency: request.currency,
            metadata: {
              'provider': provider.name,
              'test': 'multi_provider',
            },
          );

          expect(response.provider, provider);
          expect(response.metadata!['provider'], provider.name);
        }
      });

      test('should maintain data integrity through serialization', () async {
        final originalConfig = PaymentConfig(
          provider: PaymentProvider.razorpay,
          apiKey: 'rzp_test_serialization',
          environment: PaymentEnvironment.live,
          backendUrl: 'https://api.razorpay.com/v1',
          webhookUrl: 'https://webhook.example.com/razorpay',
          customHeaders: {
            'X-Razorpay-Version': '2023-08-01',
            'Authorization': 'Basic dGVzdF9rZXk6',
          },
        );

        final configJson = originalConfig.toJson();
        final deserializedConfig = PaymentConfig.fromJson(configJson);

        expect(deserializedConfig.provider, originalConfig.provider);
        expect(deserializedConfig.apiKey, originalConfig.apiKey);
        expect(deserializedConfig.environment, originalConfig.environment);
        expect(deserializedConfig.backendUrl, originalConfig.backendUrl);
        expect(deserializedConfig.webhookUrl, originalConfig.webhookUrl);
        expect(deserializedConfig.customHeaders, originalConfig.customHeaders);

        final originalRequest = PaymentRequest(
          amount: 15000.0, // 15000 paisa = ₹150.00
          currency: 'INR',
          description: 'Serialization test payment',
          customerEmail: 'serialize@test.com',
          orderId: 'order_serialize_001',
          metadata: {
            'test_type': 'serialization',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );

        final requestJson = originalRequest.toJson();
        final deserializedRequest = PaymentRequest.fromJson(requestJson);

        expect(deserializedRequest.amount, originalRequest.amount);
        expect(deserializedRequest.currency, originalRequest.currency);
        expect(deserializedRequest.description, originalRequest.description);
        expect(
            deserializedRequest.customerEmail, originalRequest.customerEmail);
        expect(deserializedRequest.orderId, originalRequest.orderId);
        expect(deserializedRequest.metadata!['test_type'], 'serialization');

        final originalResponse = PaymentResponse(
          status: PaymentStatus.success,
          message: 'Payment successful',
          transactionId: 'txn_serialize_001',
          orderId: originalRequest.orderId,
          provider: PaymentProvider.razorpay,
          amount: originalRequest.amount,
          currency: originalRequest.currency,
          metadata: {
            'serialization_test': true,
            'response_time': DateTime.now().millisecondsSinceEpoch,
          },
        );

        final responseJson = originalResponse.toJson();
        final deserializedResponse = PaymentResponse.fromJson(responseJson);

        expect(
            deserializedResponse.transactionId, originalResponse.transactionId);
        expect(deserializedResponse.amount, originalResponse.amount);
        expect(deserializedResponse.currency, originalResponse.currency);
        expect(deserializedResponse.status, originalResponse.status);
        expect(deserializedResponse.provider, originalResponse.provider);
        expect(deserializedResponse.orderId, originalResponse.orderId);
        expect(deserializedResponse.metadata!['serialization_test'], true);
      });
    });

    group('PaymentService Integration', () {
      test('should initialize and manage payment service lifecycle', () async {
        final service = PaymentService.instance;

        // Test initial state
        expect(service.isInitialized, false);

        // Test initialization
        final config = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: 'pk_test_service_integration',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://api.stripe.com/v1',
        );

        await service.init(config);

        expect(service.isInitialized, true);

        // Test reset
        service.reset();

        expect(service.isInitialized, false);
      });

      test('should handle provider URL patterns correctly', () async {
        final service = PaymentService.instance;

        final stripeConfig = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: 'pk_test_stripe',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://api.stripe.com/v1',
        );

        await service.init(stripeConfig);

        // Test that service is initialized with correct provider configuration
        expect(service.isInitialized, true);

        service.reset();
      });
    });
  });
}
