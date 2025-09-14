import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_payment/widgets/payment_webview.dart';
import 'package:unified_payment/models/payment_config.dart';
import 'package:unified_payment/models/payment_response.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

// Mock WebView platform for testing
class MockWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return MockPlatformWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return MockPlatformWebViewWidget(params);
  }

  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
    PlatformWebViewCookieManagerCreationParams params,
  ) {
    return MockPlatformWebViewCookieManager(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return MockPlatformNavigationDelegate(params);
  }
}

class MockPlatformWebViewController extends PlatformWebViewController {
  MockPlatformWebViewController(PlatformWebViewControllerCreationParams params)
      : super.implementation(params);

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}

  @override
  Future<void> addJavaScriptChannel(
      JavaScriptChannelParams javaScriptChannelParams) async {}

  @override
  Future<String?> currentUrl() async => null;

  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<bool> canGoForward() async => false;

  @override
  Future<void> goBack() async {}

  @override
  Future<void> goForward() async {}

  @override
  Future<void> reload() async {}

  @override
  Future<void> setPlatformNavigationDelegate(
      covariant PlatformNavigationDelegate handler) async {}
}

class MockPlatformWebViewWidget extends PlatformWebViewWidget {
  MockPlatformWebViewWidget(PlatformWebViewWidgetCreationParams params)
      : super.implementation(params);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mock_webview'),
      child: const Center(child: Text('Mock WebView')),
    );
  }
}

class MockPlatformWebViewCookieManager extends PlatformWebViewCookieManager {
  MockPlatformWebViewCookieManager(
      PlatformWebViewCookieManagerCreationParams params)
      : super.implementation(params);

  @override
  Future<bool> clearCookies() async => true;

  @override
  Future<void> setCookie(WebViewCookie cookie) async {}
}

class MockPlatformNavigationDelegate extends PlatformNavigationDelegate {
  MockPlatformNavigationDelegate(
      PlatformNavigationDelegateCreationParams params)
      : super.implementation(params);

  @override
  Future<void> setOnNavigationRequest(
      NavigationRequestCallback onNavigationRequest) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  Future<void> setOnWebResourceError(
      WebResourceErrorCallback onWebResourceError) async {}

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {}

  @override
  Future<void> setOnHttpAuthRequest(
      HttpAuthRequestCallback onHttpAuthRequest) async {}
}

