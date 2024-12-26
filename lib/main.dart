import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:recklamradar/home_screen.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'login_screen.dart';
import 'admin_home_screen.dart';
import 'package:recklamradar/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recklamradar/utils/size_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ReklamRadar',
      theme: themeProvider.theme,
      builder: (context, child) {
        SizeConfig().init(context);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 320, // Minimum supported width
              minHeight: 480, // Minimum supported height
            ),
            child: child!,
          ),
        );
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData) {
            final user = snapshot.data!;
            final isAdmin = user.email?.toLowerCase().endsWith('@rr.com') ?? false;
            return isAdmin ? const AdminHomeScreen() : const UserHomeScreen();
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}
