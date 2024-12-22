import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'constants/user_fields.dart';
import 'package:recklamradar/login_screen.dart';
import 'accountdetailspage.dart';
import 'providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';
  String? _profileImage;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'SEK';
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = await _firestoreService.getUserProfile(user.uid);
        if (userData != null) {
          setState(() {
            _userName = userData[UserFields.name] ?? '';
            _userEmail = userData[UserFields.email] ?? '';
            _profileImage = userData[UserFields.profileImage];
            _selectedLanguage = userData['language'] ?? 'English';
            _selectedCurrency = userData['currency'] ?? 'SEK';
            _notificationsEnabled = userData['notifications'] ?? true;
            _darkModeEnabled = userData['darkMode'] ?? false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeProvider.subtleGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: size.height * 0.25,
                      floating: false,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          'Settings',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: ThemeProvider.cardGradient,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: _profileImage != null
                                      ? NetworkImage(_profileImage!)
                                      : null,
                                  child: _profileImage == null
                                      ? Icon(Icons.person,
                                          size: 50,
                                          color: theme.colorScheme.onPrimary)
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _userName,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSettingsSection(
                          context,
                          'Account',
                          [
                            ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: const Text('Account Details'),
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
                              leading: const Icon(Icons.notifications_outlined),
                              title: const Text('Notifications'),
                              trailing: Switch(
                                value: _notificationsEnabled,
                                onChanged: (value) {
                                  setState(() => _notificationsEnabled = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        _buildSettingsSection(
                          context,
                          'Preferences',
                          [
                            ListTile(
                              leading: const Icon(Icons.language),
                              title: const Text('Language'),
                              trailing: DropdownButton<String>(
                                value: _selectedLanguage,
                                items: ['English', 'Svenska']
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
                            ListTile(
                              leading: const Icon(Icons.monetization_on_outlined),
                              title: const Text('Currency'),
                              trailing: DropdownButton<String>(
                                value: _selectedCurrency,
                                items: ['SEK', 'EUR', 'USD']
                                    .map((currency) => DropdownMenuItem(
                                          value: currency,
                                          child: Text(currency),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _selectedCurrency = value!);
                                },
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.dark_mode_outlined),
                              title: const Text('Dark Mode'),
                              trailing: Switch(
                                value: _darkModeEnabled,
                                onChanged: (value) {
                                  setState(() => _darkModeEnabled = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        _buildSettingsSection(
                          context,
                          'Other',
                          [
                            ListTile(
                              leading: const Icon(Icons.help_outline),
                              title: const Text('Help & Support'),
                              onTap: () {
                                // Navigate to Help & Support
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.info_outline),
                              title: const Text('About'),
                              onTap: () {
                                // Navigate to About page
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.logout, color: Colors.red),
                              title: const Text(
                                'Sign Out',
                                style: TextStyle(color: Colors.red),
                              ),
                              onTap: _signOut,
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
      BuildContext context, String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }
}