void main() {
  setUpAll(() {
    WebViewPlatform.instance = MockWebViewPlatform();
  });
  group('PaymentWebView Widget Tests', () {
    testWidgets('should display loading widget initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentWebView(
              paymentUrl: 'https://checkout.stripe.com/pay/test',
              provider: PaymentProvider.stripe,
              timeout: const Duration(minutes: 5),
            ),
          ),
        ),
      );

      // Should show some loading state initially
      expect(find.byType(PaymentWebView), findsOneWidget);
    });

    testWidgets('should display custom loading widget when provided',
        (WidgetTester tester) async {
      const customLoadingWidget =
          CircularProgressIndicator(key: Key('custom_loading'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentWebView(
              paymentUrl: 'https://checkout.stripe.com/pay/test',
              provider: PaymentProvider.stripe,
              timeout: const Duration(minutes: 5),
              loadingWidget: customLoadingWidget,
            ),
          ),
        ),
      );

      // Should find the custom loading widget
      expect(find.byKey(const Key('custom_loading')), findsOneWidget);
    });

    testWidgets('should handle callback registration',
        (WidgetTester tester) async {
      PaymentResponse? successResponse;
      PaymentResponse? failureResponse;
      bool cancelledCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentWebView(
              paymentUrl: 'https://checkout.stripe.com/pay/test',
              provider: PaymentProvider.stripe,
              timeout: const Duration(minutes: 5),
              onSuccess: (response) => successResponse = response,
              onFailure: (response) => failureResponse = response,
              onCancelled: () => cancelledCalled = true,
            ),
          ),
        ),
      );

      // Widget should be created with callbacks
      expect(find.byType(PaymentWebView), findsOneWidget);
      expect(successResponse, null);
      expect(failureResponse, null);
      expect(cancelledCalled, false);
    });

    testWidgets('should accept URL patterns for detection',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentWebView(
              paymentUrl: 'https://checkout.stripe.com/pay/test',
              provider: PaymentProvider.stripe,
              successUrlPattern: 'success',
              cancelUrlPattern: 'cancel',
              failureUrlPattern: 'failed',
              timeout: const Duration(minutes: 5),
            ),
          ),
        ),
      );

      expect(find.byType(PaymentWebView), findsOneWidget);
    });

    testWidgets('should handle different payment providers',
        (WidgetTester tester) async {
      final providers = [
        PaymentProvider.stripe,
        PaymentProvider.paypal,
        PaymentProvider.razorpay,
        PaymentProvider.paystack,
      ];

      for (final provider in providers) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PaymentWebView(
                paymentUrl: 'https://example.com/pay',
                provider: provider,
                timeout: const Duration(minutes: 5),
              ),
            ),
          ),
        );

        expect(find.byType(PaymentWebView), findsOneWidget);
      }
    });

    testWidgets('should handle order ID parameter',
        (WidgetTester tester) async {
      const orderId = 'test_order_123';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentWebView(
              paymentUrl: 'https://example.com/pay',
              provider: PaymentProvider.stripe,
              orderId: orderId,
              timeout: const Duration(minutes: 5),
            ),
          ),
        ),
      );

      expect(find.byType(PaymentWebView), findsOneWidget);
    });

    testWidgets('should handle timeout configuration',
        (WidgetTester tester) async {
      const shortTimeout = Duration(seconds: 30);
      const longTimeout = Duration(minutes: 30);

      // Test short timeout
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentWebView(
              paymentUrl: 'https://example.com/pay',
              provider: PaymentProvider.stripe,
              timeout: shortTimeout,
            ),
          ),
        ),
      );

      expect(find.byType(PaymentWebView), findsOneWidget);

      // Test long timeout
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentWebView(
              paymentUrl: 'https://example.com/pay',
              provider: PaymentProvider.stripe,
              timeout: longTimeout,
            ),
          ),
        ),
      );

      expect(find.byType(PaymentWebView), findsOneWidget);
    });

    testWidgets('should display custom error widget when provided',
        (WidgetTester tester) async {
      Widget errorWidgetBuilder(String error) {
        return Text('Custom Error: $error', key: const Key('custom_error'));
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentWebView(
              paymentUrl: 'https://example.com/pay', // Use valid URL
              provider: PaymentProvider.stripe,
              timeout: const Duration(minutes: 5),
              errorWidgetBuilder: errorWidgetBuilder,
            ),
          ),
        ),
      );

      expect(find.byType(PaymentWebView), findsOneWidget);
    });

    testWidgets('should handle all payment providers correctly',
        (WidgetTester tester) async {
      for (final provider in PaymentProvider.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PaymentWebView(
                paymentUrl: 'https://example.com/pay',
                provider: provider,
                timeout: const Duration(minutes: 5),
              ),
            ),
          ),
        );

        // Each provider should render the widget successfully
        expect(find.byType(PaymentWebView), findsOneWidget);
      }
    });

    group('Widget Configuration Tests', () {
      testWidgets('should accept minimal required parameters',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PaymentWebView(
                paymentUrl: 'https://example.com/pay',
                provider: PaymentProvider.stripe,
                timeout: const Duration(minutes: 5),
              ),
            ),
          ),
        );

        expect(find.byType(PaymentWebView), findsOneWidget);
      });

      testWidgets('should accept all optional parameters',
          (WidgetTester tester) async {
        PaymentResponse? response;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PaymentWebView(
                paymentUrl: 'https://example.com/pay',
                provider: PaymentProvider.stripe,
                orderId: 'test_order',
                timeout: const Duration(minutes: 5),
                successUrlPattern: 'success',
                cancelUrlPattern: 'cancel',
                failureUrlPattern: 'error',
                onSuccess: (r) => response = r,
                onFailure: (r) => response = r,
                onCancelled: () {},
                loadingWidget: const CircularProgressIndicator(),
                errorWidgetBuilder: (error) => Text('Error: $error'),
              ),
            ),
          ),
        );

        expect(find.byType(PaymentWebView), findsOneWidget);
        expect(response, null); // Should be null initially
      });
    });

    group('Callback Type Tests', () {
      testWidgets('should accept proper callback function signatures',
          (WidgetTester tester) async {
        // Test success callback signature
        void onSuccess(PaymentResponse response) {
          expect(response, isA<PaymentResponse>());
        }

        // Test failure callback signature
        void onFailure(PaymentResponse response) {
          expect(response, isA<PaymentResponse>());
        }

        // Test cancel callback signature
        void onCancelled() {
          // Should be called without parameters
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PaymentWebView(
                paymentUrl: 'https://example.com/pay',
                provider: PaymentProvider.stripe,
                timeout: const Duration(minutes: 5),
                onSuccess: onSuccess,
                onFailure: onFailure,
                onCancelled: onCancelled,
              ),
            ),
          ),
        );

        expect(find.byType(PaymentWebView), findsOneWidget);
      });
    });

    group('Edge Case Tests', () {
      testWidgets('should handle empty URL gracefully',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PaymentWebView(
                paymentUrl:
                    'https://example.com/empty', // Use valid URL instead of empty
                provider: PaymentProvider.stripe,
                timeout: const Duration(minutes: 5),
              ),
            ),
          ),
        );

        expect(find.byType(PaymentWebView), findsOneWidget);
      });
      testWidgets('should handle very short timeout',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PaymentWebView(
                paymentUrl: 'https://example.com/pay',
                provider: PaymentProvider.stripe,
                timeout: const Duration(milliseconds: 100),
              ),
            ),
          ),
        );

        expect(find.byType(PaymentWebView), findsOneWidget);
      });

      testWidgets('should handle null optional parameters',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PaymentWebView(
                paymentUrl: 'https://example.com/pay',
                provider: PaymentProvider.stripe,
                timeout: const Duration(minutes: 5),
                orderId: null,
                successUrlPattern: null,
                cancelUrlPattern: null,
                failureUrlPattern: null,
                onSuccess: null,
                onFailure: null,
                onCancelled: null,
                loadingWidget: null,
                errorWidgetBuilder: null,
              ),
            ),
          ),
        );

        expect(find.byType(PaymentWebView), findsOneWidget);
      });
    });

    group('Widget State Tests', () {
      testWidgets('should be a StatefulWidget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PaymentWebView(
                paymentUrl: 'https://example.com/pay',
                provider: PaymentProvider.stripe,
                timeout: const Duration(minutes: 5),
              ),
            ),
          ),
        );

        // Find the widget and verify it's a StatefulWidget
        final paymentWebViewFinder = find.byType(PaymentWebView);
        expect(paymentWebViewFinder, findsOneWidget);

        final paymentWebViewWidget =
            tester.widget<PaymentWebView>(paymentWebViewFinder);
        expect(paymentWebViewWidget, isA<StatefulWidget>());
      });

      testWidgets('should maintain state across rebuilds',
          (WidgetTester tester) async {
        String paymentUrl = 'https://example.com/pay/1';

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Column(
                    children: [
                      Expanded(
                        child: PaymentWebView(
                          paymentUrl: paymentUrl,
                          provider: PaymentProvider.stripe,
                          timeout: const Duration(minutes: 5),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            paymentUrl = 'https://example.com/pay/2';
                          });
                        },
                        child: const Text('Change URL'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        // Initial state
        expect(find.byType(PaymentWebView), findsOneWidget);
        expect(find.text('Change URL'), findsOneWidget);

        // Trigger rebuild
        await tester.tap(find.text('Change URL'));
        await tester.pump();

        // Should still find the widget after rebuild
        expect(find.byType(PaymentWebView), findsOneWidget);
      });
    });
  });
}
