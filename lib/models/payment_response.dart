import 'package:equatable/equatable.dart';
import 'payment_config.dart';

/// Enum for payment status
enum PaymentStatus {
  success,
  failure,
  cancelled,
  pending,
  timeout,
  unknown,
}

/// Standardized payment response model
class PaymentResponse extends Equatable {
  /// Status of the payment
  final PaymentStatus status;

  /// Unique transaction ID from the payment provider
  final String? transactionId;

  /// Order ID from the original request
  final String? orderId;

  /// Payment provider that processed the payment
  final PaymentProvider? provider;

  /// Human-readable message describing the result
  final String message;

  /// Error code if payment failed
  final String? errorCode;

  /// Raw response from the payment provider (for debugging)
  final Map<String, dynamic>? rawResponse;

  /// Timestamp when the response was created
  final DateTime timestamp;

  /// Amount that was processed (if available)
  final double? amount;

  /// Currency used for the payment
  final String? currency;

  /// Additional metadata from the payment provider
  final Map<String, dynamic>? metadata;

  PaymentResponse({
    required this.status,
    required this.message,
    this.transactionId,
    this.orderId,
    this.provider,
    this.errorCode,
    this.rawResponse,
    DateTime? timestamp,
    this.amount,
    this.currency,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a successful payment response
  factory PaymentResponse.success({
    required String transactionId,
    required String message,
    String? orderId,
    PaymentProvider? provider,
    double? amount,
    String? currency,
    Map<String, dynamic>? rawResponse,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResponse(
      status: PaymentStatus.success,
      transactionId: transactionId,
      orderId: orderId,
      provider: provider,
      message: message,
      amount: amount,
      currency: currency,
      rawResponse: rawResponse,
      metadata: metadata,
    );
  }

  /// Create a failed payment response
  factory PaymentResponse.failure({
    required String message,
    String? errorCode,
    String? orderId,
    PaymentProvider? provider,
    Map<String, dynamic>? rawResponse,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResponse(
      status: PaymentStatus.failure,
      message: message,
      errorCode: errorCode,
      orderId: orderId,
      provider: provider,
      rawResponse: rawResponse,
      metadata: metadata,
    );
  }

  /// Create a cancelled payment response
  factory PaymentResponse.cancelled({
    required String message,
    String? orderId,
    PaymentProvider? provider,
    Map<String, dynamic>? rawResponse,
  }) {
    return PaymentResponse(
      status: PaymentStatus.cancelled,
      message: message,
      orderId: orderId,
      provider: provider,
      rawResponse: rawResponse,
    );
  }

  /// Create a pending payment response
  factory PaymentResponse.pending({
    required String message,
    String? transactionId,
    String? orderId,
    PaymentProvider? provider,
    Map<String, dynamic>? rawResponse,
  }) {
    return PaymentResponse(
      status: PaymentStatus.pending,
      transactionId: transactionId,
      orderId: orderId,
      provider: provider,
      message: message,
      rawResponse: rawResponse,
    );
  }

  /// Create a timeout payment response
  factory PaymentResponse.timeout({
    required String message,
    String? orderId,
    PaymentProvider? provider,
  }) {
    return PaymentResponse(
      status: PaymentStatus.timeout,
      message: message,
      orderId: orderId,
      provider: provider,
    );
  }

  /// Create an unknown status payment response
  factory PaymentResponse.unknown({
    required String message,
    String? orderId,
    PaymentProvider? provider,
    Map<String, dynamic>? rawResponse,
  }) {
    return PaymentResponse(
      status: PaymentStatus.unknown,
      message: message,
      orderId: orderId,
      provider: provider,
      rawResponse: rawResponse,
    );
  }

  /// Check if payment was successful
  bool get isSuccess => status == PaymentStatus.success;

  /// Check if payment failed
  bool get isFailure => status == PaymentStatus.failure;

  /// Check if payment was cancelled
  bool get isCancelled => status == PaymentStatus.cancelled;

  /// Check if payment is pending
  bool get isPending => status == PaymentStatus.pending;

  /// Check if payment timed out
  bool get isTimeout => status == PaymentStatus.timeout;

  /// Create a copy of this response with updated values
  PaymentResponse copyWith({
    PaymentStatus? status,
    String? transactionId,
    String? orderId,
    PaymentProvider? provider,
    String? message,
    String? errorCode,
    Map<String, dynamic>? rawResponse,
    DateTime? timestamp,
    double? amount,
    String? currency,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResponse(
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      orderId: orderId ?? this.orderId,
      provider: provider ?? this.provider,
      message: message ?? this.message,
      errorCode: errorCode ?? this.errorCode,
      rawResponse: rawResponse ?? this.rawResponse,
      timestamp: timestamp ?? this.timestamp,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'transactionId': transactionId,
      'orderId': orderId,
      'provider': provider?.name,
      'message': message,
      'errorCode': errorCode,
      'rawResponse': rawResponse,
      'timestamp': timestamp.toIso8601String(),
      'amount': amount,
      'currency': currency,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.unknown,
      ),
      transactionId: json['transactionId'] as String?,
      orderId: json['orderId'] as String?,
      provider: json['provider'] != null
          ? PaymentProvider.values.firstWhere(
              (e) => e.name == json['provider'],
            )
          : null,
      message: json['message'] as String,
      errorCode: json['errorCode'] as String?,
      rawResponse: json['rawResponse'] != null
          ? Map<String, dynamic>.from(json['rawResponse'])
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      amount: json['amount']?.toDouble(),
      currency: json['currency'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        status,
        transactionId,
        orderId,
        provider,
        message,
        errorCode,
        rawResponse,
        timestamp,
        amount,
        currency,
        metadata,
      ];

  @override
  String toString() {
    return 'PaymentResponse(status: $status, transactionId: $transactionId, message: $message)';
  }
}
