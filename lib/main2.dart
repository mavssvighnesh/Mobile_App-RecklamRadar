import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isUserSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: Text(
                    'User',
                    style: TextStyle(
                        color: isUserSelected ? Colors.white : Colors.black),
                  ),
                  selected: isUserSelected,
                  onSelected: (selected) {
                    setState(() {
                      isUserSelected = true;
                    });
                  },
                  selectedColor: Colors.blue,
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(
                    'Business',
                    style: TextStyle(
                        color: !isUserSelected ? Colors.white : Colors.black),
                  ),
                  selected: !isUserSelected,
                  onSelected: (selected) {
                    setState(() {
                      isUserSelected = false;
                    });
                  },
                  selectedColor: Colors.blue,
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Forgot password action
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (isUserSelected) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserHomeScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminHomeScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }
}



class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0; // To keep track of the selected tab
  final PageController _pageController = PageController();

  // List of page widgets for roll-over transitions
  final List<Widget> _pages = [
    HomePage(),
    FavoritesPage(),
    CartPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Welcome Back!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black54),
            onPressed: () {
              // Search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.black54),
            onPressed: () {
              // Filter functionality
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/icons/home.png',
              color: _currentIndex == 0 ? Colors.blue : Colors.grey,
              height: 24,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/icons/favorites.png',
              color: _currentIndex == 1 ? Colors.blue : Colors.grey,
              height: 24,
            ),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/icons/cart.png',
              color: _currentIndex == 2 ? Colors.blue : Colors.grey,
              height: 24,
            ),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/icons/settings.png',
              color: _currentIndex == 3 ? Colors.blue : Colors.grey,
              height: 24,
            ),
            label: 'Settings',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

// Individual pages for each tab
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Favorites Page'));
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Cart Page'));
  }
}





class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
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
                    backgroundImage: AssetImage('assets/images/user_avatar.png'), // Replace with your avatar asset
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Olivia Smith",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "@oliviasmith",
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
                    DropdownMenuItem(value: "Spanish", child: Text("Spanish")),
                    DropdownMenuItem(value: "French", child: Text("French")),
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
                  value: "USD",
                  items: const [
                    DropdownMenuItem(value: "USD", child: Text("USD")),
                    DropdownMenuItem(value: "EUR", child: Text("EUR")),
                    DropdownMenuItem(value: "INR", child: Text("INR")),
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
                    MaterialPageRoute(builder: (context) => AccountDetailsPage()),
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
                    MaterialPageRoute(builder: (context) => LoginPage()),
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
          ],
        ),
      ),
    );
  }
}

// Placeholder for Login Page
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Login Screen",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// Placeholder for Account Details Page
class AccountDetailsPage extends StatelessWidget {
  const AccountDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Details"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "Account Details Page",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// Full-Screen Photo Page
class FullScreenPhotoPage extends StatelessWidget {
  final String imagePath;

  const FullScreenPhotoPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}




// Placeholder Screens for Navigation
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: const Center(child: Text('Favorites Page')),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: const Center(child: Text('Cart Page')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings Page')),
    );
  }
}


class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stores Available'),
      ),
      body: ListView(
        children: const [
          StoreTile(storeName: 'City Gross'),
          StoreTile(storeName: 'Willys'),
          StoreTile(storeName: 'Lidl'),
          StoreTile(storeName: 'ICA Maxi'),
          StoreTile(storeName: 'Rusta'),
          StoreTile(storeName: 'Xtra'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ItemAddingPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class StoreTile extends StatelessWidget {
  final String storeName;

  const StoreTile({super.key, required this.storeName});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(storeName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AdminStoreScreen(storeName: storeName)),
        );
      },
    );
  }
}



class AdminStoreScreen extends StatelessWidget {
  final String storeName;

  const AdminStoreScreen({super.key, required this.storeName});

  @override
  Widget build(BuildContext context) {
    // List of items with additional data
    final List<Map<String, String>> items = [
      {
        "name": "Carrots",
        "price": "SEK 11.99/KG",
        "memberPrice": "SEK 9.99/KG",
        "dateRange": "2024-01-01 to 2024-01-15",
        "image": "assets/images/carrots.png"
      },
      {
        "name": "Cabbage",
        "price": "SEK 15.99/KG",
        "memberPrice": "SEK 13.99/KG",
        "dateRange": "2024-01-05 to 2024-01-20",
        "image": "assets/images/cabbage.png"
      },
      {
        "name": "Beetroot",
        "price": "SEK 19.99/KG",
        "memberPrice": "SEK 16.99/KG",
        "dateRange": "2024-01-10 to 2024-01-25",
        "image": "assets/images/beetroot.png"
      },

    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(storeName),
      ),
      body: ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final item = items[index];
    return InteractiveItemCard(item: item);
  },
),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ItemAddingPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class InteractiveItemCard extends StatelessWidget {
  final Map<String, String> item;

  const InteractiveItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final String name = item["name"]!;
    final String price = item["price"]!;
    final String memberPrice = item["memberPrice"] ?? "N/A";
    final String dateRange = item["dateRange"] ?? "No Date Range";
    final String image = item["image"]!;

    return GestureDetector(
      onTap: () {
        // Action when the card is tapped
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name clicked!')),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      size: 60,
                      color: Colors.grey.shade400,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Regular Price: $price",
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    Text(
                      "Member Price: $memberPrice",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Available: $dateRange",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class ItemAddingPage extends StatefulWidget {
  const ItemAddingPage({super.key});

  @override
  _ItemAddingPageState createState() => _ItemAddingPageState();
}

class _ItemAddingPageState extends State<ItemAddingPage> {
  String? selectedStore; // Selected store from the dropdown
  DateTimeRange? dateRange; // Date range for availability

  // List of store options
  final List<String> stores = ["City Gross", "Willys", "Lidl", "Rusta", "Xtra"];

  // Method to pick date range
  Future<void> pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: dateRange,
    );
    if (picked != null) {
      setState(() {
        dateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload New Ad'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Dropdown for selecting store
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Store',
                border: OutlineInputBorder(),
              ),
              value: selectedStore,
              items: stores
                  .map((store) => DropdownMenuItem<String>(
                        value: store,
                        child: Text(store),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedStore = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Ad Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  items: ['KG', 'ST']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {},
                  hint: const Text('Unit'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Member Price (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => pickDateRange(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dateRange == null
                      ? 'Select Date Range'
                      : '${dateRange!.start.toLocal()} to ${dateRange!.end.toLocal()}',
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (selectedStore == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a store!')),
                  );
                  return;
                }

                // Action to upload ad
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Ad uploaded for store: $selectedStore successfully!')),
                );
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}













