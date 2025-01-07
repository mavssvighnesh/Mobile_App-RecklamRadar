import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:recklamradar/home_screen.dart';
import 'package:recklamradar/utils/performance_config.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recklamradar/utils/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recklamradar/utils/smooth_scroll_behavior.dart';
import 'package:recklamradar/utils/custom_scroll_physics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:recklamradar/services/currency_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize currency service and fetch initial rates
  final currencyService = CurrencyService();
  await currencyService.initializeCurrency();
  
  // Apply performance optimizations
  await PerformanceConfig.optimizePerformance();

  // Get cached user session
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        Provider<CurrencyService>.value(
          value: currencyService,
        ),
        StreamProvider<String>(
          create: (_) => currencyService.currencyStream,
          initialData: 'SEK',
        ),
      ],
      child: MyApp(
        initialRoute: currentUser != null ? '/home' : '/login',
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReklamRadar',
      theme: Provider.of<ThemeProvider>(context).theme,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const UserHomeScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          );
        }
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
      },
    );
  }
}
