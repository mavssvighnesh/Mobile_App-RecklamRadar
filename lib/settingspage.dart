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
import 'package:recklamradar/widgets/glass_container.dart';
import 'package:recklamradar/widgets/glass_dialog.dart';

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
  final String _selectedLanguage = 'English';
  final String _selectedCurrency = 'SEK';
  // ignore: unused_field
  final bool _isDarkMode = false;
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Section
                    GlassContainer(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile Image
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AccountDetailsPage(),
                                ),
                              );
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.transparent,
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
                          ),
                          const SizedBox(height: 24),
                          
                          // User Name
                          Text(
                            _userName.isNotEmpty ? _userName : 'No Name',
                            style: AppTextStyles.heading2(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          
                          // User Email
                          Text(
                            _userEmail.isNotEmpty ? _userEmail : 'No Email',
                            style: AppTextStyles.bodyMedium(context),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Settings Sections
                    _buildSettingsSection(
                      'App Settings',
                      [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.currency_exchange,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text('Currency', style: AppTextStyles.bodyLarge(context)),
                          subtitle: Text('Selected: ${_currencyService.selectedCurrency}'),
                          onTap: () => _showCurrencyPicker(context),
                        ),
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              title: Text('Dark Mode', style: AppTextStyles.bodyLarge(context)),
                              subtitle: Text(themeProvider.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled'),
                              trailing: Switch(
                                value: themeProvider.isDarkMode,
                                onChanged: (value) async {
                                  await themeProvider.toggleTheme();
                                  if (mounted) {
                                    final user = _auth.currentUser;
                                    if (user != null) {
                                      await _firestoreService.updateUserProfile(
                                        user.uid,
                                        {'darkMode': value},
                                        user.email?.toLowerCase().endsWith('@rr.com') ?? false,
                                      );
                                    }
                                    // Show feedback
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          value ? 'Dark mode enabled' : 'Light mode disabled',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: Theme.of(context).primaryColor,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                activeColor: Theme.of(context).primaryColor,
                              ),
                            );
                          },
                        ),
                      ],
                    ),

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
                            await _signOut();
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
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      opacity: 0.15,
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          blurRadius: 15,
          spreadRadius: 2,
        ),
      ],
      border: Border.all(
        color: Theme.of(context).primaryColor.withOpacity(0.2),
        width: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  title == 'App Settings' ? Icons.settings : Icons.person_outline,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.heading3(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children.map((child) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: child,
          )).toList(),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GlassDialog(
        title: 'Select Currency',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCurrencyOption('Swedish Krona (SEK)', 'SEK'),
            _buildCurrencyOption('US Dollar (USD)', 'USD'),
            _buildCurrencyOption('Euro (EUR)', 'EUR'),
            _buildCurrencyOption('Indian Rupee (INR)', 'INR'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String label, String currency) {
    final isSelected = _currencyService.selectedCurrency == currency;
    return GlassContainer(
      margin: const EdgeInsets.symmetric(vertical: 4),
      opacity: isSelected ? 0.2 : 0.1,
      backgroundColor: isSelected ? 
          Theme.of(context).primaryColor.withOpacity(0.1) : 
          Colors.white.withOpacity(0.1),
      boxShadow: isSelected ? [
        BoxShadow(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ] : null,
      child: ListTile(
        leading: Icon(
          isSelected ? Icons.check_circle : Icons.circle_outlined,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
        ),
        title: Text(
          label,
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: isSelected ? Theme.of(context).primaryColor : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => _updateCurrency(currency),
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

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      
      // Navigate to login screen and remove all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      showMessage(context, "Error signing out: $e", false);
    }
  }
}