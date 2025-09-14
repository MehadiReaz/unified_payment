import 'package:flutter_test/flutter_test.dart';
import 'package:unified_payment/models/payment_response.dart';
import 'package:unified_payment/models/payment_config.dart';

void main() {
  group('PaymentResponse', () {
    final testTimestamp = DateTime(2025, 9, 14, 10, 30, 0);

    final testResponse = PaymentResponse(
      status: PaymentStatus.success,
      transactionId: 'txn_123456789',
      orderId: 'order_12345',
      provider: PaymentProvider.stripe,
      message: 'Payment processed successfully',
      errorCode: null,
      rawResponse: {'id': 'pi_123', 'status': 'succeeded'},
      timestamp: testTimestamp,
      amount: 2500.0,
      currency: 'USD',
      metadata: {'source': 'mobile_app'},
    );

    group('constructor', () {
      test('should create PaymentResponse with required parameters', () {
        final response = PaymentResponse(
          status: PaymentStatus.failure,
          message: 'Payment failed',
          timestamp: testTimestamp,
        );

        expect(response.status, PaymentStatus.failure);
        expect(response.message, 'Payment failed');
        expect(response.timestamp, testTimestamp);
        expect(response.transactionId, null);
        expect(response.orderId, null);
        expect(response.provider, null);
        expect(response.errorCode, null);
        expect(response.rawResponse, null);
        expect(response.amount, null);
        expect(response.currency, null);
        expect(response.metadata, null);
      });

      test('should create PaymentResponse with all parameters', () {
        expect(testResponse.status, PaymentStatus.success);
        expect(testResponse.transactionId, 'txn_123456789');
        expect(testResponse.orderId, 'order_12345');
        expect(testResponse.provider, PaymentProvider.stripe);
        expect(testResponse.message, 'Payment processed successfully');
        expect(testResponse.errorCode, null);
        expect(
            testResponse.rawResponse, {'id': 'pi_123', 'status': 'succeeded'});
        expect(testResponse.timestamp, testTimestamp);
        expect(testResponse.amount, 2500.0);
        expect(testResponse.currency, 'USD');
        expect(testResponse.metadata, {'source': 'mobile_app'});
      });
    });

    group('factory constructors', () {
      test('should create success response', () {
        final response = PaymentResponse.success(
          transactionId: 'txn_success',
          orderId: 'order_success',
          provider: PaymentProvider.paypal,
          message: 'Success message',
          amount: 1000.0,
          currency: 'EUR',
          rawResponse: {'status': 'completed'},
          metadata: {'test': 'success'},
        );

        expect(response.status, PaymentStatus.success);
        expect(response.transactionId, 'txn_success');
        expect(response.orderId, 'order_success');
        expect(response.provider, PaymentProvider.paypal);
        expect(response.message, 'Success message');
        expect(response.amount, 1000.0);
        expect(response.currency, 'EUR');
        expect(response.rawResponse, {'status': 'completed'});
        expect(response.metadata, {'test': 'success'});
        expect(response.timestamp, isA<DateTime>());
      });

      test('should create failure response', () {
        final response = PaymentResponse.failure(
          orderId: 'order_fail',
          provider: PaymentProvider.razorpay,
          message: 'Card declined',
          errorCode: 'CARD_DECLINED',
          rawResponse: {'error': 'declined'},
        );

        expect(response.status, PaymentStatus.failure);
        expect(response.orderId, 'order_fail');
        expect(response.provider, PaymentProvider.razorpay);
        expect(response.message, 'Card declined');
        expect(response.errorCode, 'CARD_DECLINED');
        expect(response.rawResponse, {'error': 'declined'});
        expect(response.transactionId, null);
        expect(response.timestamp, isA<DateTime>());
      });

      test('should create cancelled response', () {
        final response = PaymentResponse.cancelled(
          orderId: 'order_cancelled',
          provider: PaymentProvider.paystack,
          message: 'Payment cancelled by user',
        );

        expect(response.status, PaymentStatus.cancelled);
        expect(response.orderId, 'order_cancelled');
        expect(response.provider, PaymentProvider.paystack);
        expect(response.message, 'Payment cancelled by user');
        expect(response.transactionId, null);
        expect(response.errorCode, null);
        expect(response.timestamp, isA<DateTime>());
      });

      test('should create pending response', () {
        final response = PaymentResponse.pending(
          transactionId: 'txn_pending',
          orderId: 'order_pending',
          provider: PaymentProvider.flutterwave,
          message: 'Payment is being processed',
        );

        expect(response.status, PaymentStatus.pending);
        expect(response.transactionId, 'txn_pending');
        expect(response.orderId, 'order_pending');
        expect(response.provider, PaymentProvider.flutterwave);
        expect(response.message, 'Payment is being processed');
        expect(response.timestamp, isA<DateTime>());
      });

      test('should create timeout response', () {
        final response = PaymentResponse.timeout(
          orderId: 'order_timeout',
          provider: PaymentProvider.stripe,
          message: 'Payment timed out',
        );

        expect(response.status, PaymentStatus.timeout);
        expect(response.orderId, 'order_timeout');
        expect(response.provider, PaymentProvider.stripe);
        expect(response.message, 'Payment timed out');
        expect(response.transactionId, null);
        expect(response.timestamp, isA<DateTime>());
      });
    });

    group('copyWith', () {
      test('should create new instance with updated status', () {
        final newResponse =
            testResponse.copyWith(status: PaymentStatus.pending);

        expect(newResponse.status, PaymentStatus.pending);
        expect(newResponse.transactionId, testResponse.transactionId);
        expect(newResponse.orderId, testResponse.orderId);
        expect(newResponse.message, testResponse.message);
      });

      test('should create new instance with updated message', () {
        final newResponse = testResponse.copyWith(message: 'Updated message');

        expect(newResponse.message, 'Updated message');
        expect(newResponse.status, testResponse.status);
        expect(newResponse.transactionId, testResponse.transactionId);
      });

      test('should create new instance with updated transactionId', () {
        final newResponse = testResponse.copyWith(transactionId: 'new_txn_id');

        expect(newResponse.transactionId, 'new_txn_id');
        expect(newResponse.status, testResponse.status);
        expect(newResponse.message, testResponse.message);
      });

      test('should create new instance with updated provider', () {
        final newResponse =
            testResponse.copyWith(provider: PaymentProvider.paypal);

        expect(newResponse.provider, PaymentProvider.paypal);
        expect(newResponse.status, testResponse.status);
        expect(newResponse.transactionId, testResponse.transactionId);
      });

      test('should create new instance with updated amount and currency', () {
        final newResponse = testResponse.copyWith(
          amount: 3500.0,
          currency: 'EUR',
        );

        expect(newResponse.amount, 3500.0);
        expect(newResponse.currency, 'EUR');
        expect(newResponse.status, testResponse.status);
      });

      test('should return identical instance if no parameters provided', () {
        final newResponse = testResponse.copyWith();

        expect(newResponse.status, testResponse.status);
        expect(newResponse.transactionId, testResponse.transactionId);
        expect(newResponse.orderId, testResponse.orderId);
        expect(newResponse.provider, testResponse.provider);
        expect(newResponse.message, testResponse.message);
        expect(newResponse.errorCode, testResponse.errorCode);
        expect(newResponse.rawResponse, testResponse.rawResponse);
        expect(newResponse.timestamp, testResponse.timestamp);
        expect(newResponse.amount, testResponse.amount);
        expect(newResponse.currency, testResponse.currency);
        expect(newResponse.metadata, testResponse.metadata);
      });
    });

    group('JSON serialization', () {
      test('should convert to JSON correctly', () {
        final json = testResponse.toJson();

        expect(json['status'], 'success');
        expect(json['transactionId'], 'txn_123456789');
        expect(json['orderId'], 'order_12345');
        expect(json['provider'], 'stripe');
        expect(json['message'], 'Payment processed successfully');
        expect(json['errorCode'], null);
        expect(json['rawResponse'], {'id': 'pi_123', 'status': 'succeeded'});
        expect(json['timestamp'], testTimestamp.toIso8601String());
        expect(json['amount'], 2500.0);
        expect(json['currency'], 'USD');
        expect(json['metadata'], {'source': 'mobile_app'});
      });

      test('should convert from JSON correctly', () {
        final json = {
          'status': 'failure',
          'transactionId': 'txn_json',
          'orderId': 'order_json',
          'provider': 'paypal',
          'message': 'JSON failure',
          'errorCode': 'JSON_ERROR',
          'rawResponse': {'error': 'json_error'},
          'timestamp': '2025-09-14T10:30:00.000Z',
          'amount': 1500.0,
          'currency': 'GBP',
          'metadata': {'source': 'json'},
        };

        final response = PaymentResponse.fromJson(json);

        expect(response.status, PaymentStatus.failure);
        expect(response.transactionId, 'txn_json');
        expect(response.orderId, 'order_json');
        expect(response.provider, PaymentProvider.paypal);
        expect(response.message, 'JSON failure');
        expect(response.errorCode, 'JSON_ERROR');
        expect(response.rawResponse, {'error': 'json_error'});
        expect(response.timestamp, DateTime.parse('2025-09-14T10:30:00.000Z'));
        expect(response.amount, 1500.0);
        expect(response.currency, 'GBP');
        expect(response.metadata, {'source': 'json'});
      });

      test('should handle JSON with null optional fields', () {
        final json = {
          'status': 'cancelled',
          'transactionId': null,
          'orderId': null,
          'provider': null,
          'message': 'Cancelled payment',
          'errorCode': null,
          'rawResponse': null,
          'timestamp': '2025-09-14T10:30:00.000Z',
          'amount': null,
          'currency': null,
          'metadata': null,
        };

        final response = PaymentResponse.fromJson(json);

        expect(response.status, PaymentStatus.cancelled);
        expect(response.transactionId, null);
        expect(response.orderId, null);
        expect(response.provider, null);
        expect(response.message, 'Cancelled payment');
        expect(response.errorCode, null);
        expect(response.rawResponse, null);
        expect(response.amount, null);
        expect(response.currency, null);
        expect(response.metadata, null);
      });
    });

    group('equality', () {
      test('should be equal when all properties are same', () {
        final response1 = PaymentResponse(
          status: PaymentStatus.success,
          message: 'Success',
          timestamp: testTimestamp,
          transactionId: 'txn_123',
        );

        final response2 = PaymentResponse(
          status: PaymentStatus.success,
          message: 'Success',
          timestamp: testTimestamp,
          transactionId: 'txn_123',
        );

        expect(response1, response2);
      });

      test('should not be equal when properties differ', () {
        final response1 = PaymentResponse(
          status: PaymentStatus.success,
          message: 'Success',
          timestamp: testTimestamp,
        );

        final response2 = PaymentResponse(
          status: PaymentStatus.failure,
          message: 'Success',
          timestamp: testTimestamp,
        );

        expect(response1, isNot(response2));
      });

      test('should have same hashCode when equal', () {
        final response1 = PaymentResponse(
          status: PaymentStatus.success,
          message: 'Success',
          timestamp: testTimestamp,
          transactionId: 'txn_123',
        );

        final response2 = PaymentResponse(
          status: PaymentStatus.success,
          message: 'Success',
          timestamp: testTimestamp,
          transactionId: 'txn_123',
        );

        expect(response1.hashCode, response2.hashCode);
      });
    });

    group('helper getters', () {
      test('isSuccess should return true for success status', () {
        expect(testResponse.isSuccess, true);

        final failureResponse = PaymentResponse.failure(
          message: 'Failed',
          errorCode: 'ERROR',
        );
        expect(failureResponse.isSuccess, false);
      });

      test('isFailure should return true for failure status', () {
        final failureResponse = PaymentResponse.failure(
          message: 'Failed',
          errorCode: 'ERROR',
        );
        expect(failureResponse.isFailure, true);
        expect(testResponse.isFailure, false);
      });

      test('isCancelled should return true for cancelled status', () {
        final cancelledResponse = PaymentResponse.cancelled(
          message: 'Cancelled',
        );
        expect(cancelledResponse.isCancelled, true);
        expect(testResponse.isCancelled, false);
      });

      test('isPending should return true for pending status', () {
        final pendingResponse = PaymentResponse.pending(
          message: 'Pending',
        );
        expect(pendingResponse.isPending, true);
        expect(testResponse.isPending, false);
      });

      test('isTimeout should return true for timeout status', () {
        final timeoutResponse = PaymentResponse.timeout(
          message: 'Timeout',
        );
        expect(timeoutResponse.isTimeout, true);
        expect(testResponse.isTimeout, false);
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final responseString = testResponse.toString();

        expect(responseString, contains('PaymentResponse'));
        expect(responseString, contains('success'));
        expect(responseString, contains('txn_123456789'));
      });
    });
  });

  group('PaymentStatus enum', () {
    test('should have correct values', () {
      expect(PaymentStatus.values.length, 6);
      expect(PaymentStatus.values, contains(PaymentStatus.success));
      expect(PaymentStatus.values, contains(PaymentStatus.failure));
      expect(PaymentStatus.values, contains(PaymentStatus.cancelled));
      expect(PaymentStatus.values, contains(PaymentStatus.pending));
      expect(PaymentStatus.values, contains(PaymentStatus.timeout));
      expect(PaymentStatus.values, contains(PaymentStatus.unknown));
    });
  });
}
