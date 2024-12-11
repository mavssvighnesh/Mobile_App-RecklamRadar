import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'accountdetailspage.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

 @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Card(
                child: ListTile(
                  title: const Text("Language"),
                  trailing: DropdownButton<String>(
                    value: "English",
                    items: const [
                      DropdownMenuItem(value: "English", child: Text("English")),
                      DropdownMenuItem(value: "Svenska", child: Text("Svenska")),
                      DropdownMenuItem(value: "Español", child: Text("Español")),
                      DropdownMenuItem(value: "Français", child: Text("français")),
                    ],
                    onChanged: (value) {
                      // Handle language selection
                    },
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text("Currency"),
                  trailing: DropdownButton<String>(
                    value: "SEK",
                    items: const [
                      DropdownMenuItem(value: "SEK", child: Text("SEK")),
                      DropdownMenuItem(value: "INR", child: Text("INR")),
                      DropdownMenuItem(value: "USD", child: Text("USD")),
                      DropdownMenuItem(value: "EUR", child: Text("EUR")),
                      
                    ],
                    onChanged: (value) {
                      // Handle currency selection
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Appearance Section
              Text(
                "Appearance",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Handle light theme selection
                        },
                        child: const Column(
                          children: [
                            Icon(Icons.light_mode, color: Colors.blue),
                            SizedBox(height: 4),
                            Text("Light"),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Handle dark theme selection
                        },
                        child: const Column(
                          children: [
                            Icon(Icons.dark_mode, color: Colors.grey),
                            SizedBox(height: 4),
                            Text("Dark"),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Handle system theme selection
                        },
                        child: const Column(
                          children: [
                            Icon(Icons.brightness_auto, color: Colors.grey),
                            SizedBox(height: 4),
                            Text("System"),
                          ],
                        ),
                      ),
                    ],
                  ),
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
              Card(
                child: ListTile(
                  title: const Text("Account"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to Account Details Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AccountDetailsPage()),
                    );
                  },
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text("Logout"),
                  onTap: () {
                    // Navigate back to the login screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Footer Section
              Text(
                "Version 1.0.0. For support, visit our help center or contact us at support@example.com. "
                "We are here to assist you with any issues or questions you may have.",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
          ]
       ),
      ),
    );
  }
}    
