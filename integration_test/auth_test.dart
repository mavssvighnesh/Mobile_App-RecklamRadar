import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:recklamradar/main.dart' as app;
import 'package:recklamradar/providers/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:recklamradar/firebase_options.dart';
import 'package:recklamradar/services/currency_service.dart';
import 'package:recklamradar/home_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Tests', () {
    late CurrencyService currencyService;

    setUpAll(() async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      currencyService = CurrencyService();
      try {
        await currencyService.initializeCurrency();
      } catch (e) {
        print('Currency service initialization error: $e');
        // Continue with test even if currency service fails
      }
    });

    testWidgets('Complete login cycle test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            Provider<CurrencyService>.value(value: currencyService),
            StreamProvider<String>(
              create: (_) => currencyService.currencyStream,
              initialData: 'SEK',
            ),
          ],
          child: const app.MyApp(initialRoute: '/login'),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Enter valid credentials
      await tester.enterText(
        find.byKey(const Key('email_field')), 
        'vighneshmandaleeka@gmail.com'
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('password_field')), 
        '123467'
      );
      await tester.pump();

      // Tap login button
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump(const Duration(seconds: 3));

      // Wait for navigation
      await tester.pumpAndSettle();

      // Verify we're on the home screen
      expect(find.byType(UserHomeScreen), findsOneWidget);
    });
  });
} 