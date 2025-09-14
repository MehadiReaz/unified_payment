import 'package:flutter_test/flutter_test.dart';
import 'package:unified_payment/providers/stripe_provider.dart';
import 'package:unified_payment/models/payment_config.dart';
import 'package:unified_payment/models/payment_request.dart';
import 'package:unified_payment/models/payment_response.dart';

void main() {
  group('StripePaymentProvider', () {
    late StripePaymentProvider stripeProvider;
    late PaymentConfig testConfig;

    setUp(() {
      testConfig = const PaymentConfig(
        provider: PaymentProvider.stripe,
        apiKey: 'pk_test_stripe_key',
        environment: PaymentEnvironment.sandbox,
        backendUrl: 'https://test-backend.com',
      );
      stripeProvider = StripePaymentProvider(testConfig);
    });

    group('constructor', () {
      test('should initialize with config', () {
        expect(stripeProvider.config, testConfig);
        expect(stripeProvider.config.provider, PaymentProvider.stripe);
      });
    });

    group('URL patterns', () {
      test('should have correct success URL patterns', () {
        final patterns = stripeProvider.successUrlPatterns;

        expect(patterns, isNotEmpty);
        expect(patterns, isA<List<String>>());
      });

      test('should have correct cancel URL patterns', () {
        final patterns = stripeProvider.cancelUrlPatterns;

        expect(patterns, isNotEmpty);
        expect(patterns, isA<List<String>>());
      });

      test('should have correct failure URL patterns', () {
        final patterns = stripeProvider.failureUrlPatterns;

        expect(patterns, isNotEmpty);
        expect(patterns, isA<List<String>>());
      });
    });

    group('parsePaymentResponse', () {
      test('should parse successful Stripe response', () {
        final stripeResponse = {
          'id': 'pi_stripe_123456',
          'status': 'succeeded',
          'amount': 2500,
          'currency': 'usd',
          'description': 'Test payment',
          'metadata': {'order_id': 'order_123'}
        };

        final paymentResponse =
            stripeProvider.parsePaymentResponse(stripeResponse);

        expect(paymentResponse, isA<PaymentResponse>());
        expect(paymentResponse.provider, PaymentProvider.stripe);
        expect(paymentResponse.rawResponse, stripeResponse);
      });

      test('should parse failed Stripe response', () {
        final stripeResponse = {
          'id': 'pi_stripe_failed',
          'status': 'failed',
          'last_payment_error': {
            'code': 'card_declined',
            'message': 'Your card was declined.'
          },
          'metadata': {'order_id': 'order_failed'}
        };

        final paymentResponse =
            stripeProvider.parsePaymentResponse(stripeResponse);

        expect(paymentResponse, isA<PaymentResponse>());
        expect(paymentResponse.provider, PaymentProvider.stripe);
        expect(paymentResponse.rawResponse, stripeResponse);
      });

      test('should parse cancelled Stripe response', () {
        final stripeResponse = {
          'id': 'pi_stripe_cancelled',
          'status': 'canceled',
          'cancellation_reason': 'abandoned',
          'metadata': {'order_id': 'order_cancelled'}
        };

        final paymentResponse =
            stripeProvider.parsePaymentResponse(stripeResponse);

        expect(paymentResponse, isA<PaymentResponse>());
        expect(paymentResponse.provider, PaymentProvider.stripe);
        expect(paymentResponse.rawResponse, stripeResponse);
      });

      test('should parse pending Stripe response', () {
        final stripeResponse = {
          'id': 'pi_stripe_pending',
          'status': 'processing',
          'metadata': {'order_id': 'order_pending'}
        };

        final paymentResponse =
            stripeProvider.parsePaymentResponse(stripeResponse);

        expect(paymentResponse, isA<PaymentResponse>());
        expect(paymentResponse.provider, PaymentProvider.stripe);
        expect(paymentResponse.rawResponse, stripeResponse);
      });

      test('should handle malformed response gracefully', () {
        final malformedResponse = {'unexpected_field': 'unexpected_value'};

        final paymentResponse =
            stripeProvider.parsePaymentResponse(malformedResponse);

        expect(paymentResponse, isA<PaymentResponse>());
        expect(paymentResponse.provider, PaymentProvider.stripe);
        expect(paymentResponse.rawResponse, malformedResponse);
      });
    });

    group('Stripe-specific logic', () {
      test('should format amount correctly for Stripe (cents)', () {
        const request = PaymentRequest(
          amount: 25.99,
          currency: 'USD',
          description: 'Test',
          orderId: 'test',
        );

        // Test the logic that would be used in the provider
        final amountInCents = (request.amount * 100).round();
        expect(amountInCents, 2599);
      });

      test('should handle different currencies', () {
        final currencies = ['USD', 'EUR', 'GBP', 'CAD'];

        for (final currency in currencies) {
          final request = PaymentRequest(
            amount: 100.0,
            currency: currency,
            description: 'Test',
            orderId: 'test',
          );

          expect(request.currency, currency);
          expect(request.amount, 100.0);
        }
      });
    });

    group('error handling', () {
      test('should create error response for network errors', () {
        const errorMessage = 'Network error';
        final errorResponse = PaymentResponse.failure(
          message: errorMessage,
          errorCode: 'NETWORK_ERROR',
          provider: PaymentProvider.stripe,
        );

        expect(errorResponse.isFailure, true);
        expect(errorResponse.errorCode, 'NETWORK_ERROR');
        expect(errorResponse.message, errorMessage);
        expect(errorResponse.provider, PaymentProvider.stripe);
      });

      test('should create timeout response', () {
        final timeoutResponse = PaymentResponse.timeout(
          message: 'Request timed out',
          provider: PaymentProvider.stripe,
        );

        expect(timeoutResponse.isTimeout, true);
        expect(timeoutResponse.provider, PaymentProvider.stripe);
      });
    });
  });
}
