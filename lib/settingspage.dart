import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'constants/user_fields.dart';
import 'package:recklamradar/login_screen.dart';
import 'accountdetailspage.dart';
import 'providers/theme_provider.dart';
import 'package:recklamradar/utils/size_config.dart';

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
  bool _isDarkMode = false;

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
    return Material(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            onRefresh: _loadUserData,
            child: Container(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                minWidth: constraints.maxWidth,
              ),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color.fromARGB(0, 239, 237, 237),
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: SizeConfig.blockSizeVertical * 2.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: ThemeProvider.cardGradient,
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
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.95),
                                  Colors.white.withOpacity(0.85),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
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
                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                    radius: SizeConfig.blockSizeVertical * 8,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: _profileImage != null 
                                      ? NetworkImage(_profileImage!)
                                      : null,
                                    child: _profileImage == null
                                      ? Icon(
                                          Icons.person,
                                          size: SizeConfig.blockSizeVertical * 8,
                                          color: Colors.grey[400],
                                        )
                                      : null,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _userName.isNotEmpty ? _userName : 'No Name',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userEmail.isNotEmpty ? _userEmail : 'No Email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
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
                                leading: const Icon(Icons.attach_money),
                                title: const Text('Currency'),
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
                                    value: _selectedCurrency,
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
                                    items: ['SEK', 'USD', 'EUR']
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
                              ),
                              ListTile(
                                leading: Icon(
                                  _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                ),
                                title: const Text('Dark Mode'),
                                trailing: Switch(
                                  value: _isDarkMode,
                                  onChanged: (value) async {
                                    setState(() => _isDarkMode = value);
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
        },
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
