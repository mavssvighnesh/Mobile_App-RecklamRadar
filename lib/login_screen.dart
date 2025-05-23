import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'registration_page.dart';
import 'passwordpage.dart';
import 'package:recklamradar/providers/theme_provider.dart';
import 'package:recklamradar/utils/message_utils.dart';
import 'package:recklamradar/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:recklamradar/styles/app_text_styles.dart';
import 'package:recklamradar/widgets/glass_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Remove the setPersistence call since it's web-only
    // _auth.setPersistence(Persistence.LOCAL);
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      final userId = credential.user?.uid;
      if (userId != null) {
        showMessage(context, "Successfully logged in!", true);
        
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;
        
        final userProfile = await _firestoreService.getUserProfile(userId);
        final isAdmin = userProfile?['isAdmin'] ?? 
                     _emailController.text.trim().toLowerCase().endsWith('@rr.com');

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      String message = 'An error occurred';
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          message = 'No user found with this email';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided';
        }
      }
      showMessage(context, message, false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: Provider.of<ThemeProvider>(context).backgroundGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 32),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Provider.of<ThemeProvider>(context).isDarkMode 
                              ? Colors.white 
                              : theme.colorScheme.primary,
                          ), 
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          key: const Key('email_field'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: AppTextStyles.label(context),
                            prefixIcon: Icon(Icons.email_outlined, 
                              color: theme.colorScheme.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          key: const Key('password_field'),
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: AppTextStyles.label(context),
                            prefixIcon: Icon(Icons.lock_outline,
                              color: theme.colorScheme.primary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: theme.colorScheme.primary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgotPasswordPage(),
                                ),
                              );
                            },
                            child: Text(
                              "Forgot Password?",
                              style: AppTextStyles.link(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          key: const Key('login_button'),
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: Size(size.width * 0.7, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Log In',
                                  style: AppTextStyles.buttonLarge(context),
                                ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegistrationPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: Size(size.width * 0.7, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}