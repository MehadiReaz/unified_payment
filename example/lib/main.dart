import 'package:flutter/material.dart';
import 'package:unified_payment/unified_payment.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unified Payment Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PaymentDemoPage(),
    );
  }
}

class PaymentDemoPage extends StatefulWidget {
  const PaymentDemoPage({super.key});

  @override
  State<PaymentDemoPage> createState() => _PaymentDemoPageState();
}

class _PaymentDemoPageState extends State<PaymentDemoPage> {
  final PaymentService _paymentService = PaymentService();
  PaymentProvider _selectedProvider = PaymentProvider.stripe;
  PaymentEnvironment _selectedEnvironment = PaymentEnvironment.sandbox;
  String _backendUrl = 'https://your-backend.com';
  String _apiKey = 'your-api-key';

  final TextEditingController _amountController =
      TextEditingController(text: '10.00');
  final TextEditingController _currencyController =
      TextEditingController(text: 'USD');
  final TextEditingController _descriptionController =
      TextEditingController(text: 'Test Payment');
  final TextEditingController _orderIdController = TextEditingController(
      text: 'order_${DateTime.now().millisecondsSinceEpoch}');
  final TextEditingController _emailController =
      TextEditingController(text: 'test@example.com');
  final TextEditingController _nameController =
      TextEditingController(text: 'Test User');

  String _lastResult = 'No payment attempted yet';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _currencyController.dispose();
    _descriptionController.dispose();
    _orderIdController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initializePaymentService() async {
    try {
      setState(() => _isLoading = true);

      final config = PaymentConfig(
        provider: _selectedProvider,
        apiKey: _apiKey,
        environment: _selectedEnvironment,
        backendUrl: _backendUrl,
      );

      await _paymentService.init(config);

      setState(() {
        _lastResult = 'Payment service initialized successfully';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _lastResult = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _makePayment() async {
    if (!_paymentService.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please initialize payment service first')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final request = PaymentRequest(
        amount: double.parse(_amountController.text),
        currency: _currencyController.text,
        description: _descriptionController.text,
        orderId: _orderIdController.text,
        customerEmail: _emailController.text,
        customerName: _nameController.text,
      );

      await _paymentService.pay(
        context: context,
        request: request,
        onSuccess: (PaymentResponse response) {
          setState(() {
            _lastResult = 'Payment Successful!\n'
                'Transaction ID: ${response.transactionId}\n'
                'Order ID: ${response.orderId}\n'
                'Message: ${response.message}';
            _isLoading = false;
          });
          _showPaymentDialog(
              'Payment Successful', response.message, Colors.green);
        },
        onFailure: (PaymentResponse response) {
          setState(() {
            _lastResult = 'Payment Failed!\n'
                'Status: ${response.status.name}\n'
                'Message: ${response.message}\n'
                'Error Code: ${response.errorCode ?? 'N/A'}';
            _isLoading = false;
          });
          _showPaymentDialog('Payment Failed', response.message, Colors.red);
        },
      );
    } catch (e) {
      setState(() {
        _lastResult = 'Error: $e';
        _isLoading = false;
      });
      _showPaymentDialog('Error', e.toString(), Colors.red);
    }
  }

  void _showPaymentDialog(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              title.contains('Success') ? Icons.check_circle : Icons.error,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Provider Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentProvider>(
              value: _selectedProvider,
              decoration: const InputDecoration(
                labelText: 'Payment Provider',
                border: OutlineInputBorder(),
              ),
              items: PaymentProvider.values.map((provider) {
                return DropdownMenuItem(
                  value: provider,
                  child: Text(provider.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedProvider = value);
                  _updateApiKeyPlaceholder();
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentEnvironment>(
              value: _selectedEnvironment,
              decoration: const InputDecoration(
                labelText: 'Environment',
                border: OutlineInputBorder(),
              ),
              items: PaymentEnvironment.values.map((env) {
                return DropdownMenuItem(
                  value: env,
                  child: Text(env.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedEnvironment = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _backendUrl,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                border: OutlineInputBorder(),
                hintText: 'https://your-backend.com',
              ),
              onChanged: (value) => _backendUrl = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _apiKey,
              decoration: InputDecoration(
                labelText: 'API Key (Public Key)',
                border: const OutlineInputBorder(),
                hintText: _getApiKeyHint(),
              ),
              onChanged: (value) => _apiKey = value,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _initializePaymentService,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.settings),
                label: Text(_isLoading
                    ? 'Initializing...'
                    : 'Initialize Payment Service'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _currencyController,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _orderIdController,
              decoration: const InputDecoration(
                labelText: 'Order ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Customer Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading || !_paymentService.isInitialized
                    ? null
                    : _makePayment,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payment),
                label: Text(_isLoading ? 'Processing...' : 'Make Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Result',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _lastResult,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateApiKeyPlaceholder() {
    // Update API key placeholder based on selected provider
    switch (_selectedProvider) {
      case PaymentProvider.stripe:
        _apiKey = 'pk_test_...';
        break;
      case PaymentProvider.paypal:
        _apiKey = 'your-paypal-client-id';
        break;
      case PaymentProvider.razorpay:
        _apiKey = 'rzp_test_...';
        break;
      case PaymentProvider.paystack:
        _apiKey = 'pk_test_...';
        break;
      case PaymentProvider.flutterwave:
        _apiKey = 'FLWPUBK_TEST-...';
        break;
    }
  }

  String _getApiKeyHint() {
    switch (_selectedProvider) {
      case PaymentProvider.stripe:
        return 'pk_test_... (Stripe Publishable Key)';
      case PaymentProvider.paypal:
        return 'PayPal Client ID';
      case PaymentProvider.razorpay:
        return 'rzp_test_... (RazorPay Key ID)';
      case PaymentProvider.paystack:
        return 'pk_test_... (Paystack Public Key)';
      case PaymentProvider.flutterwave:
        return 'FLWPUBK_TEST-... (Flutterwave Public Key)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Unified Payment Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProviderConfig(),
            const SizedBox(height: 16),
            _buildPaymentForm(),
            const SizedBox(height: 16),
            _buildResultSection(),
          ],
        ),
      ),
    );
  }
}
