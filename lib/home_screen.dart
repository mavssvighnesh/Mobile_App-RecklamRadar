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
import 'utils/size_config.dart';
import 'widgets/store_card.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
              icon: SizedBox(
                height: SizeConfig.blockSizeVertical * 3,
                width: SizeConfig.blockSizeVertical * 3,
                child: Image.asset(
                  'assets/icons/home.png',
                  color: _currentIndex == 0 ? Colors.blue : Colors.grey,
                ),
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isSearchActive = false;
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> stores = [];
  bool isLoading = true;
  String userName = '';

  @override
  void initState() {
    super.initState();
    loadStores();
    loadUserName();
  }

  Future<void> loadUserName() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final userData = await _firestoreService.getUserProfile(userId);
        if (mounted && userData != null) {
          setState(() {
            userName = userData['name'] ?? 'User';
          });
        }
      }
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  Future<void> loadStores() async {
    try {
      setState(() => isLoading = true);
      
      final storesList = [
        {
          "id": "1",
          "name": "City Gross",
          "image": "assets/images/stores/city_gross.png",
          "description": "City Gross Supermarket",
        },
        {
          "id": "2",
          "name": "Willys",
          "image": "assets/images/stores/willys.png",
          "description": "Willys Supermarket",
        },
        {
          "id": "3",
          "name": "Coop",
          "image": "assets/images/stores/coop.png",
          "description": "Coop Supermarket",
        },
        {
          "id": "4",
          "name": "Xtra",
          "image": "assets/images/stores/xtra.png",
          "description": "Xtra Supermarket",
        },
        {
          "id": "5",
          "name": "JYSK",
          "image": "assets/images/stores/jysk.png",
          "description": "JYSK Store",
        },
        {
          "id": "6",
          "name": "Rusta",
          "image": "assets/images/stores/rusta.png",
          "description": "Rusta Store",
        },
        {
          "id": "7",
          "name": "Lidl",
          "image": "assets/images/stores/lidl.png",
          "description": "Lidl Supermarket",
        },
        {
          "id": "8",
          "name": "Maxi",
          "image": "assets/images/stores/maxi.png",
          "description": "Maxi ICA Stormarknad",
        },
      ];

      setState(() {
        stores = storesList;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading stores: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        decoration: BoxDecoration(
          gradient: ThemeProvider.subtleGradient,
        ),
        child: Column(
          children: [
            // Enhanced App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: ThemeProvider.cardGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome Back!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            isSearchActive ? Icons.close : Icons.search,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              isSearchActive = !isSearchActive;
                              if (!isSearchActive) {
                                searchController.clear();
                                // Reset search results
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (isSearchActive) ...[
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search stores...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context).primaryColor,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                // Reset search results
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                          onChanged: (value) {
                            // Implement search functionality
                            // Filter stores based on search query
                            setState(() {
                              if (value.isEmpty) {
                                searchResults = stores;
                              } else {
                                searchResults = stores
                                    .where((store) => store["name"]!
                                        .toLowerCase()
                                        .contains(value.toLowerCase()))
                                    .toList();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Stores Grid
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: isSearchActive ? searchResults.length : stores.length,
                      itemBuilder: (context, index) {
                        final store = isSearchActive ? searchResults[index] : stores[index];
                        return _buildStoreCard(store);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to store details
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      store["image"]!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  store["name"]!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  store["description"]!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
