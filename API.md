# API Documentation

This document provides detailed API reference for the `unified_payment` package.

## Table of Contents

- [Core Classes](#core-classes)
- [Models](#models)
- [Providers](#providers)
- [Widgets](#widgets)
- [Usage Examples](#usage-examples)

## Core Classes

### PaymentService

The main service class that orchestrates payment processing across different providers.

#### Methods

##### `init(PaymentConfig config)`

Initializes the payment service with the specified configuration.

```dart
await PaymentService().init(PaymentConfig(
  provider: PaymentProvider.stripe,
  apiKey: 'pk_test_...',
  environment: PaymentEnvironment.sandbox,
  backendUrl: 'https://your-backend.com/api',
));
```

**Parameters:**
- `config` (PaymentConfig): Payment provider configuration

**Throws:**
- `ArgumentError`: If configuration is invalid
- `PaymentProviderException`: If provider initialization fails

##### `pay({required BuildContext context, required PaymentRequest request, ...})`

Initiates a payment flow using WebView.

```dart
await PaymentService().pay(
  context: context,
  request: PaymentRequest(
    amount: 100.0,
    currency: 'USD',
    description: 'Test payment',
    orderId: 'order_123',
  ),
  onSuccess: (response) => print('Success: ${response.transactionId}'),
  onFailure: (response) => print('Failed: ${response.message}'),
);
```

**Parameters:**
- `context` (BuildContext): Widget context for navigation
- `request` (PaymentRequest): Payment details
- `onSuccess` (PaymentSuccessCallback?): Success callback
- `onFailure` (PaymentFailureCallback?): Failure callback
- `timeout` (Duration?): Payment timeout (default: 15 minutes)

##### `verifyPayment(String transactionId)`

Manually verifies a payment with the backend.

```dart
final response = await PaymentService().verifyPayment('txn_123');
```

**Parameters:**
- `transactionId` (String): Transaction ID to verify

**Returns:**
- `Future<PaymentResponse>`: Payment verification result

##### `createPaymentUrl(PaymentRequest request)`

Creates a payment URL without launching WebView (for custom implementations).

```dart
final urlResponse = await PaymentService().createPaymentUrl(request);
```

**Parameters:**
- `request` (PaymentRequest): Payment details

**Returns:**
- `Future<PaymentUrlResponse>`: Payment URL and metadata

#### Properties

##### `isInitialized`

Returns `true` if the service has been initialized.

```dart
if (PaymentService().isInitialized) {
  // Make payment
}
```

##### `config`

Returns the current payment configuration.

```dart
final currentProvider = PaymentService().config?.provider;
```

##### `providerType`

Returns the current payment provider type.

```dart
if (PaymentService().providerType == PaymentProvider.stripe) {
  // Stripe-specific logic
}
```

## Models

### PaymentConfig

Configuration object for payment providers.

#### Properties

```dart
PaymentConfig({
  required PaymentProvider provider,
  required String apiKey,
  required PaymentEnvironment environment,
  required String backendUrl,
  String? webhookUrl,
  Map<String, String>? customHeaders,
})
```

- `provider`: Payment provider (stripe, paypal, razorpay, paystack)
- `apiKey`: Public/publishable API key
- `environment`: sandbox or live
- `backendUrl`: Your backend API base URL
- `webhookUrl`: Optional webhook URL for notifications
- `customHeaders`: Optional custom headers for backend requests

#### Methods

##### `copyWith(...)`

Creates a copy with updated values.

```dart
final newConfig = config.copyWith(environment: PaymentEnvironment.live);
```

##### `toJson()` / `fromJson(Map<String, dynamic>)`

JSON serialization support.

```dart
final json = config.toJson();
final config = PaymentConfig.fromJson(json);
```

### PaymentRequest

Payment request details.

#### Properties

```dart
PaymentRequest({
  required double amount,
  required String currency,
  required String description,
  required String orderId,
  String? successUrl,
  String? cancelUrl,
  String? customerEmail,
  String? customerName,
  String? customerPhone,
  Map<String, dynamic>? metadata,
  String? returnUrl,
})
```

- `amount`: Payment amount in major currency units (e.g., 10.50 for $10.50)
- `currency`: ISO 4217 currency code (USD, EUR, INR, etc.)
- `description`: Human-readable payment description
- `orderId`: Unique order identifier
- `successUrl`: Custom success callback URL
- `cancelUrl`: Custom cancel callback URL
- `customerEmail`: Customer email address
- `customerName`: Customer full name
- `customerPhone`: Customer phone number
- `metadata`: Additional custom data
- `returnUrl`: Custom return URL for payment flow

#### Methods

##### `copyWith(...)`

Creates a copy with updated values.

##### `formattedAmount`

Returns formatted amount string with currency.

```dart
final request = PaymentRequest(amount: 10.50, currency: 'USD');
print(request.formattedAmount); // "USD 10.50"
```

##### `amountInMajorUnits`

Returns amount in major currency units (handles currency-specific formatting).

```dart
final amount = request.amountInMajorUnits; // 10.50 for most currencies
```

### PaymentResponse

Standardized payment response.

#### Properties

```dart
PaymentResponse({
  required PaymentStatus status,
  required String message,
  String? transactionId,
  String? orderId,
  PaymentProvider? provider,
  String? errorCode,
  Map<String, dynamic>? rawResponse,
  DateTime? timestamp,
  double? amount,
  String? currency,
  Map<String, dynamic>? metadata,
})
```

#### Factory Constructors

##### `PaymentResponse.success(...)`

Creates a successful payment response.

```dart
final response = PaymentResponse.success(
  transactionId: 'txn_123',
  message: 'Payment completed successfully',
  orderId: 'order_123',
);
```

##### `PaymentResponse.failure(...)`

Creates a failed payment response.

```dart
final response = PaymentResponse.failure(
  message: 'Payment failed',
  errorCode: 'card_declined',
);
```

##### `PaymentResponse.cancelled(...)`

Creates a cancelled payment response.

##### `PaymentResponse.pending(...)`

Creates a pending payment response.

##### `PaymentResponse.timeout(...)`

Creates a timeout payment response.

#### Helper Properties

```dart
bool get isSuccess => status == PaymentStatus.success;
bool get isFailure => status == PaymentStatus.failure;
bool get isCancelled => status == PaymentStatus.cancelled;
bool get isPending => status == PaymentStatus.pending;
bool get isTimeout => status == PaymentStatus.timeout;
```

## Providers

### BasePaymentProvider

Abstract base class for payment provider implementations.

#### Abstract Methods

```dart
Future<PaymentUrlResponse> createPaymentUrl(PaymentRequest request);
Future<PaymentResponse> verifyPayment(String transactionId);
PaymentResponse parsePaymentResponse(Map<String, dynamic> response);
List<String> get successUrlPatterns;
List<String> get cancelUrlPatterns;
List<String> get failureUrlPatterns;
```

### Provider Implementations

#### StripePaymentProvider

Stripe-specific implementation.

- Converts amounts to cents
- Handles Stripe Payment Intents
- Supports 3D Secure authentication

#### PayPalPaymentProvider

PayPal-specific implementation.

- Uses PayPal Orders API
- Handles PayPal checkout flow
- Supports PayPal and card payments

#### RazorPayPaymentProvider

RazorPay-specific implementation.

- Converts amounts to paise (Indian currency subunit)
- Handles RazorPay orders and payments
- Supports multiple payment methods

#### PaystackPaymentProvider

Paystack-specific implementation.

- Converts amounts to kobo (Nigerian currency subunit)
- Handles Paystack transactions
- Supports card and bank payments

## Widgets

### PaymentWebView

WebView widget for handling payment flows.

#### Properties

```dart
PaymentWebView({
  required String paymentUrl,
  required PaymentProvider provider,
  String? successUrlPattern,
  String? cancelUrlPattern,
  String? failureUrlPattern,
  String? orderId,
  PaymentSuccessCallback? onSuccess,
  PaymentFailureCallback? onFailure,
  PaymentCancelledCallback? onCancelled,
  Duration timeout = const Duration(minutes: 15),
  Widget? loadingWidget,
  Widget Function(String error)? errorWidgetBuilder,
})
```

#### Usage

```dart
PaymentWebView(
  paymentUrl: 'https://checkout.stripe.com/pay/cs_...',
  provider: PaymentProvider.stripe,
  orderId: 'order_123',
  onSuccess: (response) {
    // Handle success
  },
  onFailure: (response) {
    // Handle failure
  },
)
```

## Enums

### PaymentProvider

```dart
enum PaymentProvider {
  stripe,
  paypal,
  razorpay,
  paystack,
  flutterwave,
}
```

### PaymentEnvironment

```dart
enum PaymentEnvironment {
  sandbox,
  live,
}
```

### PaymentStatus

```dart
enum PaymentStatus {
  success,
  failure,
  cancelled,
  pending,
  timeout,
  unknown,
}
```

## Usage Examples

### Basic Payment Flow

```dart
// 1. Initialize service
await PaymentService().init(PaymentConfig(
  provider: PaymentProvider.stripe,
  apiKey: 'pk_test_...',
  environment: PaymentEnvironment.sandbox,
  backendUrl: 'https://api.example.com',
));

// 2. Create payment request
final request = PaymentRequest(
  amount: 29.99,
  currency: 'USD',
  description: 'Premium subscription',
  orderId: 'sub_${DateTime.now().millisecondsSinceEpoch}',
  customerEmail: 'user@example.com',
);

// 3. Make payment
await PaymentService().pay(
  context: context,
  request: request,
  onSuccess: (response) {
    print('Payment successful: ${response.transactionId}');
    // Update UI, navigate to success page, etc.
  },
  onFailure: (response) {
    print('Payment failed: ${response.message}');
    // Show error message, retry option, etc.
  },
);
```

### Switching Providers

```dart
// Switch to PayPal
await PaymentService().init(PaymentConfig(
  provider: PaymentProvider.paypal,
  apiKey: 'your-paypal-client-id',
  environment: PaymentEnvironment.sandbox,
  backendUrl: 'https://api.example.com',
));

// Same payment request works with any provider
await PaymentService().pay(
  context: context,
  request: request,
  onSuccess: onSuccess,
  onFailure: onFailure,
);
```

### Custom WebView Implementation

```dart
final urlResponse = await PaymentService().createPaymentUrl(request);

Navigator.push(context, MaterialPageRoute(
  builder: (context) => PaymentWebView(
    paymentUrl: urlResponse.paymentUrl,
    provider: PaymentProvider.stripe,
    orderId: request.orderId,
    loadingWidget: CustomLoadingWidget(),
    errorWidgetBuilder: (error) => CustomErrorWidget(error),
    onSuccess: (response) {
      // Custom success handling
    },
  ),
));
```

### Error Handling

```dart
try {
  await PaymentService().pay(
    context: context,
    request: request,
    onSuccess: (response) {
      if (response.isSuccess) {
        // Payment completed
      } else if (response.isPending) {
        // Payment needs verification
        _pollPaymentStatus(response.transactionId);
      }
    },
    onFailure: (response) {
      if (response.isCancelled) {
        // User cancelled
        showSnackBar('Payment cancelled');
      } else if (response.isTimeout) {
        // Payment timed out
        showRetryDialog();
      } else {
        // Payment failed
        showErrorDialog(response.message);
      }
    },
  );
} catch (e) {
  // Handle initialization or other errors
  showErrorDialog('Payment service error: $e');
}
```