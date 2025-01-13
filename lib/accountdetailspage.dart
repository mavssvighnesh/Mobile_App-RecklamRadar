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

  ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 0;
        _opacity = (_scrollController.offset / 180).clamp(0.0, 1.0);
      });
    });
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
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 100,
                width: 100,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 3,
                  ),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
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
                        colors: [
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
                        colors: [
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
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[200],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: themeProvider.backgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: false,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isScrolled ? 0.0 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: themeProvider.cardGradient,
                      ),
                    ),
                  ),
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isScrolled ? 0.0 : 1.0,
                    child: Text(
                      'Account Details',
                      style: AppTextStyles.heading2(context).copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(24),
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
                          _buildProfileImage(),
                          const SizedBox(height: 24),
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
                          themeProvider.isDarkMode
                              ? _buildDarkModeFields()
                              : _buildLightModeFields(),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),
                    // Action Buttons
                    ElevatedButton(
                      onPressed: _updateUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Change Password',
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showDeleteAccountDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete Account',
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Add bottom padding to ensure content is scrollable past the bottom edge
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
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
                  const Color(0xFF2C3E50).withOpacity(0.3),
                  const Color(0xFF3A506B).withOpacity(0.3),
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
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyLarge(context).copyWith(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.label(context).copyWith(
            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
          ),
          prefixIcon: Icon(
            icon,
            color: themeProvider.isDarkMode ? Colors.white70 : Theme.of(context).primaryColor,
          ),
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
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
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
                  const Color(0xFF2C3E50).withOpacity(0.3),
                  const Color(0xFF3A506B).withOpacity(0.3),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white,
                ],
              ),
      ),
      child: DropdownButtonFormField<String>(
        value: _gender,
        hint: Text(
          'Select Gender',
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        decoration: InputDecoration(
          labelText: 'Gender',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: AppTextStyles.label(context).copyWith(
            color: themeProvider.isDarkMode 
                ? const Color.fromARGB(255, 255, 255, 255) 
                : Colors.black87,
          ),
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
          filled: true,
          fillColor: themeProvider.isDarkMode 
              ? Colors.transparent 
              : Colors.white,
        ),
        selectedItemBuilder: (BuildContext context) {
          return _genderOptions.map<Widget>((String item) {
            return Container(
              alignment: Alignment.centerLeft,
              constraints: const BoxConstraints(minWidth: 100),
              child: Text(
                item,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            );
          }).toList();
        },
        items: _genderOptions.map((String gender) {
          return DropdownMenuItem(
            value: gender,
            child: Row(
              children: [
                Icon(
                  gender == 'Male' 
                      ? Icons.male 
                      : gender == 'Female' 
                          ? Icons.female 
                          : Icons.person_outline,
                  color: themeProvider.isDarkMode 
                      ? Colors.white 
                      : Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  gender,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() => _gender = newValue);
        },
        validator: (value) => value == null ? 'Please select your gender' : null,
        isExpanded: true,
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

  Widget _buildProfileImage() {
    return Center(
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
                backgroundImage: _currentProfileImage != null
                    ? NetworkImage(_currentProfileImage!)
                    : null,
                child: _currentProfileImage == null
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
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
    );
  }
}
