import 'package:equatable/equatable.dart';

/// Enum for supported payment providers
enum PaymentProvider {
  stripe,
  paypal,
  razorpay,
  paystack,
  flutterwave,
}

/// Enum for payment environments
enum PaymentEnvironment {
  sandbox,
  live,
}

/// Configuration class for payment providers
class PaymentConfig extends Equatable {
  /// The payment provider to use
  final PaymentProvider provider;

  /// API key for the payment provider (public key only)
  final String apiKey;

  /// Environment (sandbox or live)
  final PaymentEnvironment environment;

  /// Backend URL for payment processing
  final String backendUrl;

  /// Optional webhook URL for payment notifications
  final String? webhookUrl;

  /// Optional custom headers for backend requests
  final Map<String, String>? customHeaders;

  const PaymentConfig({
    required this.provider,
    required this.apiKey,
    required this.environment,
    required this.backendUrl,
    this.webhookUrl,
    this.customHeaders,
  });

  /// Create a copy of this config with updated values
  PaymentConfig copyWith({
    PaymentProvider? provider,
    String? apiKey,
    PaymentEnvironment? environment,
    String? backendUrl,
    String? webhookUrl,
    Map<String, String>? customHeaders,
  }) {
    return PaymentConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      environment: environment ?? this.environment,
      backendUrl: backendUrl ?? this.backendUrl,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      customHeaders: customHeaders ?? this.customHeaders,
    );
  }

  /// Convert to JSON for backend communication
  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'apiKey': apiKey,
      'environment': environment.name,
      'backendUrl': backendUrl,
      if (webhookUrl != null) 'webhookUrl': webhookUrl,
      if (customHeaders != null) 'customHeaders': customHeaders,
    };
  }

  /// Create from JSON
  factory PaymentConfig.fromJson(Map<String, dynamic> json) {
    return PaymentConfig(
      provider: PaymentProvider.values.firstWhere(
        (e) => e.name == json['provider'],
      ),
      apiKey: json['apiKey'] as String,
      environment: PaymentEnvironment.values.firstWhere(
        (e) => e.name == json['environment'],
      ),
      backendUrl: json['backendUrl'] as String,
      webhookUrl: json['webhookUrl'] as String?,
      customHeaders: json['customHeaders'] != null
          ? Map<String, String>.from(json['customHeaders'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        provider,
        apiKey,
        environment,
        backendUrl,
        webhookUrl,
        customHeaders,
      ];

  @override
  String toString() {
    return 'PaymentConfig(provider: $provider, environment: $environment, backendUrl: $backendUrl)';
  }
}
