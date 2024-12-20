import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'constants/user_fields.dart';
import 'login_screen.dart';
import 'accountdetailspage.dart';

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
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreferences(String field, String value) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final isAdmin = user.email?.toLowerCase().endsWith('@rr.com') ?? false;
        await _firestoreService.updateUserProfile(
          user.uid,
          {field: value},
          isAdmin,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating preferences: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Profile Section
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _profileImage != null && _profileImage!.isNotEmpty
                              ? NetworkImage(_profileImage!)
                              : const AssetImage('assets/images/default_avatar.png')
                                  as ImageProvider,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _userEmail,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Settings Section
                  Text(
                    "App Settings",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Language'),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      items: ['English', 'Swedish', 'Spanish']
                          .map((lang) => DropdownMenuItem(
                                value: lang,
                                child: Text(lang),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLanguage = value);
                          _updatePreferences('language', value);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_money),
                    title: const Text('Currency'),
                    trailing: DropdownButton<String>(
                      value: _selectedCurrency,
                      items: ['SEK', 'USD', 'EUR']
                          .map((currency) => DropdownMenuItem(
                                value: currency,
                                child: Text(currency),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCurrency = value);
                          _updatePreferences('currency', value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account Settings Section
                  Text(
                    "Account Settings",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text("Account Details"),
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
                    leading: const Icon(Icons.logout),
                    title: const Text("Logout"),
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
                  const SizedBox(height: 16),

                  // Footer Section
                  Text(
                    "Version 1.0.0. For support, visit our help center or contact us at support@example.com. "
                    "We are here to assist you with any issues or questions you may have.",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
