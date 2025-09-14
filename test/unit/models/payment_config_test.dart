import 'package:flutter_test/flutter_test.dart';
import 'package:unified_payment/models/payment_config.dart';

void main() {
  group('PaymentConfig', () {
    const testConfig = PaymentConfig(
      provider: PaymentProvider.stripe,
      apiKey: 'pk_test_123456789',
      environment: PaymentEnvironment.sandbox,
      backendUrl: 'https://api.example.com',
      webhookUrl: 'https://webhook.example.com',
      customHeaders: {'Custom-Header': 'value'},
    );

    group('constructor', () {
      test('should create PaymentConfig with required parameters', () {
        const config = PaymentConfig(
          provider: PaymentProvider.paypal,
          apiKey: 'test_api_key',
          environment: PaymentEnvironment.live,
          backendUrl: 'https://backend.example.com',
        );

        expect(config.provider, PaymentProvider.paypal);
        expect(config.apiKey, 'test_api_key');
        expect(config.environment, PaymentEnvironment.live);
        expect(config.backendUrl, 'https://backend.example.com');
        expect(config.webhookUrl, null);
        expect(config.customHeaders, null);
      });

      test('should create PaymentConfig with all parameters', () {
        expect(testConfig.provider, PaymentProvider.stripe);
        expect(testConfig.apiKey, 'pk_test_123456789');
        expect(testConfig.environment, PaymentEnvironment.sandbox);
        expect(testConfig.backendUrl, 'https://api.example.com');
        expect(testConfig.webhookUrl, 'https://webhook.example.com');
        expect(testConfig.customHeaders, {'Custom-Header': 'value'});
      });
    });

    group('copyWith', () {
      test('should create new instance with updated provider', () {
        final newConfig =
            testConfig.copyWith(provider: PaymentProvider.razorpay);

        expect(newConfig.provider, PaymentProvider.razorpay);
        expect(newConfig.apiKey, testConfig.apiKey);
        expect(newConfig.environment, testConfig.environment);
        expect(newConfig.backendUrl, testConfig.backendUrl);
      });

      test('should create new instance with updated apiKey', () {
        final newConfig = testConfig.copyWith(apiKey: 'new_api_key');

        expect(newConfig.provider, testConfig.provider);
        expect(newConfig.apiKey, 'new_api_key');
        expect(newConfig.environment, testConfig.environment);
      });

      test('should create new instance with updated environment', () {
        final newConfig =
            testConfig.copyWith(environment: PaymentEnvironment.live);

        expect(newConfig.environment, PaymentEnvironment.live);
        expect(newConfig.provider, testConfig.provider);
      });

      test('should create new instance with updated backendUrl', () {
        final newConfig =
            testConfig.copyWith(backendUrl: 'https://new-backend.com');

        expect(newConfig.backendUrl, 'https://new-backend.com');
        expect(newConfig.provider, testConfig.provider);
      });

      test('should create new instance with updated webhookUrl', () {
        final newConfig =
            testConfig.copyWith(webhookUrl: 'https://new-webhook.com');

        expect(newConfig.webhookUrl, 'https://new-webhook.com');
        expect(newConfig.provider, testConfig.provider);
      });

      test('should create new instance with updated customHeaders', () {
        final newHeaders = {'New-Header': 'new-value'};
        final newConfig = testConfig.copyWith(customHeaders: newHeaders);

        expect(newConfig.customHeaders, newHeaders);
        expect(newConfig.provider, testConfig.provider);
      });

      test('should return identical instance if no parameters provided', () {
        final newConfig = testConfig.copyWith();

        expect(newConfig.provider, testConfig.provider);
        expect(newConfig.apiKey, testConfig.apiKey);
        expect(newConfig.environment, testConfig.environment);
        expect(newConfig.backendUrl, testConfig.backendUrl);
        expect(newConfig.webhookUrl, testConfig.webhookUrl);
        expect(newConfig.customHeaders, testConfig.customHeaders);
      });
    });

    group('JSON serialization', () {
      test('should convert to JSON correctly', () {
        final json = testConfig.toJson();

        expect(json['provider'], 'stripe');
        expect(json['apiKey'], 'pk_test_123456789');
        expect(json['environment'], 'sandbox');
        expect(json['backendUrl'], 'https://api.example.com');
        expect(json['webhookUrl'], 'https://webhook.example.com');
        expect(json['customHeaders'], {'Custom-Header': 'value'});
      });

      test('should convert from JSON correctly', () {
        final json = {
          'provider': 'paypal',
          'apiKey': 'test_key',
          'environment': 'live',
          'backendUrl': 'https://backend.com',
          'webhookUrl': 'https://webhook.com',
          'customHeaders': {'Auth': 'Bearer token'}
        };

        final config = PaymentConfig.fromJson(json);

        expect(config.provider, PaymentProvider.paypal);
        expect(config.apiKey, 'test_key');
        expect(config.environment, PaymentEnvironment.live);
        expect(config.backendUrl, 'https://backend.com');
        expect(config.webhookUrl, 'https://webhook.com');
        expect(config.customHeaders, {'Auth': 'Bearer token'});
      });

      test('should handle JSON with null optional fields', () {
        final json = {
          'provider': 'razorpay',
          'apiKey': 'rzp_test_key',
          'environment': 'sandbox',
          'backendUrl': 'https://api.example.com',
          'webhookUrl': null,
          'customHeaders': null,
        };

        final config = PaymentConfig.fromJson(json);

        expect(config.provider, PaymentProvider.razorpay);
        expect(config.apiKey, 'rzp_test_key');
        expect(config.environment, PaymentEnvironment.sandbox);
        expect(config.backendUrl, 'https://api.example.com');
        expect(config.webhookUrl, null);
        expect(config.customHeaders, null);
      });

      test('should handle JSON without optional fields', () {
        final json = {
          'provider': 'paystack',
          'apiKey': 'pk_test_paystack',
          'environment': 'live',
          'backendUrl': 'https://paystack-backend.com',
        };

        final config = PaymentConfig.fromJson(json);

        expect(config.provider, PaymentProvider.paystack);
        expect(config.apiKey, 'pk_test_paystack');
        expect(config.environment, PaymentEnvironment.live);
        expect(config.backendUrl, 'https://paystack-backend.com');
        expect(config.webhookUrl, null);
        expect(config.customHeaders, null);
      });
    });

    group('equality', () {
      test('should be equal when all properties are same', () {
        const config1 = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: 'test_key',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://backend.com',
        );

        const config2 = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: 'test_key',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://backend.com',
        );

        expect(config1, config2);
      });

      test('should not be equal when properties differ', () {
        const config1 = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: 'test_key',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://backend.com',
        );

        const config2 = PaymentConfig(
          provider: PaymentProvider.paypal,
          apiKey: 'test_key',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://backend.com',
        );

        expect(config1, isNot(config2));
      });

      test('should have same hashCode when equal', () {
        const config1 = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: 'test_key',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://backend.com',
        );

        const config2 = PaymentConfig(
          provider: PaymentProvider.stripe,
          apiKey: 'test_key',
          environment: PaymentEnvironment.sandbox,
          backendUrl: 'https://backend.com',
        );

        expect(config1.hashCode, config2.hashCode);
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final configString = testConfig.toString();

        expect(configString, contains('PaymentConfig'));
        expect(configString, contains('stripe'));
        expect(configString, contains('sandbox'));
        expect(configString, contains('https://api.example.com'));
      });
    });
  });

  group('PaymentProvider enum', () {
    test('should have correct values', () {
      expect(PaymentProvider.values.length, 5);
      expect(PaymentProvider.values, contains(PaymentProvider.stripe));
      expect(PaymentProvider.values, contains(PaymentProvider.paypal));
      expect(PaymentProvider.values, contains(PaymentProvider.razorpay));
      expect(PaymentProvider.values, contains(PaymentProvider.paystack));
      expect(PaymentProvider.values, contains(PaymentProvider.flutterwave));
    });
  });

  group('PaymentEnvironment enum', () {
    test('should have correct values', () {
      expect(PaymentEnvironment.values.length, 2);
      expect(PaymentEnvironment.values, contains(PaymentEnvironment.sandbox));
      expect(PaymentEnvironment.values, contains(PaymentEnvironment.live));
    });
  });
}
