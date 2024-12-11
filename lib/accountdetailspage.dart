import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import 'passwordpage.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  _AccountDetailsPageState createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final TextEditingController _nameController = TextEditingController(text: "Vighnesh Mandaleeka");
  final TextEditingController _ageController = TextEditingController(text: "20");
  final TextEditingController _phoneController = TextEditingController(text: "+46 734807115");
  final TextEditingController _emailController = TextEditingController(text: "Vighneshmandaleeka@gmai.com");
  String _selectedGender = "Female";
  bool _isEditing = false;

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Profile Section
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/images/user_avatar.jpg'), // Replace with your avatar asset
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Vighnesh Mandaleeka",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "@Mavssv",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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
                  icon: Icon(_isEditing ? Icons.done : Icons.edit, color: Colors.blue),
                  onPressed: () {
                    setState(() {
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
            _buildEditableField("Age", _ageController, _isEditing, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildEditableField("Phone Number", _phoneController, _isEditing, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildEditableField("Email Address", _emailController, _isEditing, keyboardType: TextInputType.emailAddress),
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
}

