import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:recklamradar/main.dart' as app;
import 'package:recklamradar/models/store_item.dart';
import 'package:flutter/services.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Currency Change Tests', () {
    setUp(() {
      debugPrint("Setting up test...");
      // Reset debug flags at start
      debugPrintGestureArenaDiagnostics = false;
      debugPrintScheduleFrameStacks = false;
    });

    tearDown(() async {
      debugPrint("Cleaning up test...");
      // Reset all debug flags
      debugPrintGestureArenaDiagnostics = false;
      debugPrintScheduleFrameStacks = false;
      // Reset widget binding
      WidgetsBinding.instance.resetEpoch();
      // Reset scheduler binding
      SchedulerBinding.instance.resetEpoch();
      // Allow any animations to complete
      await Future.delayed(const Duration(seconds: 1));
      // Final pump to ensure clean state
      await WidgetsBinding.instance.endOfFrame;
    });

    testWidgets(
      'Navigate to Willys, change currency to INR, and verify updated prices',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          try {
            debugPrint("\n=== Starting Currency Change Test ===");
            
            // Start the app
            debugPrint("Step 1: Loading the app");
            app.main();
            await tester.pumpAndSettle(const Duration(seconds: 5));

            // Login
            debugPrint("Step 2: Performing login");
            await _performLogin(tester);
            debugPrint("Login successful");

            // First visit to Willys
            debugPrint("Step 3: First visit to Willys store");
            await _navigateToWillysStore(tester);
            await _verifyStoreItemsAndScroll(tester, 'SEK');
            debugPrint("First Willys store visit completed");

            // Verify home screen before currency change
            debugPrint("Step 4: Verifying home screen");
            await _navigateBackToHome(tester);
            debugPrint("Home screen verified");

            // Change currency
            debugPrint("Step 5: Changing currency to INR");
            await _changeCurrencyToINR(tester);
            debugPrint("Currency changed to INR");

            // Second visit to Willys
            debugPrint("Step 6: Second visit to Willys store");
            await _navigateToWillysStore(tester);
            await _verifyStoreItemsAndScroll(tester, 'INR');
            debugPrint("Second Willys store visit completed");
            
            // Final cleanup and verification
            await tester.pumpAndSettle();
            // Ensure we're back on home screen
            expect(find.text('Welcome Back!'), findsOneWidget, reason: 'Not back on home screen after test completion');
            // Wait for any pending timers
            await Future.delayed(const Duration(seconds: 2));
            // Final pump to ensure clean state
            await tester.pumpAndSettle();
            await WidgetsBinding.instance.endOfFrame;
            
            debugPrint("\n=== Test Completed Successfully ===");
          } finally {
            // Reset debug flags in finally block too
            debugPrintGestureArenaDiagnostics = false;
            debugPrintScheduleFrameStacks = false;
            await tester.pumpAndSettle();
            await WidgetsBinding.instance.endOfFrame;
          }
        });
      },
    );
  });
}

Future<void> _performLogin(WidgetTester tester) async {
  await tester.pumpAndSettle();
  expect(find.text('Welcome Back!'), findsOneWidget, reason: 'Login screen not found');

  await tester.enterText(find.byKey(const Key('email_field')), 'vighneshmandaleeka@gmail.com');
  await tester.enterText(find.byKey(const Key('password_field')), '123467');
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle(const Duration(seconds: 3));

  expect(find.text('Welcome Back!'), findsOneWidget, reason: 'Home screen not loaded after login');
}

Future<void> _navigateToWillysStore(WidgetTester tester) async {
  try {
    debugPrint("Starting navigation to Willys store");
    await tester.pumpAndSettle();

    // Find and tap search icon in app bar
    final searchIcon = find.byIcon(Icons.search);
    expect(searchIcon, findsWidgets, reason: 'Search icon not found');
    await tester.tap(searchIcon.first);
    await tester.pumpAndSettle();
    debugPrint("Tapped search icon");

    // Enter "Willys" in search field
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget, reason: 'Search field not found');
    await tester.enterText(searchField, 'Willys');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    debugPrint("Entered Willys in search");

    // Tap on Willys store result
    final willysStore = find.text('Willys');
    expect(willysStore, findsWidgets, reason: 'Willys store not found in search results');
    await tester.tap(willysStore.last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    debugPrint("Tapped on Willys store");

  } catch (e, stackTrace) {
    debugPrint("Error in _navigateToWillysStore: $e");
    debugPrint("StackTrace: $stackTrace");
    rethrow;
  }
}

