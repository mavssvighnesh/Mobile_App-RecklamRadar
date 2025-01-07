import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:recklamradar/main.dart' as app;
import 'package:recklamradar/providers/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:recklamradar/firebase_options.dart';
import 'package:recklamradar/services/currency_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Tests', () {
    late CurrencyService currencyService;

    setUpAll(() async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      currencyService = CurrencyService();
      await currencyService.initializeCurrency();
    });

    Widget createTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<CurrencyService>.value(value: currencyService),
          StreamProvider<String>(
            create: (_) => currencyService.currencyStream,
            initialData: 'SEK',
          ),
        ],
        child: const app.MyApp(),
      );
    }

    testWidgets('Complete login cycle test', (WidgetTester tester) async {
      // 1. First login with valid credentials
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Enter valid credentials
      await tester.enterText(find.byKey(const Key('email_field')), 'vighneshmandaleeka@gmail.com');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('password_field')), '123467');
      await tester.pump();
      
      // Tap login button
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Verify success message
      expect(
        find.text('Successfully logged in!'), 
        findsOneWidget,
        reason: 'Success message not found after login'
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 2. Navigate to settings and logout
      await tester.tap(find.byIcon(Icons.settings_rounded)); // Profile/Settings tab
      await tester.pumpAndSettle();

      // Find and tap logout button
      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pumpAndSettle();

      // Verify we're back at login screen
      expect(find.byKey(const Key('login_button')), findsOneWidget);

      // 3. Try login with invalid credentials
      await tester.enterText(find.byKey(const Key('email_field')), 'invalid@email.com');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('password_field')), 'wrongpassword');
      await tester.pump();
      
      // Tap login button
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Check for error message in SnackBar
      bool errorFound = tester.any(find.byType(SnackBar));
      expect(errorFound, true, reason: 'No error SnackBar was displayed');

      // Verify error message content
      final bool hasErrorMessage = [
        'An error occurred',
        'No user found with this email',
        'Wrong password provided',
      ].any((message) => find.text(message).evaluate().isNotEmpty);
      
      expect(hasErrorMessage, true, 
        reason: 'Expected error message not found in SnackBar');

      // Verify we're still on login screen
      expect(find.byKey(const Key('login_button')), findsOneWidget,
        reason: 'Should remain on login screen after failed attempt');
    });
  });
} 