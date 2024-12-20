import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:recklamradar/constants/user_fields.dart';
import 'services/auth_service.dart';
import 'home_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:recklamradar/admin_home_screen.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _gender;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isBusiness = false;
  File? _profileImage;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
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
                  final XFile? pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 75,
                  );
                  if (pickedFile != null) {
                    setState(() => _profileImage = File(pickedFile.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 75,
                  );
                  if (pickedFile != null) {
                    setState(() => _profileImage = File(pickedFile.path));
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

  Future<String?> _uploadImage(String userId) async {
    if (_profileImage == null) return null;
    
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('$userId.jpg');
          
      await ref.putFile(_profileImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile picture')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final isBusiness = email.toLowerCase().endsWith('@rr.com');
      
      // Upload image first
      String? imageUrl;
      if (_profileImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
            
        await ref.putFile(_profileImage!);
        imageUrl = await ref.getDownloadURL();
      }

      // Register user with image URL
      final result = await _auth.signUpWithEmail(
        email,
        _passwordController.text.trim(),
        _nameController.text.trim(),
        isBusiness,
        imageUrl,
      );

      if (result != null && mounted) {
        // Additional profile data
        await _auth.updateUserProfile(
          result.user!.uid,
          {
            UserFields.phone: _phoneController.text.trim(),
            UserFields.age: int.tryParse(_ageController.text.trim()),
            UserFields.gender: _gender,
            UserFields.isBusiness: isBusiness,
          },
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => isBusiness 
                  ? const AdminHomeScreen()
                  : const UserHomeScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _profileImage != null 
                        ? FileImage(_profileImage!) 
                        : null,
                    child: _profileImage == null
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => 
                    value?.isEmpty ?? true ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  hintText: 'example@gmail.com',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter an email';
                  }
                  if (!value!.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  if (!value.toLowerCase().endsWith('@gmail.com') && 
                      !value.toLowerCase().endsWith('@rr.com')) {
                    return 'Please use a Gmail or RR email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible 
                        ? Icons.visibility_off 
                        : Icons.visibility),
                    onPressed: () => setState(() => 
                        _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter a password';
                  if (value!.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => 
                    value?.isEmpty ?? true ? 'Please enter your phone number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter your age';
                  final age = int.tryParse(value!);
                  if (age == null || age < 18) return 'You must be at least 18 years old';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: ['Male', 'Female', 'Other']
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _gender = value),
                validator: (value) => 
                    value == null ? 'Please select your gender' : null,
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Business Account'),
                subtitle: const Text('Switch to create a business account'),
                value: _isBusiness,
                onChanged: (bool value) {
                  setState(() {
                    _isBusiness = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register with Email'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading 
                    ? null 
                    : () async {
                        setState(() => _isLoading = true);
                        try {
                          final result = await _auth.signInWithGoogle();
                          if (result != null && mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UserHomeScreen(),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Google sign-up failed: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                icon: const FaIcon(FontAwesomeIcons.google),
                label: const Text('Sign up with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}
