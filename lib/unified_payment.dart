/// A Flutter package that provides a unified API for multiple payment providers
/// using a WebView-first approach.
///
/// Supported payment providers:
/// - Stripe
/// - PayPal
/// - RazorPay
/// - Paystack
/// - Flutterwave (coming soon)
///
/// This package enables easy switching between payment providers with minimal
/// code changes and provides standardized responses across all providers.
library unified_payment;

// Export core models
export 'models/payment_config.dart';
export 'models/payment_request.dart';
export 'models/payment_response.dart';

// Export main service
export 'payment_service.dart';

// Export widgets (for custom implementations) - hide duplicate types
export 'widgets/payment_webview.dart'
    hide
        PaymentSuccessCallback,
        PaymentFailureCallback,
        PaymentCancelledCallback;

// Export providers (for advanced usage)
export 'providers/base_provider.dart';
export 'providers/stripe_provider.dart';
export 'providers/paypal_provider.dart';
export 'providers/razorpay_provider.dart';
export 'providers/paystack_provider.dart';

// Export common types
export 'models/payment_config.dart' show PaymentProvider, PaymentEnvironment;
export 'models/payment_response.dart' show PaymentStatus;
export 'payment_service.dart'
    show PaymentSuccessCallback, PaymentFailureCallback;
