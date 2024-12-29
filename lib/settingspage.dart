import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recklamradar/utils/message_utils.dart';
import 'services/firestore_service.dart';
import 'constants/user_fields.dart';
import 'package:recklamradar/login_screen.dart';
import 'accountdetailspage.dart';
import 'providers/theme_provider.dart';
import 'package:recklamradar/styles/app_text_styles.dart';
import 'package:provider/provider.dart';
import 'services/currency_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final CurrencyService _currencyService = CurrencyService();
  // ignore: unused_field
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';
  String? _profileImage;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'SEK';
  // ignore: unused_field
  bool _isDarkMode = false;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  // ignore: unused_field
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUserData();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    setState(() {
      _opacity = (offset / 180).clamp(0.0, 1.0);
      _isScrolled = offset > 0;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get user profile data from Firestore
        final userData = await _firestoreService.getUserProfile(user.uid);
        
        if (mounted && userData != null) {
          setState(() {
            _userName = userData[UserFields.name] ?? 'No Name';
            _userEmail = userData[UserFields.email] ?? user.email ?? 'No Email';
            _profileImage = userData[UserFields.profileImage];
            
            // Print for debugging
            print('Loaded User Data:');
            print('Name: $_userName');
            print('Email: $_userEmail');
            print('Profile Image: $_profileImage');
          });
        } else {
          print('No user data found in Firestore');
          // Use Firebase Auth data as fallback
          setState(() {
            _userName = user.displayName ?? 'No Name';
            _userEmail = user.email ?? 'No Email';
            _profileImage = user.photoURL;
          });
        }
      } else {
        print('No authenticated user found');
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AnimatedContainer(
        duration: ThemeProvider.themeDuration,
        curve: ThemeProvider.themeCurve,
        decoration: BoxDecoration(
          gradient: Provider.of<ThemeProvider>(context).backgroundGradient,
        ),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: false,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isScrolled ? 0.0 : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: Provider.of<ThemeProvider>(context).cardGradient,
                    ),
                  ),
                ),
                title: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isScrolled ? 0.0 : 1.0,
                  child: const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Section
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        gradient: Provider.of<ThemeProvider>(context).isDarkMode
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF2C3E50).withOpacity(0.8),
                                  const Color(0xFF3A506B).withOpacity(0.8),
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.95),
                                  Colors.white.withOpacity(0.85),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Provider.of<ThemeProvider>(context).isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AccountDetailsPage(),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              backgroundImage: _profileImage != null
                                  ? NetworkImage(_profileImage!)
                                  : null,
                              child: _profileImage == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Theme.of(context).colorScheme.primary,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _userName.isNotEmpty ? _userName : 'No Name',
                            style: AppTextStyles.heading2(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _userEmail.isNotEmpty ? _userEmail : 'No Email',
                            style: AppTextStyles.bodyMedium(context),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Settings Section
                    _buildSettingsSection(
                      'App Settings',
                      [
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: const Text('Language'),
                          trailing: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: DropdownButton<String>(
                              value: _selectedLanguage,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              dropdownColor: Colors.white,
                              items: ['English', 'Swedish']
                                  .map((lang) => DropdownMenuItem(
                                        value: lang,
                                        child: Text(lang),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _selectedLanguage = value!);
                              },
                            ),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.currency_exchange),
                          title: const Text('Currency'),
                          subtitle: Text('Selected: ${_currencyService.selectedCurrency}'),
                          onTap: () => _showCurrencyPicker(context),
                        ),
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return AnimatedContainer(
                              duration: ThemeProvider.themeDuration,
                              curve: ThemeProvider.themeCurve,
                              decoration: BoxDecoration(
                                gradient: themeProvider.isDarkMode
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF2C3E50).withOpacity(0.8),
                                          const Color(0xFF3A506B).withOpacity(0.8),
                                        ],
                                      )
                                    : LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withOpacity(0.95),
                                          Colors.white.withOpacity(0.85),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: themeProvider.isDarkMode
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                ),
                              ),
                              child: ListTile(
                                leading: AnimatedSwitcher(
                                  duration: ThemeProvider.themeDuration,
                                  child: Icon(
                                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                    key: ValueKey(themeProvider.isDarkMode),
                                    color: Theme.of(context).iconTheme.color,
                                  ),
                                ),
                                title: Text(
                                  'Dark Mode',
                                  style: AppTextStyles.bodyLarge(context),
                                ),
                                subtitle: Text(
                                  'Toggle app theme',
                                  style: AppTextStyles.bodySmall(context),
                                ),
                                trailing: Switch(
                                  value: themeProvider.isDarkMode,
                                  onChanged: (value) async {
                                    await themeProvider.toggleTheme();
                                    // Update user preferences in Firestore if needed
                                    final user = _auth.currentUser;
                                    if (user != null) {
                                      await _firestoreService.updateUserProfile(
                                        user.uid,
                                        {'darkMode': value},
                                        user.email?.toLowerCase().endsWith('@rr.com') ?? false,
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Account Settings Section
                    _buildSettingsSection(
                      'Account Settings',
                      [
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Account Details'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AccountDetailsPage(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () async {
                            await _auth.signOut();
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: Provider.of<ThemeProvider>(context).isDarkMode
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2C3E50).withOpacity(0.8),
                  const Color(0xFF3A506B).withOpacity(0.8),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Provider.of<ThemeProvider>(context).isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading3(context),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Swedish Krona (SEK)'),
              onTap: () => _updateCurrency('SEK'),
            ),
            ListTile(
              title: const Text('US Dollar (USD)'),
              onTap: () => _updateCurrency('USD'),
            ),
            ListTile(
              title: const Text('Euro (EUR)'),
              onTap: () => _updateCurrency('EUR'),
            ),
            ListTile(
              title: const Text('Indian Rupee (INR)'),
              onTap: () => _updateCurrency('INR'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateCurrency(String currency) async {
    try {
      setState(() => _isLoading = true);
      
      // Update currency and fetch new rates
      await CurrencyService().setSelectedCurrency(currency);
      
      // Close the dialog
      Navigator.pop(context);
      
      // Show success message
      if (mounted) {
        showMessage(context, 'Currency updated to $currency', true);
      }
    } catch (e) {
      print('Error updating currency: $e');
      if (mounted) {
        showMessage(context, 'Failed to update currency', false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
