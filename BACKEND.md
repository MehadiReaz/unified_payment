# Backend Integration Guide

This guide explains how to set up your backend server to work with the `unified_payment` Flutter package.

## Table of Contents

- [Overview](#overview)
- [Required Endpoints](#required-endpoints)
- [Provider-Specific Implementation](#provider-specific-implementation)
- [Security Considerations](#security-considerations)
- [Example Implementations](#example-implementations)
- [Testing](#testing)

## Overview

The `unified_payment` package follows a **backend-first approach** for security. Your Flutter app communicates with your backend, which then interacts with payment providers using secret keys.

### Flow Diagram

```
Flutter App → Your Backend → Payment Provider → Payment Page
                ↓
Flutter App ← Your Backend ← Payment Provider ← User completes payment
```

### Benefits

- **Security**: Secret keys never leave your server
- **Flexibility**: Easy to add new providers or modify payment logic
- **Compliance**: Better PCI DSS compliance
- **Analytics**: Centralized payment tracking and logging

## Required Endpoints

Your backend must implement these two endpoints:

### 1. Create Payment (`POST /api/payments/create`)

Creates a payment session and returns a payment URL for the Flutter app to load in WebView.

#### Request Format

```json
{
  "provider": "stripe|paypal|razorpay|paystack",
  "amount": 1000,
  "currency": "USD",
  "description": "Product purchase",
  "order_id": "order_123",
  "customer_email": "user@example.com",
  "customer_name": "John Doe",
  "customer_phone": "+1234567890",
  "api_key": "pk_test_...",
  "environment": "sandbox|live",
  "success_url": "https://yourapp.com/success",
  "cancel_url": "https://yourapp.com/cancel",
  "metadata": {
    "user_id": "user_123",
    "subscription_id": "sub_456"
  }
}
```

#### Response Format

```json
{
  "success": true,
  "payment_url": "https://checkout.stripe.com/pay/cs_...",
  "client_secret": "pi_123_secret_456",
  "transaction_id": "txn_789",
  "metadata": {
    "session_id": "cs_123",
    "expires_at": "2023-12-31T23:59:59Z"
  }
}
```

### 2. Verify Payment (`GET /api/payments/verify/{transactionId}`)

Verifies payment status with the payment provider.

#### Response Format

```json
{
  "success": true,
  "status": "success|failed|pending|cancelled",
  "transaction_id": "txn_789",
  "order_id": "order_123",
  "amount": 1000,
  "currency": "USD",
  "provider": "stripe",
  "provider_response": {
    "payment_intent_id": "pi_123",
    "charges": [...],
    "metadata": {...}
  },
  "created_at": "2023-12-31T10:00:00Z",
  "updated_at": "2023-12-31T10:05:00Z"
}
```

## Provider-Specific Implementation

### Stripe

#### Dependencies
```bash
npm install stripe  # Node.js
pip install stripe  # Python
composer require stripe/stripe-php  # PHP
```

#### Create Payment

```javascript
// Node.js/Express example
app.post('/api/payments/create', async (req, res) => {
  const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
  
  const { amount, currency, order_id, customer_email } = req.body;
  
  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount * 100, // Convert to cents
      currency: currency.toLowerCase(),
      metadata: { order_id },
      receipt_email: customer_email,
    });
    
    const session = await stripe.checkout.sessions.create({
      payment_intent_data: {
        id: paymentIntent.id,
      },
      line_items: [{
        price_data: {
          currency: currency.toLowerCase(),
          product_data: { name: req.body.description },
          unit_amount: amount * 100,
        },
        quantity: 1,
      }],
      mode: 'payment',
      success_url: req.body.success_url,
      cancel_url: req.body.cancel_url,
    });
    
    res.json({
      success: true,
      payment_url: session.url,
      client_secret: paymentIntent.client_secret,
      transaction_id: paymentIntent.id,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});
```

#### Verify Payment

```javascript
app.get('/api/payments/verify/:transactionId', async (req, res) => {
  const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
  
  try {
    const paymentIntent = await stripe.paymentIntents.retrieve(
      req.params.transactionId
    );
    
    res.json({
      success: true,
      status: paymentIntent.status === 'succeeded' ? 'success' : 'failed',
      transaction_id: paymentIntent.id,
      amount: paymentIntent.amount / 100,
      currency: paymentIntent.currency.toUpperCase(),
      provider: 'stripe',
      provider_response: paymentIntent,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});
```

### PayPal

#### Dependencies
```bash
npm install @paypal/checkout-server-sdk  # Node.js
```

#### Create Payment

```javascript
const paypal = require('@paypal/checkout-server-sdk');

// Configure PayPal environment
const environment = process.env.NODE_ENV === 'production'
  ? new paypal.core.LiveEnvironment(process.env.PAYPAL_CLIENT_ID, process.env.PAYPAL_CLIENT_SECRET)
  : new paypal.core.SandboxEnvironment(process.env.PAYPAL_CLIENT_ID, process.env.PAYPAL_CLIENT_SECRET);

const client = new paypal.core.PayPalHttpClient(environment);

app.post('/api/payments/create', async (req, res) => {
  const { amount, currency, order_id, description, success_url, cancel_url } = req.body;
  
  const request = new paypal.orders.OrdersCreateRequest();
  request.prefer("return=representation");
  request.requestBody({
    intent: 'CAPTURE',
    purchase_units: [{
      reference_id: order_id,
      amount: {
        currency_code: currency.toUpperCase(),
        value: amount.toString(),
      },
      description: description,
    }],
    application_context: {
      return_url: success_url,
      cancel_url: cancel_url,
      user_action: 'PAY_NOW',
    },
  });
  
  try {
    const order = await client.execute(request);
    const approvalUrl = order.result.links.find(
      link => link.rel === 'approve'
    ).href;
    
    res.json({
      success: true,
      payment_url: approvalUrl,
      transaction_id: order.result.id,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});
```

### RazorPay

#### Dependencies
```bash
npm install razorpay  # Node.js
pip install razorpay  # Python
```

#### Create Payment

```javascript
const Razorpay = require('razorpay');

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

app.post('/api/payments/create', async (req, res) => {
  const { amount, currency, order_id, customer_email, customer_name } = req.body;
  
  try {
    const order = await razorpay.orders.create({
      amount: amount * 100, // Convert to paise
      currency: currency.toUpperCase(),
      receipt: order_id,
      notes: {
        customer_email,
        customer_name,
      },
    });
    
    // Create payment link
    const paymentLink = await razorpay.paymentLink.create({
      amount: amount * 100,
      currency: currency.toUpperCase(),
      description: req.body.description,
      customer: {
        name: customer_name,
        email: customer_email,
      },
      callback_url: req.body.success_url,
      callback_method: 'get',
    });
    
    res.json({
      success: true,
      payment_url: paymentLink.short_url,
      transaction_id: order.id,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});
```

### Paystack

#### Dependencies
```bash
npm install paystack  # Node.js
```

#### Create Payment

```javascript
const paystack = require('paystack')(process.env.PAYSTACK_SECRET_KEY);

app.post('/api/payments/create', async (req, res) => {
  const { amount, currency, order_id, customer_email, success_url, cancel_url } = req.body;
  
  try {
    const transaction = await paystack.transaction.initialize({
      email: customer_email,
      amount: amount * 100, // Convert to kobo
      currency: currency.toUpperCase(),
      reference: order_id,
      callback_url: success_url,
      metadata: {
        cancel_action: cancel_url,
      },
    });
    
    res.json({
      success: true,
      payment_url: transaction.data.authorization_url,
      transaction_id: transaction.data.reference,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});
```

## Security Considerations

### 1. API Key Validation

Always validate the API key sent from the Flutter app:

```javascript
app.post('/api/payments/create', (req, res) => {
  const { api_key, environment } = req.body;
  
  // Validate API key format
  if (environment === 'sandbox' && !api_key.startsWith('pk_test_')) {
    return res.status(400).json({
      success: false,
      error: 'Invalid sandbox API key',
    });
  }
  
  // You might also want to validate against a whitelist
  const allowedKeys = process.env.ALLOWED_API_KEYS?.split(',') || [];
  if (!allowedKeys.includes(api_key)) {
    return res.status(403).json({
      success: false,
      error: 'Unauthorized API key',
    });
  }
  
  // Proceed with payment creation...
});
```

### 2. Rate Limiting

Implement rate limiting to prevent abuse:

```javascript
const rateLimit = require('express-rate-limit');

const paymentLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Limit each IP to 10 requests per windowMs
  message: 'Too many payment requests, please try again later.',
});

app.use('/api/payments', paymentLimiter);
```

### 3. Input Validation

Always validate and sanitize input:

```javascript
const { body, validationResult } = require('express-validator');

const validatePaymentRequest = [
  body('amount').isFloat({ min: 0.01 }).withMessage('Amount must be positive'),
  body('currency').isLength({ min: 3, max: 3 }).withMessage('Invalid currency'),
  body('order_id').isLength({ min: 1, max: 100 }).withMessage('Order ID required'),
  body('customer_email').isEmail().withMessage('Valid email required'),
  // Add more validations...
];

app.post('/api/payments/create', validatePaymentRequest, (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array(),
    });
  }
  
  // Process payment...
});
```

### 4. HTTPS Only

Ensure all payment endpoints use HTTPS:

```javascript
app.use('/api/payments', (req, res, next) => {
  if (!req.secure && req.get('X-Forwarded-Proto') !== 'https') {
    return res.status(400).json({
      success: false,
      error: 'HTTPS required for payment endpoints',
    });
  }
  next();
});
```

### 5. Webhook Verification

Implement webhook endpoints for reliable payment status updates:

```javascript
// Stripe webhook
app.post('/webhooks/stripe', express.raw({ type: 'application/json' }), (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;
  
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    console.log(`Webhook signature verification failed.`, err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }
  
  if (event.type === 'payment_intent.succeeded') {
    const paymentIntent = event.data.object;
    // Update your database with successful payment
    updatePaymentStatus(paymentIntent.id, 'success');
  }
  
  res.json({ received: true });
});
```

## Testing

### Test Environment Setup

1. Use provider sandbox/test environments
2. Set up test API keys
3. Configure test webhooks

### Test Cases

Create automated tests for:

```javascript
// Jest example
describe('Payment API', () => {
  test('creates Stripe payment successfully', async () => {
    const response = await request(app)
      .post('/api/payments/create')
      .send({
        provider: 'stripe',
        amount: 10.00,
        currency: 'USD',
        order_id: 'test_order_123',
        api_key: 'pk_test_123',
        environment: 'sandbox',
      });
    
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.payment_url).toContain('checkout.stripe.com');
  });
  
  test('verifies payment status', async () => {
    const response = await request(app)
      .get('/api/payments/verify/pi_test_123');
    
    expect(response.status).toBe(200);
    expect(response.body.status).toBeDefined();
  });
  
  test('handles invalid API keys', async () => {
    const response = await request(app)
      .post('/api/payments/create')
      .send({
        api_key: 'invalid_key',
        // ... other fields
      });
    
    expect(response.status).toBe(403);
    expect(response.body.success).toBe(false);
  });
});
```

### Load Testing

Test your endpoints under load:

```bash
# Using Apache Bench
ab -n 1000 -c 10 -H "Content-Type: application/json" -p payment_request.json http://localhost:3000/api/payments/create

# Using Artillery
artillery quick --count 50 --num 10 http://localhost:3000/api/payments/create
```

## Error Handling

Implement consistent error responses:

```javascript
const handleError = (error, provider) => {
  console.error(`${provider} Error:`, error);
  
  // Map provider-specific errors to consistent format
  let errorMessage = 'Payment processing failed';
  let errorCode = 'payment_error';
  
  if (provider === 'stripe') {
    errorMessage = error.message;
    errorCode = error.code;
  } else if (provider === 'paypal') {
    errorMessage = error.details?.[0]?.description || error.message;
    errorCode = error.name;
  }
  // Add more provider mappings...
  
  return {
    success: false,
    error: errorMessage,
    error_code: errorCode,
    provider: provider,
  };
};
```

## Monitoring and Logging

Implement comprehensive logging:

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'payment_error.log', level: 'error' }),
    new winston.transports.File({ filename: 'payment_combined.log' }),
  ],
});

app.post('/api/payments/create', async (req, res) => {
  const startTime = Date.now();
  
  try {
    logger.info('Payment request received', {
      provider: req.body.provider,
      amount: req.body.amount,
      order_id: req.body.order_id,
      ip: req.ip,
    });
    
    // Process payment...
    
    logger.info('Payment created successfully', {
      provider: req.body.provider,
      transaction_id: result.transaction_id,
      duration: Date.now() - startTime,
    });
  } catch (error) {
    logger.error('Payment creation failed', {
      provider: req.body.provider,
      error: error.message,
      duration: Date.now() - startTime,
    });
  }
});
```

This backend integration guide provides the foundation for implementing a secure, scalable payment processing backend that works seamlessly with the `unified_payment` Flutter package.