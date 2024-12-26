import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'login_screen.dart';
import 'passwordpage.dart';
import 'constants/user_fields.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:recklamradar/providers/theme_provider.dart';
import 'package:recklamradar/utils/message_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  _AccountDetailsPageState createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String? _currentProfileImage;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  String? _gender;

  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _ageController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Debug print
        print('Fetching data for user: $userId');
        
        final userData = await _firestoreService.getUserProfile(userId);
        
        // Debug print
        print('Fetched user data: $userData');

        if (mounted && userData != null) {
          setState(() {
            _nameController.text = userData[UserFields.name]?.toString() ?? '';
            _emailController.text = userData[UserFields.email]?.toString() ?? '';
            _phoneController.text = userData[UserFields.phone]?.toString() ?? '';
            _ageController.text = userData[UserFields.age]?.toString() ?? '';
            _gender = userData[UserFields.gender]?.toString();
            _currentProfileImage = userData[UserFields.profileImage];
            // Debug prints
            print('Name: ${_nameController.text}');
            print('Email: ${_emailController.text}');
            print('Phone: ${_phoneController.text}');
            print('Age: ${_ageController.text}');
            print('Gender: $_gender');
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateUserData() async {
    try {
      final age = int.tryParse(_ageController.text);
      if (age == null || age < 14 || age > 100) {
        showMessage(context, 'Please enter a valid age between 14 and 100', false);
        return;
      }

      final user = _auth.currentUser;
      if (user != null) {
        final isAdmin = user.email?.toLowerCase().endsWith('@rr.com') ?? false;
        await _firestoreService.updateUserProfile(
          user.uid,
          {
            UserFields.name: _nameController.text,
            UserFields.phone: _phoneController.text,
            UserFields.age: age,
            UserFields.gender: _gender,
          },
          isAdmin,
        );

        showMessage(context, "Profile updated successfully", true);
      }
    } catch (e) {
      showMessage(context, "Error updating profile: $e", false);
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera, color: Colors.blue),
                  title: const Text(
                    'Take a Photo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _picker.pickImage(source: ImageSource.camera);
                    if (image != null) {
                      _uploadProfileImage(image.path);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      _uploadProfileImage(image.path);
                    }
                  },
                ),
                if (_currentProfileImage != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Remove Photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _removeProfileImage();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeProfileImage() async {
    try {
      setState(() => _isLoading = true);
      
      if (_currentProfileImage != null) {
        // Delete from Storage
        final storageRef = FirebaseStorage.instance.refFromURL(_currentProfileImage!);
        await storageRef.delete();
        
        // Update Firestore
        final user = _auth.currentUser;
        if (user != null) {
          await _firestoreService.updateUserProfile(
            user.uid,
            {'profileImage': null},
            user.email?.toLowerCase().endsWith('@rr.com') ?? false,
          );
        }
        
        setState(() {
          _currentProfileImage = null;
        });
      }
    } catch (e) {
      showMessage(context, 'Error removing profile photo: $e', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadProfileImage(String imagePath) async {
    try {
      setState(() => _isLoading = true);
      
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${_auth.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await ref.putFile(File(imagePath));
      final imageUrl = await ref.getDownloadURL();

      // Update Auth profile
      await _auth.currentUser?.updatePhotoURL(imageUrl);

      // Update Firestore profile
      final isAdmin = _auth.currentUser?.email?.toLowerCase().endsWith('@rr.com') ?? false;
      await _firestoreService.updateUserProfile(
        _auth.currentUser!.uid,
        {UserFields.profileImage: imageUrl},
        isAdmin,
      );

      setState(() => _currentProfileImage = imageUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    try {
      setState(() => _isLoading = true);
      final user = _auth.currentUser;
      
      if (user != null) {
        final userId = user.uid;
        final isAdmin = user.email?.toLowerCase().endsWith('@rr.com') ?? false;
        
        // 1. Delete profile image from Storage if exists
        if (_currentProfileImage != null) {
          try {
            final storageRef = FirebaseStorage.instance.refFromURL(_currentProfileImage!);
            await storageRef.delete();
            print('Profile image deleted successfully');
          } catch (e) {
            print('Error deleting profile image: $e');
          }
        }

        // 2. Delete user data from Firestore
        try {
          // Delete from appropriate collection (users or admins)
          final collection = isAdmin ? 'admins' : 'users';
          await _firestore.collection(collection).doc(userId).delete();
          
          // Delete user's favorites
          final favoritesSnapshot = await _firestore
              .collection('favorites')
              .where('userId', isEqualTo: userId)
              .get();
          
          for (var doc in favoritesSnapshot.docs) {
            await doc.reference.delete();
          }
          
          // Delete user's cart items
          final cartSnapshot = await _firestore
              .collection('carts')
              .where('userId', isEqualTo: userId)
              .get();
              
          for (var doc in cartSnapshot.docs) {
            await doc.reference.delete();
          }
          
          print('User data deleted successfully');
        } catch (e) {
          print('Error deleting user data: $e');
        }

        // 3. Delete Firebase Auth account
        await user.delete();
        
        if (mounted) {
          showMessage(context, 'Account deleted successfully', true);
          // Navigate to login screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'Error deleting account: $e', false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: Container(
          decoration: BoxDecoration(
            gradient: ThemeProvider.backgroundGradient,
          ),
          child: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 120,
                        floating: false,
                        pinned: true,
                        backgroundColor: Colors.transparent,
                        leading: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.black87,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        flexibleSpace: LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            final top = constraints.biggest.height;
                            return FlexibleSpaceBar(
                              centerTitle: false,
                              titlePadding: EdgeInsets.only(
                                left: top <= 80 ? 50.0 : 16.0,
                                bottom: 16.0,
                              ),
                              title: Text(
                                'Account Details',
                                style: TextStyle(
                                  color: top <= 80 ? Colors.black87 : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: top <= 80 ? 20 : 24,
                                ),
                              ),
                              background: Container(
                                decoration: BoxDecoration(
                                  gradient: ThemeProvider.cardGradient,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Center(
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      CircleAvatar(
                                        radius: 60,
                                        backgroundImage: _currentProfileImage != null
                                            ? NetworkImage(_currentProfileImage!)
                                            : null,
                                        child: _currentProfileImage == null
                                            ? const Icon(Icons.person, size: 60)
                                            : null,
                                      ),
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: theme.colorScheme.primary,
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildProfileSection(
                                context,
                                'Personal Information',
                                [
                                  _buildTextField(
                                    'Full Name',
                                    _nameController,
                                    Icons.person_outline,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    'Email',
                                    _emailController,
                                    Icons.email_outlined,
                                    enabled: false,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    'Phone',
                                    _phoneController,
                                    Icons.phone_outlined,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    'Age',
                                    _ageController,
                                    Icons.calendar_today_outlined,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your age';
                                      }

                                      // Check if it's a valid number
                                      final age = int.tryParse(value);
                                      if (age == null) {
                                        return 'Please enter a valid number';
                                      }

                                      // Check age range
                                      if (age < 14) {
                                        return 'You must be at least 14 years old';
                                      }
                                      if (age > 100) {
                                        return 'Age cannot be more than 100';
                                      }

                                      return null;
                                    },
                                    onChanged: (value) {
                                      // Remove non-numeric characters
                                      final newValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                                      if (newValue != value) {
                                        _ageController.text = newValue;
                                        _ageController.selection = TextSelection.fromPosition(
                                          TextPosition(offset: newValue.length),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDropdownField('Gender', _gender, validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Please select a gender';
                                    return null;
                                  }),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _updateUserData,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: const Text('Save Changes'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ChangePasswordPage(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: const Text('Change Password'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _showDeleteAccountDialog();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: const Text('Delete Account'),
                                    ),
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
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String? value, {required String? Function(dynamic value) validator}) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.person_outline),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        ),
      ),
      dropdownColor: Colors.white,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 16,
      ),
      validator: validator,
      items: ['Male', 'Female', 'Other']
          .map((gender) => DropdownMenuItem(
                value: gender,
                child: Text(gender),
              ))
          .toList(),
      onChanged: (newValue) {
        setState(() {
          _gender = newValue!;
        });
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _showDeleteAccountDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and will delete all your data.',
            style: TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
