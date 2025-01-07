import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:recklamradar/home_screen.dart';
import 'package:recklamradar/utils/performance_config.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'login_screen.dart';
import 'admin_home_screen.dart';
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
  
  // Initialize currency service and fetch initial rates
  final currencyService = CurrencyService();
  await currencyService.initializeCurrency();
  
  // Apply performance optimizations
  await PerformanceConfig.optimizePerformance();

  // Enable frame monitoring in debug mode
  if (kDebugMode) {
    debugPrintBeginFrameBanner = true;
    debugPrintEndFrameBanner = true;
    debugPrintScheduleFrameStacks = true;
  }

  // Add image cache optimization
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final prefs = await SharedPreferences.getInstance();
  // ignore: unused_local_variable
  final isDarkMode = prefs.getBool('is_dark_mode') ?? false;
  
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
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'ReklamRadar',
          theme: themeProvider.theme,
          home: const LoginScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
