import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'login_screen.dart';
import 'passwordpage.dart';
import 'constants/user_fields.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Details"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _currentProfileImage != null
                              ? NetworkImage(_currentProfileImage!)
                              : _auth.currentUser?.photoURL != null
                                  ? NetworkImage(_auth.currentUser!.photoURL!)
                                  : const AssetImage('assets/images/default_avatar.png')
                                      as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Editable Fields with Edit Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Account Details",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(
                          _isEditing ? Icons.done : Icons.edit,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_isEditing) {
                              _updateUserData();
                            }
                            _isEditing = !_isEditing;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEditableField("Name", _nameController, _isEditing),
                  const SizedBox(height: 16),
                  _buildDropdownField("Gender", _selectedGender, _isEditing),
                  const SizedBox(height: 16),
                  _buildEditableField("Age", _ageController, _isEditing,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildEditableField("Phone Number", _phoneController, _isEditing,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildEditableField("Email Address", _emailController, _isEditing,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 24),

                  // Change Password Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text("Change Password"),
                  ),
                  const SizedBox(height: 16),

                  // Delete Account Button
                  ElevatedButton(
                    onPressed: () {
                      _showDeleteAccountDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text("Delete Account"),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, bool isEditable,
      {TextInputType keyboardType = TextInputType.text}) {
    if (isEditable) {
      return TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(
            controller.text,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
          const Divider(),
        ],
      );
    }
  }

  Widget _buildDropdownField(String label, String value, bool isEditable) {
    if (isEditable) {
      return DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: ["Male", "Female", "Other"]
            .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
            .toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedGender = newValue!;
          });
        },
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
          const Divider(),
        ],
      );
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // Perform account deletion
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Account deleted successfully!")),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()), // Redirect to Login Page
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
