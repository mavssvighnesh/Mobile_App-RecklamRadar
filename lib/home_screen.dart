import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storedealspage.dart';
import 'providers/theme_provider.dart';
import 'storedealspage.dart';
import 'favoritespage.dart';
import 'settingspage.dart';


import 'cartpage.dart';
import 'services/firestore_service.dart';
import 'models/store.dart';
import 'models/deal.dart';

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
    const FavoritesPage(),
    const CartPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: ThemeProvider.subtleGradient,
          ),
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _pages,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface.withOpacity(0.9),
              theme.colorScheme.surface.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.grey.shade400,
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
        ),
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
  final FirestoreService _firestoreService = FirestoreService();
  bool isSearchActive = false;
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  
  bool get isFriday => DateTime.now().weekday == DateTime.friday;
  
  String get thisWeekDates {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return '${DateFormat('MMM d').format(monday)} - ${DateFormat('MMM d').format(sunday)}';
  }
  
  String get nextWeekDates {
    final now = DateTime.now();
    final nextMonday = now.add(Duration(days: 8 - now.weekday));
    final nextSunday = nextMonday.add(const Duration(days: 6));
    return '${DateFormat('MMM d').format(nextMonday)} - ${DateFormat('MMM d').format(nextSunday)}';
  }

  Future<void> performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults.clear();
      });
      return;
    }

    try {
      final storeSnapshot = await _firestoreService.searchStores(query);
      final stores = storeSnapshot.docs.map((doc) {
        final store = Store.fromFirestore(doc);
        return {
          "name": store.name,
          "image": store.imageUrl,
          "isStore": true,
        };
      }).toList();

      setState(() {
        searchResults = stores;
      });
    } catch (e) {
      print('Error performing search: $e');
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: isSearchActive
            ? TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: "Search products or stores...",
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  performSearch(value);
                },
              )
            : const Text("ReklamRadar"),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeProvider.subtleGradient,
        ),
        child: Column(
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
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getStores(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final stores = snapshot.data?.docs
                      .map((doc) => Store.fromFirestore(doc))
                      .toList() ?? [];

                  return GridView.builder(
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      crossAxisSpacing: MediaQuery.of(context).size.width * 0.04,
                      mainAxisSpacing: MediaQuery.of(context).size.width * 0.04,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: stores.length,
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StoreDealsPage(storeName: store.name),
                            )
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.9),
                                Colors.white.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                store.imageUrl,
                                height: 80,
                                width: 80,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                store.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Display selection menu if today is Friday
            if (isFriday)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
                  ),
                ),
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
      ),
    );
  }
}
