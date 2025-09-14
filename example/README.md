# Unified Payment Example

This example demonstrates how to use the `unified_payment` package in a Flutter application.

## Features Demonstrated

- Payment provider configuration (Stripe, PayPal, RazorPay, Paystack)
- Environment switching (sandbox/live)
- Payment processing with WebView
- Success/failure handling
- Payment verification

## Setup Instructions

### 1. Backend Requirements

Before running this example, you need a backend server that provides these endpoints:

```
POST /api/payments/create
GET  /api/payments/verify/{transactionId}
```

#### Create Payment Endpoint (`POST /api/payments/create`)

**Request Body:**
```json
{
  "provider": "stripe|paypal|razorpay|paystack",
  "amount": 1000,
  "currency": "USD",
  "description": "Test payment",
  "order_id": "order_123",
  "customer_email": "test@example.com",
  "api_key": "your-public-key",
  "environment": "sandbox|live"
}
```

**Response:**
```json
{
  "payment_url": "https://payment-provider.com/pay/session_123",
  "client_secret": "pi_123_secret_456",
  "transaction_id": "txn_789"
}
```

#### Verify Payment Endpoint (`GET /api/payments/verify/{transactionId}`)

**Response:**
```json
{
  "status": "success|failed|pending",
  "transaction_id": "txn_789",
  "order_id": "order_123",
  "amount": 1000,
  "currency": "USD"
}
```

### 2. Provider Setup

#### Stripe
1. Create a Stripe account
2. Get your publishable key (`pk_test_...` for sandbox)
3. Set up webhook endpoints for payment confirmation

#### PayPal  
1. Create a PayPal developer account
2. Create an app to get Client ID
3. Configure return URLs

#### RazorPay
1. Create a RazorPay account
2. Get your Key ID (`rzp_test_...` for sandbox)
3. Set up webhooks

#### Paystack
1. Create a Paystack account
2. Get your public key (`pk_test_...` for sandbox)
3. Configure callback URLs

### 3. Running the Example

1. Update the backend URL in the app
2. Enter your provider API keys
3. Initialize the payment service  
4. Fill in payment details
5. Tap "Make Payment" to test

## Code Structure

```
lib/
├── main.dart           # Main app and payment demo
```

The example shows:

- **Provider Configuration**: How to set up different payment providers
- **Payment Flow**: Complete payment process from initialization to completion
- **Error Handling**: Proper handling of payment failures and errors
- **UI Integration**: How to integrate payment flows into your app

## Backend Implementation Examples

See the `/backend_examples` directory for sample backend implementations in:
- Node.js/Express
- Python/Flask
- PHP/Laravel

## Security Notes

⚠️ **Important Security Considerations:**

1. **Never store secret keys in your Flutter app** - only use publishable/public keys
2. **Always verify payments on your backend** - never trust client-side payment confirmations
3. **Use webhooks** for reliable payment status updates
4. **Implement proper authentication** for your backend endpoints
5. **Use HTTPS** for all payment-related communications

## Testing

Use these test credentials for different providers:

### Stripe Test Cards
- Success: `4242424242424242`
- Decline: `4000000000000002`
- Insufficient funds: `4000000000009995`

### PayPal Sandbox
- Use PayPal sandbox buyer accounts for testing

### RazorPay Test Cards
- Success: `4111111111111111`
- Failure: `4000300011112220`

### Paystack Test Cards  
- Success: `4084084084084081`
- Insufficient funds: `5060666666666666666`

## Troubleshooting

### Common Issues

1. **"PaymentService not initialized"**
   - Make sure to call `PaymentService().init(config)` before making payments

2. **WebView not loading**
   - Check that your backend URL is accessible
   - Verify SSL certificates for HTTPS endpoints

3. **Payment verification fails**
   - Ensure your backend verify endpoint is working
   - Check transaction ID format matches provider requirements

4. **Callback URLs not working**
   - Verify callback URLs are properly configured in provider dashboards
   - Check URL patterns in provider configurations

For more help, check the main package documentation or create an issue on GitHub.