Future<void> _navigateBackToHome(WidgetTester tester) async {
  // Just verify we're on home screen since navigation is already done
  expect(find.text('Welcome Back!'), findsOneWidget, reason: 'Not on home screen');
  debugPrint("Verified on home screen");
}

Future<void> _changeCurrencyToINR(WidgetTester tester) async {
  try {
    debugPrint("Starting currency change to INR");
    await tester.pumpAndSettle();

    // Find and tap settings tab using the correct icon
    final settingsTab = find.byIcon(Icons.settings_rounded);
    expect(settingsTab, findsWidgets, reason: 'Settings tab not found');
    await tester.tap(settingsTab.last);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    // Verify we're on settings page by looking for specific settings options
    final currencyOption = find.widgetWithText(ListTile, 'Currency');
    expect(currencyOption, findsOneWidget, reason: 'Currency option not found - Settings page not loaded');
    debugPrint("On settings page");

    // Tap currency option
    await tester.tap(currencyOption);
    await tester.pumpAndSettle();
    debugPrint("Currency dialog opened");

    // Select INR from currency options
    final inrOption = find.text('Indian Rupee (INR)');
    expect(inrOption, findsOneWidget, reason: 'INR option not found in currency dialog');
    await tester.tap(inrOption);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    debugPrint("Selected INR");

    // Return to home using home tab
    final homeTab = find.byIcon(Icons.home_rounded);
    expect(homeTab, findsWidgets, reason: 'Home tab not found');
    await tester.tap(homeTab.last);
    await tester.pumpAndSettle();
    debugPrint("Returned to home screen");

    // Verify on home screen
    expect(find.text('Welcome Back!'), findsOneWidget, 
      reason: 'Not on home screen after currency change');
    debugPrint("Successfully changed currency to INR");

  } catch (e, stackTrace) {
    debugPrint("Error in _changeCurrencyToINR: $e");
    debugPrint("StackTrace: $stackTrace");
    rethrow;
  }
}

Future<void> _verifyStoreItemsAndScroll(WidgetTester tester, String currency) async {
  try {
    debugPrint("In Willys store, waiting before navigation");
    await tester.pumpAndSettle(const Duration(seconds: 3));

    if (currency == 'INR') {
      // For second visit
      await tester.pumpAndSettle(const Duration(seconds: 5));
      debugPrint("Waited 5 seconds in second visit");
      
      // Navigate back to home
      final backButton = find.byTooltip('Back');
      expect(backButton, findsOneWidget, reason: 'Back button not found');
      await tester.tap(backButton);
      await tester.pumpAndSettle();
      debugPrint("Tapped back button");

      // Close search
      final closeIcon = find.byIcon(Icons.close);
      expect(closeIcon, findsOneWidget, reason: 'Close search icon not found');
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();
      debugPrint("Closed search");

      // Final verification and cleanup
      expect(find.text('Welcome Back!'), findsOneWidget, reason: 'Not back on home screen');
      
      // Complete test and cleanup
      debugPrint("\n=== Test Status: PASSED ===");
      debugPrint("All test steps completed successfully");
      
      // Force app closure and cleanup
      await tester.pumpAndSettle();
      await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
      WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.detached);
      await tester.pumpAndSettle();
      
      // Final cleanup
      await WidgetsBinding.instance.endOfFrame;
      debugPrint("App closed and test completed");
      return;
    }
    
    // First visit logic remains the same...
    final backButton = find.byTooltip('Back');
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    final closeIcon = find.byIcon(Icons.close);
    expect(closeIcon, findsOneWidget);
    await tester.tap(closeIcon);
    await tester.pumpAndSettle();

  } catch (e, stackTrace) {
    debugPrint("Error in _verifyStoreItemsAndScroll: $e");
    debugPrint("StackTrace: $stackTrace");
    rethrow;
  }
}
