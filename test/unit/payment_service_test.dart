import 'package:flutter_test/flutter_test.dart';
import 'package:unified_payment/payment_service.dart';
import 'package:unified_payment/models/payment_config.dart';
import 'package:unified_payment/models/payment_request.dart';
import 'package:unified_payment/models/payment_response.dart';

void main() {
  group('PaymentService', () {
    late PaymentService paymentService;

    setUp(() {
      // Get fresh singleton instance for each test
      paymentService = PaymentService.instance;
      // Reset any previous state
      paymentService.reset();
    });

    tearDown(() {
      // Clean up after each test
      paymentService.reset();
    });

    group('Singleton pattern', () {
      test('should return same instance', () {
        final instance1 = PaymentService.instance;
        final instance2 = PaymentService.instance;
        final instance3 = PaymentService();

        expect(instance1, same(instance2));
        expect(instance1, same(instance3));
      });
    });

    group('initialization', () {
      test('should initialize with Stripe config', () async {
        const config = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: 'pk_test_stripe',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://backend.com',
        );

        await paymentService.init(config);

        expect(paymentService.isInitialized, true);
        expect(paymentService.config, config);
        expect(paymentService.providerType, PaymentProvider.stripe);
      });

      test('should initialize with PayPal config', () async {
        const config = PaymentConfig(
          provider: PaymentProvider.paypal,
          apiKey: 'paypal_client_id',
          environment: PaymentEnvironment.live,
          backendUrl: 'https://backend.com',
        );

        await paymentService.init(config);

        expect(paymentService.isInitialized, true);
        expect(paymentService.config, config);
        expect(paymentService.providerType, PaymentProvider.paypal);
      });

      test('should initialize with RazorPay config', () async {
        const config = PaymentConfig(
          provider: PaymentProvider.razorpay,
          apiKey: 'rzp_test_key',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://backend.com',
        );

        await paymentService.init(config);

        expect(paymentService.isInitialized, true);
        expect(paymentService.providerType, PaymentProvider.razorpay);
      });

      test('should initialize with Paystack config', () async {
        const config = PaymentConfig(
          provider: PaymentProvider.paystack,
          apiKey: 'pk_test_paystack',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://backend.com',
        );

        await paymentService.init(config);

        expect(paymentService.isInitialized, true);
        expect(paymentService.providerType, PaymentProvider.paystack);
      });

      test('should throw for Flutterwave (not implemented)', () async {
        const config = PaymentConfig(
          provider: PaymentProvider.flutterwave,
          apiKey: 'flw_test_key',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://backend.com',
        );

        expect(
          () async => await paymentService.init(config),
          throwsUnimplementedError,
        );
      });
    });

    group('configuration management', () {
      test('should update configuration', () async {
        const config1 = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: 'pk_test_1',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://backend1.com',
        );

        const config2 = PaymentConfig(
          provider: PaymentProvider.paypal,
          apiKey: 'pk_test_2',
          environment: PaymentEnvironment.live,
          backendUrl: 'https://backend2.com',
        );

        await paymentService.init(config1);
        expect(paymentService.providerType, PaymentProvider.stripe);

        await paymentService.init(config2); // Re-initialize with new config
        expect(paymentService.providerType, PaymentProvider.paypal);
        expect(paymentService.config, config2);
      });

      test('should handle uninitialized state', () {
        expect(paymentService.isInitialized, false);
        expect(paymentService.config, null);
        expect(paymentService.providerType, null);
      });
    });

    group('payment processing', () {
      setUp(() async {
        const config = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: 'pk_test_stripe',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://test-backend.com',
        );
        await paymentService.init(config);
      });

      test('should throw when creating payment URL without initialization',
          () async {
        final uninitializedService = PaymentService();
        uninitializedService.reset(); // Ensure clean state

        const request = PaymentRequest(
          amount: 1000.0,
          currency: 'USD',
          description: 'Test payment',
          orderId: 'order_123',
        );

        expect(
          () async => await uninitializedService.createPaymentUrl(request),
          throwsStateError,
        );
      });

      test('should handle payment request creation', () {
        const request = PaymentRequest(
          amount: 2500.0,
          currency: 'USD',
          description: 'Test payment',
          orderId: 'order_123',
          customerEmail: 'test@example.com',
        );

        expect(request.amount, 2500.0);
        expect(request.currency, 'USD');
        expect(request.orderId, 'order_123');
        expect(request.customerEmail, 'test@example.com');
      });
    });

    group('payment verification', () {
      setUp(() async {
        const config = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: 'pk_test_stripe',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://test-backend.com',
        );
        await paymentService.init(config);
      });

      test('should throw when verifying payment without initialization', () {
        final uninitializedService = PaymentService();
        uninitializedService.reset();

        expect(
          () async => await uninitializedService.verifyPayment('txn_123'),
          throwsStateError,
        );
      });
    });

    group('provider URL patterns', () {
      setUp(() async {
        const config = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: 'pk_test_stripe',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://test-backend.com',
        );
        await paymentService.init(config);
      });

      test('should return URL patterns for initialized provider', () {
        final patterns = paymentService.getProviderUrlPatterns();

        expect(patterns, isA<Map<String, List<String>>>());
        expect(patterns.containsKey('success'), true);
        expect(patterns.containsKey('cancel'), true);
        expect(patterns.containsKey('failure'), true);
      });

      test('should return empty map when not initialized', () {
        final uninitializedService = PaymentService();
        uninitializedService.reset();

        final patterns = uninitializedService.getProviderUrlPatterns();
        expect(patterns, isEmpty);
      });
    });

    group('response parsing', () {
      setUp(() async {
        const config = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: 'pk_test_stripe',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://test-backend.com',
        );
        await paymentService.init(config);
      });

      test('should parse payment response', () {
        final responseData = {
          'id': 'pi_test_123',
          'status': 'succeeded',
          'amount': 2500,
          'currency': 'usd',
        };

        final parsedResponse =
            paymentService.parsePaymentResponse(responseData);

        expect(parsedResponse, isA<PaymentResponse>());
        expect(parsedResponse.provider, PaymentProvider.stripe);
      });

      test('should throw when parsing response without initialization', () {
        final uninitializedService = PaymentService();
        uninitializedService.reset();

        final responseData = {
          'id': 'pi_test_123',
          'status': 'succeeded',
        };

        expect(
          () => uninitializedService.parsePaymentResponse(responseData),
          throwsStateError,
        );
      });
    });

    group('error handling', () {
      test('should handle provider creation errors gracefully', () async {
        const config = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: '', // Invalid empty key
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://backend.com',
        );

        // The service should still initialize
        await paymentService.init(config);
        expect(paymentService.isInitialized, true);
      });

      test('should create proper error responses', () {
        final errorResponse = PaymentResponse.failure(
          message: 'Test error',
          errorCode: 'TEST_ERROR',
          provider: PaymentProvider.stripe,
        );

        expect(errorResponse.isFailure, true);
        expect(errorResponse.errorCode, 'TEST_ERROR');
        expect(errorResponse.message, 'Test error');
      });
    });

    group('utility methods', () {
      test('should format currency correctly', () {
        const request = PaymentRequest(
          amount: 1234.56,
          currency: 'USD',
          description: 'Test',
          orderId: 'test',
        );

        expect(request.formattedAmount, 'USD 1234.56');
      });

      test('should convert amounts to major units', () {
        const usdRequest = PaymentRequest(
          amount: 2599.0, // 25.99 dollars in cents
          currency: 'USD',
          description: 'Test',
          orderId: 'test',
        );

        const jpyRequest = PaymentRequest(
          amount: 100.0, // 100 yen (no decimal places)
          currency: 'JPY',
          description: 'Test',
          orderId: 'test',
        );

        expect(usdRequest.amountInMajorUnits, 25.99);
        expect(jpyRequest.amountInMajorUnits, 100.0);
      });
    });

    group('reset functionality', () {
      test('should reset service state', () async {
        const config = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: 'pk_test_stripe',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://backend.com',
        );

        await paymentService.init(config);
        expect(paymentService.isInitialized, true);

        paymentService.reset();
        expect(paymentService.isInitialized, false);
        expect(paymentService.config, null);
        expect(paymentService.providerType, null);
      });
    });

    group('callback handling', () {
      test('should handle success callback signature', () {
        PaymentResponse? receivedResponse;

        void onSuccess(PaymentResponse response) {
          receivedResponse = response;
        }

        final response = PaymentResponse.success(
          transactionId: 'txn_123',
          message: 'Payment successful',
          provider: PaymentProvider.stripe,
        );

        // Simulate callback execution
        onSuccess(response);

        expect(receivedResponse, isNotNull);
        expect(receivedResponse!.isSuccess, true);
        expect(receivedResponse!.transactionId, 'txn_123');
      });

      test('should handle failure callback signature', () {
        PaymentResponse? receivedResponse;

        void onFailure(PaymentResponse response) {
          receivedResponse = response;
        }

        final response = PaymentResponse.failure(
          message: 'Payment failed',
          errorCode: 'CARD_DECLINED',
          provider: PaymentProvider.stripe,
        );

        // Simulate callback execution
        onFailure(response);

        expect(receivedResponse, isNotNull);
        expect(receivedResponse!.isFailure, true);
        expect(receivedResponse!.errorCode, 'CARD_DECLINED');
      });
    });
  });
}
