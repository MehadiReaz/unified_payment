import 'package:flutter_test/flutter_test.dart';
import 'package:unified_payment/models/payment_request.dart';

void main() {
  group('PaymentRequest', () {
    const testRequest = PaymentRequest(
      amount: 2500.0,
      currency: 'USD',
      description: 'Test payment for order #12345',
      orderId: 'order_12345',
      successUrl: 'https://example.com/success',
      cancelUrl: 'https://example.com/cancel',
      customerEmail: 'test@example.com',
      customerName: 'John Doe',
      customerPhone: '+1234567890',
      metadata: {'productId': '123', 'category': 'electronics'},
      returnUrl: 'https://example.com/return',
    );

    group('constructor', () {
      test('should create PaymentRequest with required parameters', () {
        const request = PaymentRequest(
          amount: 1000.0,
          currency: 'EUR',
          description: 'Simple payment',
          orderId: 'simple_order',
        );

        expect(request.amount, 1000.0);
        expect(request.currency, 'EUR');
        expect(request.description, 'Simple payment');
        expect(request.orderId, 'simple_order');
        expect(request.successUrl, null);
        expect(request.cancelUrl, null);
        expect(request.customerEmail, null);
        expect(request.customerName, null);
        expect(request.customerPhone, null);
        expect(request.metadata, null);
        expect(request.returnUrl, null);
      });

      test('should create PaymentRequest with all parameters', () {
        expect(testRequest.amount, 2500.0);
        expect(testRequest.currency, 'USD');
        expect(testRequest.description, 'Test payment for order #12345');
        expect(testRequest.orderId, 'order_12345');
        expect(testRequest.successUrl, 'https://example.com/success');
        expect(testRequest.cancelUrl, 'https://example.com/cancel');
        expect(testRequest.customerEmail, 'test@example.com');
        expect(testRequest.customerName, 'John Doe');
        expect(testRequest.customerPhone, '+1234567890');
        expect(testRequest.metadata,
            {'productId': '123', 'category': 'electronics'});
        expect(testRequest.returnUrl, 'https://example.com/return');
      });
    });

    group('copyWith', () {
      test('should create new instance with updated amount', () {
        final newRequest = testRequest.copyWith(amount: 3000.0);

        expect(newRequest.amount, 3000.0);
        expect(newRequest.currency, testRequest.currency);
        expect(newRequest.description, testRequest.description);
        expect(newRequest.orderId, testRequest.orderId);
      });

      test('should create new instance with updated currency', () {
        final newRequest = testRequest.copyWith(currency: 'GBP');

        expect(newRequest.currency, 'GBP');
        expect(newRequest.amount, testRequest.amount);
        expect(newRequest.description, testRequest.description);
      });

      test('should create new instance with updated description', () {
        final newRequest =
            testRequest.copyWith(description: 'Updated description');

        expect(newRequest.description, 'Updated description');
        expect(newRequest.amount, testRequest.amount);
        expect(newRequest.currency, testRequest.currency);
      });

      test('should create new instance with updated orderId', () {
        final newRequest = testRequest.copyWith(orderId: 'new_order_id');

        expect(newRequest.orderId, 'new_order_id');
        expect(newRequest.amount, testRequest.amount);
        expect(newRequest.currency, testRequest.currency);
      });

      test('should create new instance with updated customer details', () {
        final newRequest = testRequest.copyWith(
          customerEmail: 'new@example.com',
          customerName: 'Jane Smith',
          customerPhone: '+9876543210',
        );

        expect(newRequest.customerEmail, 'new@example.com');
        expect(newRequest.customerName, 'Jane Smith');
        expect(newRequest.customerPhone, '+9876543210');
        expect(newRequest.amount, testRequest.amount);
      });

      test('should create new instance with updated URLs', () {
        final newRequest = testRequest.copyWith(
          successUrl: 'https://new.com/success',
          cancelUrl: 'https://new.com/cancel',
          returnUrl: 'https://new.com/return',
        );

        expect(newRequest.successUrl, 'https://new.com/success');
        expect(newRequest.cancelUrl, 'https://new.com/cancel');
        expect(newRequest.returnUrl, 'https://new.com/return');
        expect(newRequest.amount, testRequest.amount);
      });

      test('should create new instance with updated metadata', () {
        final newMetadata = {'newKey': 'newValue'};
        final newRequest = testRequest.copyWith(metadata: newMetadata);

        expect(newRequest.metadata, newMetadata);
        expect(newRequest.amount, testRequest.amount);
        expect(newRequest.currency, testRequest.currency);
      });

      test('should return identical instance if no parameters provided', () {
        final newRequest = testRequest.copyWith();

        expect(newRequest.amount, testRequest.amount);
        expect(newRequest.currency, testRequest.currency);
        expect(newRequest.description, testRequest.description);
        expect(newRequest.orderId, testRequest.orderId);
        expect(newRequest.successUrl, testRequest.successUrl);
        expect(newRequest.cancelUrl, testRequest.cancelUrl);
        expect(newRequest.customerEmail, testRequest.customerEmail);
        expect(newRequest.customerName, testRequest.customerName);
        expect(newRequest.customerPhone, testRequest.customerPhone);
        expect(newRequest.metadata, testRequest.metadata);
        expect(newRequest.returnUrl, testRequest.returnUrl);
      });
    });

    group('JSON serialization', () {
      test('should convert to JSON correctly', () {
        final json = testRequest.toJson();

        expect(json['amount'], 2500.0);
        expect(json['currency'], 'USD');
        expect(json['description'], 'Test payment for order #12345');
        expect(json['orderId'], 'order_12345');
        expect(json['successUrl'], 'https://example.com/success');
        expect(json['cancelUrl'], 'https://example.com/cancel');
        expect(json['customerEmail'], 'test@example.com');
        expect(json['customerName'], 'John Doe');
        expect(json['customerPhone'], '+1234567890');
        expect(
            json['metadata'], {'productId': '123', 'category': 'electronics'});
        expect(json['returnUrl'], 'https://example.com/return');
      });

      test('should convert to JSON with only required fields', () {
        const minimalRequest = PaymentRequest(
          amount: 1000.0,
          currency: 'EUR',
          description: 'Minimal payment',
          orderId: 'min_order',
        );

        final json = minimalRequest.toJson();

        expect(json['amount'], 1000.0);
        expect(json['currency'], 'EUR');
        expect(json['description'], 'Minimal payment');
        expect(json['orderId'], 'min_order');
        expect(json.containsKey('successUrl'), false);
        expect(json.containsKey('cancelUrl'), false);
        expect(json.containsKey('customerEmail'), false);
        expect(json.containsKey('customerName'), false);
        expect(json.containsKey('customerPhone'), false);
        expect(json.containsKey('metadata'), false);
        expect(json.containsKey('returnUrl'), false);
      });

      test('should convert from JSON correctly', () {
        final json = {
          'amount': 3500.0,
          'currency': 'GBP',
          'description': 'JSON payment',
          'orderId': 'json_order',
          'successUrl': 'https://json.com/success',
          'cancelUrl': 'https://json.com/cancel',
          'customerEmail': 'json@example.com',
          'customerName': 'JSON User',
          'customerPhone': '+1111111111',
          'metadata': {'source': 'json'},
          'returnUrl': 'https://json.com/return',
        };

        final request = PaymentRequest.fromJson(json);

        expect(request.amount, 3500.0);
        expect(request.currency, 'GBP');
        expect(request.description, 'JSON payment');
        expect(request.orderId, 'json_order');
        expect(request.successUrl, 'https://json.com/success');
        expect(request.cancelUrl, 'https://json.com/cancel');
        expect(request.customerEmail, 'json@example.com');
        expect(request.customerName, 'JSON User');
        expect(request.customerPhone, '+1111111111');
        expect(request.metadata, {'source': 'json'});
        expect(request.returnUrl, 'https://json.com/return');
      });

      test('should handle JSON with null optional fields', () {
        final json = {
          'amount': 1500.0,
          'currency': 'INR',
          'description': 'Null optional fields',
          'orderId': 'null_order',
          'successUrl': null,
          'cancelUrl': null,
          'customerEmail': null,
          'customerName': null,
          'customerPhone': null,
          'metadata': null,
          'returnUrl': null,
        };

        final request = PaymentRequest.fromJson(json);

        expect(request.amount, 1500.0);
        expect(request.currency, 'INR');
        expect(request.description, 'Null optional fields');
        expect(request.orderId, 'null_order');
        expect(request.successUrl, null);
        expect(request.cancelUrl, null);
        expect(request.customerEmail, null);
        expect(request.customerName, null);
        expect(request.customerPhone, null);
        expect(request.metadata, null);
        expect(request.returnUrl, null);
      });

      test('should handle JSON without optional fields', () {
        final json = {
          'amount': 2000.0,
          'currency': 'CAD',
          'description': 'Missing optional fields',
          'orderId': 'missing_order',
        };

        final request = PaymentRequest.fromJson(json);

        expect(request.amount, 2000.0);
        expect(request.currency, 'CAD');
        expect(request.description, 'Missing optional fields');
        expect(request.orderId, 'missing_order');
        expect(request.successUrl, null);
        expect(request.cancelUrl, null);
        expect(request.customerEmail, null);
        expect(request.customerName, null);
        expect(request.customerPhone, null);
        expect(request.metadata, null);
        expect(request.returnUrl, null);
      });
    });

    group('equality', () {
      test('should be equal when all properties are same', () {
        const request1 = PaymentRequest(
          amount: 1000.0,
          currency: 'USD',
          description: 'Test payment',
          orderId: 'test_order',
          customerEmail: 'test@example.com',
        );

        const request2 = PaymentRequest(
          amount: 1000.0,
          currency: 'USD',
          description: 'Test payment',
          orderId: 'test_order',
          customerEmail: 'test@example.com',
        );

        expect(request1, request2);
      });

      test('should not be equal when properties differ', () {
        const request1 = PaymentRequest(
          amount: 1000.0,
          currency: 'USD',
          description: 'Test payment',
          orderId: 'test_order',
        );

        const request2 = PaymentRequest(
          amount: 2000.0,
          currency: 'USD',
          description: 'Test payment',
          orderId: 'test_order',
        );

        expect(request1, isNot(request2));
      });

      test('should have same hashCode when equal', () {
        const request1 = PaymentRequest(
          amount: 1000.0,
          currency: 'USD',
          description: 'Test payment',
          orderId: 'test_order',
        );

        const request2 = PaymentRequest(
          amount: 1000.0,
          currency: 'USD',
          description: 'Test payment',
          orderId: 'test_order',
        );

        expect(request1.hashCode, request2.hashCode);
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final requestString = testRequest.toString();

        expect(requestString, contains('PaymentRequest'));
        expect(requestString, contains('USD 2500.00'));
        expect(requestString, contains('order_12345'));
      });
    });

    group('formattedAmount', () {
      test('should return formatted amount with currency', () {
        const request = PaymentRequest(
          amount: 2500.0,
          currency: 'USD',
          description: 'Test',
          orderId: 'test',
        );

        expect(request.formattedAmount, 'USD 2500.00');
      });

      test('should handle different currencies', () {
        const request = PaymentRequest(
          amount: 1250.75,
          currency: 'EUR',
          description: 'Test',
          orderId: 'test',
        );

        expect(request.formattedAmount, 'EUR 1250.75');
      });
    });

    group('amountInMajorUnits', () {
      test('should convert amount to major units for standard currencies', () {
        const request = PaymentRequest(
          amount: 2599.0,
          currency: 'USD',
          description: 'Test',
          orderId: 'test',
        );

        expect(request.amountInMajorUnits, 25.99);
      });

      test('should return same amount for JPY (no decimal places)', () {
        const request = PaymentRequest(
          amount: 100.0,
          currency: 'JPY',
          description: 'Test',
          orderId: 'test',
        );

        expect(request.amountInMajorUnits, 100.0);
      });

      test('should return same amount for KRW (no decimal places)', () {
        const request = PaymentRequest(
          amount: 1000.0,
          currency: 'KRW',
          description: 'Test',
          orderId: 'test',
        );

        expect(request.amountInMajorUnits, 1000.0);
      });
    });
  });
}
