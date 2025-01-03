import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'login_screen.dart';
import 'passwordpage.dart';
import 'package:recklamradar/styles/app_text_styles.dart';
import 'constants/user_fields.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:recklamradar/providers/theme_provider.dart';
import 'package:recklamradar/utils/message_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  _AccountDetailsPageState createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  String? _currentProfileImage;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  String? _gender;

  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _ageController = TextEditingController();
    _loadUserData();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    setState(() {
      _opacity = (offset / 180).clamp(0.0, 1.0);
      _isScrolled = offset > 0;
    });
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final userData = await _firestoreService.getUserProfile(userId);
        if (mounted && userData != null) {
          setState(() {
            _nameController.text = userData[UserFields.name]?.toString() ?? '';
            _emailController.text = userData[UserFields.email]?.toString() ?? '';
            _phoneController.text = userData[UserFields.phone]?.toString() ?? '';
            _ageController.text = userData[UserFields.age]?.toString() ?? '';
            _gender = userData[UserFields.gender]?.toString();
            _currentProfileImage = userData[UserFields.profileImage];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'Error loading profile: $e', false);
      }
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

  Future<void> _showImagePickerOptions() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            gradient: themeProvider.isDarkMode
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2C3E50).withOpacity(0.95),
                      const Color(0xFF3A506B).withOpacity(0.95),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.90),
                    ],
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: themeProvider.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Profile Photo',
                  style: AppTextStyles.heading2(context).copyWith(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageOptionButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: themeProvider.isDarkMode
                            ? [
                                const Color(0xFF2C3E50).withOpacity(0.8),
                                const Color(0xFF3A506B).withOpacity(0.8),
                              ]
                            : [
                                Theme.of(context).primaryColor.withOpacity(0.1),
                                Theme.of(context).primaryColor.withOpacity(0.2),
                              ],
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 85,
                        );
                        if (image != null && mounted) {
                          await _uploadProfileImage(image.path);
                        }
                      },
                    ),
                    _buildImageOptionButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: themeProvider.isDarkMode
                            ? [
                                const Color(0xFF2C3E50).withOpacity(0.8),
                                const Color(0xFF3A506B).withOpacity(0.8),
                              ]
                            : [
                                Theme.of(context).primaryColor.withOpacity(0.1),
                                Theme.of(context).primaryColor.withOpacity(0.2),
                              ],
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 85,
                        );
                        if (image != null && mounted) {
                          await _uploadProfileImage(image.path);
                        }
                      },
                    ),
                    if (_currentProfileImage != null)
                      _buildImageOptionButton(
                        icon: Icons.delete_rounded,
                        label: 'Remove',
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.red.withOpacity(0.1),
                            Colors.red.withOpacity(0.2),
                          ],
                        ),
                        color: Colors.red,
                        onTap: () {
                          Navigator.pop(context);
                          _removeProfileImage();
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: themeProvider.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[100],
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Gradient gradient,
    Color? color,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeProvider.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color ?? Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: themeProvider.isDarkMode
                  ? Colors.white
                  : color ?? Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeProfileImage() async {
    try {
      setState(() => _isLoading = true);
      
      final user = _auth.currentUser;
      if (user == null) return;

      if (_currentProfileImage != null) {
        // Delete from Storage
        try {
          final storageRef = FirebaseStorage.instance.refFromURL(_currentProfileImage!);
          await storageRef.delete();
        } catch (e) {
          print('Error deleting image from storage: $e');
        }
        
        // Update Firestore profile
        await _firestoreService.updateUserProfile(
          user.uid,
          {UserFields.profileImage: null},
          user.email?.toLowerCase().endsWith('@rr.com') ?? false,
        );

        // Update Auth profile
        await user.updatePhotoURL(null);

        if (mounted) {
          setState(() {
            _currentProfileImage = null;
          });
          showMessage(context, 'Profile picture removed successfully', true);
        }
      }
    } catch (e) {
      print('Error removing profile photo: $e');
      if (mounted) {
        showMessage(context, 'Error removing profile photo: $e', false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadProfileImage(String imagePath) async {
    try {
      setState(() => _isLoading = true);
      
      final user = _auth.currentUser;
      if (user == null) return;

      // Create storage reference
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // Upload new image
      await ref.putFile(File(imagePath));
      final imageUrl = await ref.getDownloadURL();

      // Delete old image if exists
      if (_currentProfileImage != null) {
        try {
          final oldRef = FirebaseStorage.instance.refFromURL(_currentProfileImage!);
          await oldRef.delete();
        } catch (e) {
          print('Error deleting old image: $e');
        }
      }

      // Update user profile
      final isAdmin = user.email?.toLowerCase().endsWith('@rr.com') ?? false;
      await _firestoreService.updateUserProfile(
        user.uid,
        {UserFields.profileImage: imageUrl},
        isAdmin,
      );

      // Update Auth profile
      await user.updatePhotoURL(imageUrl);

      // Update local state
      if (mounted) {
        setState(() {
          _currentProfileImage = imageUrl;
        });
        showMessage(context, 'Profile picture updated successfully', true);
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      if (mounted) {
        showMessage(context, 'Error updating profile picture: $e', false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  Future<void> _showImageEditOptions(String imageUrl) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).primaryColor,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Show current image
             /*Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),*/
              // Edit options
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                title: Text(
                  'Change Photo',
                  style: AppTextStyles.bodyLarge(context),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showImagePickerOptions();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
                title: Text(
                  'Remove Photo',
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfileImage();
                },
              ),
              const SizedBox(height: 16),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.grey[200],
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
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
              leading: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isScrolled ? 0.0 : 1.0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
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
                    'Account Details',
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(24),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (_currentProfileImage != null) {
                                      _showImageEditOptions(_currentProfileImage!);
                                    } else {
                                      _showImagePickerOptions();
                                    }
                                  },
                                  child: Hero(
                                    tag: 'profileImage',
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: Provider.of<ThemeProvider>(context).isDarkMode
                                              ? LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    const Color(0xFF2C3E50).withOpacity(0.9),
                                                    const Color(0xFF3A506B).withOpacity(0.9),
                                                  ],
                                                )
                                              : LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Theme.of(context).primaryColor.withOpacity(0.1),
                                                    Theme.of(context).primaryColor.withOpacity(0.2),
                                                  ],
                                                ),
                                        ),
                                        child: _currentProfileImage != null
                                            ? CircleAvatar(
                                                radius: 50,
                                                backgroundImage: NetworkImage(_currentProfileImage!),
                                              )
                                            : Icon(
                                                Icons.person,
                                                size: 50,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      _currentProfileImage != null ? Icons.edit : Icons.add_a_photo,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _nameController.text.isNotEmpty ? _nameController.text : 'No Name',
                            style: AppTextStyles.heading2(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _emailController.text.isNotEmpty ? _emailController.text : 'No Email',
                            style: AppTextStyles.bodyMedium(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, child) {
                              return themeProvider.isDarkMode
                                  ? _buildDarkModeFields()
                                  : _buildLightModeFields();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _updateUserData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
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
                              backgroundColor: Theme.of(context).colorScheme.primary,
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
    );
  }

  Widget _buildProfileSection(BuildContext context, String label, List<Widget> children) {
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
            label,
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

  // ignore: unused_element
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

  // ignore: unused_element
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
    _scrollController.dispose();
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

  // ignore: unused_element
  Widget _buildProfileField(BuildContext context, String label, String value) {
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Provider.of<ThemeProvider>(context).isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label(context),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.bodyLarge(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.isDarkMode 
              ? Colors.white.withOpacity(0.1)
              : Theme.of(context).primaryColor.withOpacity(0.1),
        ),
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
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
              ),
      ),
      child: DropdownButtonFormField<String>(
        value: _gender,
        decoration: InputDecoration(
          labelText: 'Gender',
          labelStyle: AppTextStyles.label(context),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
        ),
        style: AppTextStyles.bodyLarge(context).copyWith(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
        ),
        dropdownColor: themeProvider.isDarkMode 
            ? const Color(0xFF2C3E50)
            : Theme.of(context).scaffoldBackgroundColor,
        icon: Icon(
          Icons.arrow_drop_down_circle,
          color: Theme.of(context).primaryColor,
        ),
        items: _genderOptions.map((String gender) {
          return DropdownMenuItem(
            value: gender,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    gender == 'Male' 
                        ? Icons.male 
                        : gender == 'Female' 
                            ? Icons.female 
                            : Icons.person_outline,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    gender,
                    style: AppTextStyles.bodyMedium(context),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() => _gender = newValue);
        },
        validator: (value) => value == null ? 'Please select your gender' : null,
        isExpanded: true,
        menuMaxHeight: 300,
        elevation: 8,
        selectedItemBuilder: (BuildContext context) {
          return _genderOptions.map<Widget>((String item) {
            return Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    item == 'Male' 
                        ? Icons.male 
                        : item == 'Female' 
                            ? Icons.female 
                            : Icons.person_outline,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item,
                    style: AppTextStyles.bodyMedium(context),
                  ),
                ],
              ),
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildDarkModeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          'Name',
          _nameController,
          Icons.person,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Email',
          _emailController,
          Icons.email,
          enabled: false,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Phone',
          _phoneController,
          Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Age',
          _ageController,
          Icons.calendar_today,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildGenderDropdown(),
      ],
    );
  }

  Widget _buildLightModeFields() {
    return _buildProfileSection(
      context,
      'Personal Information',
      [
        _buildTextField(
          'Name',
          _nameController,
          Icons.person,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Email',
          _emailController,
          Icons.email,
          enabled: false,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Phone',
          _phoneController,
          Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Age',
          _ageController,
          Icons.calendar_today,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildGenderDropdown(),
      ],
    );
  }
}
