import 'package:equatable/equatable.dart';

/// Payment request model containing all necessary payment information
class PaymentRequest extends Equatable {
  /// Payment amount (in the smallest currency unit, e.g., cents for USD)
  final double amount;

  /// Currency code (ISO 4217, e.g., 'USD', 'EUR', 'INR')
  final String currency;

  /// Human-readable description of the payment
  final String description;

  /// Unique order/transaction identifier
  final String orderId;

  /// Callback URL for successful payments
  final String? successUrl;

  /// Callback URL for cancelled payments
  final String? cancelUrl;

  /// Customer email (optional but recommended)
  final String? customerEmail;

  /// Customer name (optional)
  final String? customerName;

  /// Customer phone number (optional)
  final String? customerPhone;

  /// Additional metadata for the payment
  final Map<String, dynamic>? metadata;

  /// Custom return URL for the payment flow
  final String? returnUrl;

  const PaymentRequest({
    required this.amount,
    required this.currency,
    required this.description,
    required this.orderId,
    this.successUrl,
    this.cancelUrl,
    this.customerEmail,
    this.customerName,
    this.customerPhone,
    this.metadata,
    this.returnUrl,
  });

  /// Create a copy of this request with updated values
  PaymentRequest copyWith({
    double? amount,
    String? currency,
    String? description,
    String? orderId,
    String? successUrl,
    String? cancelUrl,
    String? customerEmail,
    String? customerName,
    String? customerPhone,
    Map<String, dynamic>? metadata,
    String? returnUrl,
  }) {
    return PaymentRequest(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      orderId: orderId ?? this.orderId,
      successUrl: successUrl ?? this.successUrl,
      cancelUrl: cancelUrl ?? this.cancelUrl,
      customerEmail: customerEmail ?? this.customerEmail,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      metadata: metadata ?? this.metadata,
      returnUrl: returnUrl ?? this.returnUrl,
    );
  }

  /// Convert to JSON for backend communication
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'description': description,
      'orderId': orderId,
      if (successUrl != null) 'successUrl': successUrl,
      if (cancelUrl != null) 'cancelUrl': cancelUrl,
      if (customerEmail != null) 'customerEmail': customerEmail,
      if (customerName != null) 'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (metadata != null) 'metadata': metadata,
      if (returnUrl != null) 'returnUrl': returnUrl,
    };
  }

  /// Create from JSON
  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      description: json['description'] as String,
      orderId: json['orderId'] as String,
      successUrl: json['successUrl'] as String?,
      cancelUrl: json['cancelUrl'] as String?,
      customerEmail: json['customerEmail'] as String?,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      returnUrl: json['returnUrl'] as String?,
    );
  }

  /// Format amount as string with currency symbol
  String get formattedAmount {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Get amount in major currency units (e.g., dollars instead of cents)
  double get amountInMajorUnits {
    // Most currencies use 2 decimal places, but some exceptions exist
    switch (currency.toUpperCase()) {
      case 'JPY':
      case 'KRW':
        return amount; // No decimal places
      default:
        return amount / 100; // Standard currencies with 2 decimal places
    }
  }

  @override
  List<Object?> get props => [
        amount,
        currency,
        description,
        orderId,
        successUrl,
        cancelUrl,
        customerEmail,
        customerName,
        customerPhone,
        metadata,
        returnUrl,
      ];

  @override
  String toString() {
    return 'PaymentRequest(orderId: $orderId, amount: $formattedAmount, description: $description)';
  }
}
