import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storedealspage.dart';


import 'favoritespage.dart';
import 'settingspage.dart';


import 'cartpage.dart';

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
    const HomePage(),
    FavoritesPage(),
    CartPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Removed the AppBar
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
              'assets/icons/search.png',
              color: _currentIndex == 1 ? Colors.blue : Colors.grey,
              height: 24,
            ),
            label: 'Search',
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




class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> stores = [
    {"name": "City Gross", "image": "assets/images/city_gross.png"},
    {"name": "Willys", "image": "assets/images/willys.png"},
    {"name": "Coop", "image": "assets/images/coop.png"},
    {"name": "Xtra", "image": "assets/images/xtra.png"},
    {"name": "JYSK", "image": "assets/images/jysk.png"},
    {"name": "Rusta", "image": "assets/images/rusta.png"},
    {"name": "Lidl", "image": "assets/images/lidl.png"},
    {"name": "Maxi ICA", "image": "assets/images/maxi.png"},
  ];

  bool isSearchActive = false; // Tracks whether search is active
  TextEditingController searchController = TextEditingController();
  List<dynamic> searchResults = []; // Dynamic list for search results
  List<dynamic> products = []; // List to store fetched products

  @override
  void initState() {
    super.initState();
    fetchProducts(); // Fetch products from an online API
  }

  // Fetch products from an API
  Future<void> fetchProducts() async {
    final response = await http.get(Uri.parse('https://fakestoreapi.com/products'));
    if (response.statusCode == 200) {
      setState(() {
        products = json.decode(response.body);
      });
    } else {
      print('Failed to fetch products');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if today is Friday
    bool isFriday = DateTime.now().weekday == DateTime.friday;

    // Calculate dates for "This Week" and "Next Week"
    DateTime today = DateTime.now();
    DateTime startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    DateTime startOfNextWeek = startOfWeek.add(const Duration(days: 7));
    DateTime endOfNextWeek = startOfNextWeek.add(const Duration(days: 6));

    String thisWeekDates =
        "${DateFormat('dd.MM.yyyy').format(startOfWeek)} - ${DateFormat('dd.MM.yyyy').format(endOfWeek)}";
    String nextWeekDates =
        "${DateFormat('dd.MM.yyyy').format(startOfNextWeek)} - ${DateFormat('dd.MM.yyyy').format(endOfNextWeek)}";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: isSearchActive
            ? TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: "Search products or stores...",
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  // Update search results dynamically as user types
                  setState(() {
                    searchResults = [
                      ...stores.where((store) =>
                          store["name"].toLowerCase().contains(value.toLowerCase())),
                      ...products.where((product) =>
                          product["title"].toLowerCase().contains(value.toLowerCase())),
                    ];
                  });
                },
              )
            : const Text(
                "Welcome Back!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(isSearchActive ? Icons.close : Icons.search, color: Colors.black54),
            onPressed: () {
              setState(() {
                if (isSearchActive) {
                  searchController.clear();
                  searchResults.clear(); // Clear search results when search is closed
                }
                isSearchActive = !isSearchActive;
              });
            },
          ),
          if (!isSearchActive)
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined, color: Colors.black54),
              onPressed: () {
                // Filter functionality
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Display search results or placeholder
          if (isSearchActive && searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final result = searchResults[index];
                  return ListTile(
                    leading: result.containsKey("image")
                        ? Image.asset(result["image"], width: 50, height: 50, fit: BoxFit.cover)
                        : Image.network(result["image"], width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(result["name"] ?? result["title"]),
                    onTap: () {
                      // Navigate to store deals or product details
                      if (result.containsKey("name")) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoreDealsPage(storeName: result["name"]),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Selected: ${result["title"]}")),
                        );
                      }
                    },
                  );
                },
              ),
            )
          else if (isSearchActive && searchResults.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "No results found. Try searching for something else.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),

          // Grid for Stores
          if (!isSearchActive)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Two items per row
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoreDealsPage(storeName: store["name"]),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 5,
                              spreadRadius: 1,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              store["image"],
                              height: 80,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              store["name"],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Display selection menu if today is Friday
          if (isFriday)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Reklam Options:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: "this_week",
                        child: Text("This Week: $thisWeekDates"),
                      ),
                      DropdownMenuItem(
                        value: "next_week",
                        child: Text("Next Week: $nextWeekDates"),
                      ),
                    ],
                    onChanged: (value) {
                      // Handle selection
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Selected: ${value == 'this_week' ? 'This Week' : 'Next Week'}"),
                        ),
                      );
                    },
                    hint: const Text("Select Reklam"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
