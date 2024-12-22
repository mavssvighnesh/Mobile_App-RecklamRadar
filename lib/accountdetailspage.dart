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

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  _AccountDetailsPageState createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  
  String? _currentProfileImage;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedGender = '';
  bool _isEditing = false;
  bool _isLoading = true;

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
            _nameController.text = userData[UserFields.name] ?? '';
            _emailController.text = userData[UserFields.email] ?? '';
            _phoneController.text = userData[UserFields.phone] ?? '';
            _ageController.text = userData[UserFields.age]?.toString() ?? '';
            _selectedGender = userData[UserFields.gender] ?? '';
            _currentProfileImage = userData[UserFields.profileImage];
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final isAdmin = user.email?.toLowerCase().endsWith('@rr.com') ?? false;
        await _firestoreService.updateUserProfile(
          user.uid,
          {
            UserFields.name: _nameController.text,
            UserFields.phone: _phoneController.text,
            UserFields.age: int.tryParse(_ageController.text),
            UserFields.gender: _selectedGender,
          },
          isAdmin,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Picture'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 75,
                  );
                  if (image != null) {
                    await _uploadProfileImage(File(image.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 75,
                  );
                  if (image != null) {
                    await _uploadProfileImage(File(image.path));
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    try {
      setState(() => _isLoading = true);
      
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${_auth.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await ref.putFile(imageFile);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeProvider.backgroundGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 200,
                      floating: false,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          'Account Details',
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
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
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
                                ),
                                const SizedBox(height: 16),
                                _buildDropdownField('Gender', _selectedGender),
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
                          ],
                        ),
                      ),
                    ),
                  ],
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
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String value) {
    return DropdownButtonFormField<String>(
      value: value.isNotEmpty ? value : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: ['Male', 'Female', 'Other']
          .map((gender) => DropdownMenuItem(
                value: gender,
                child: Text(gender),
              ))
          .toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedGender = newValue!;
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
}
