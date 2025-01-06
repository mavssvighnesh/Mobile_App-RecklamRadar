import 'package:flutter/material.dart';
import 'package:recklamradar/pages/store_details_page.dart';
import 'providers/theme_provider.dart';
import 'pages/favorites_page.dart';
import 'settingspage.dart';
import 'package:provider/provider.dart';

import 'cartpage.dart';
import 'services/firestore_service.dart';
import 'utils/size_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/glass_container.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
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
    // ignore: unused_local_variable
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      key: const Key('home_screen'),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: Provider.of<ThemeProvider>(context).subtleGradient,
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.grey.shade400,
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          iconSize: 24,
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
            _buildNavItem(Icons.home_rounded, 'Home'),
            _buildNavItem(Icons.search_rounded, 'Search'),
            _buildNavItem(Icons.shopping_cart_rounded, 'Cart'),
            _buildNavItem(Icons.settings_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      activeIcon: Icon(icon, size: 28),
      label: label,
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
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _navigateToStore(Map<String, dynamic> store) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreDetailsPage(
          storeId: store['id'],
          storeName: store['name'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        decoration: BoxDecoration(
          gradient: Provider.of<ThemeProvider>(context).subtleGradient,
        ),
        child: Column(
          children: [
            // Enhanced App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: Provider.of<ThemeProvider>(context).cardGradient,
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
                                color: Colors.white,
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
                        return _StoreCard(store: store);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildStoreCard(Map<String, dynamic> store) {
    return _StoreCard(store: store);
  }
}

class _StoreCard extends StatefulWidget {
  final Map<String, dynamic> store;
  
  const _StoreCard({required this.store});
  
  @override
  State<_StoreCard> createState() => _StoreCardState();
}

class _StoreCardState extends State<_StoreCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToStore() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreDetailsPage(
          storeId: widget.store['id'],
          storeName: widget.store['name'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GlassContainer(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _navigateToStore,
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Hero(
                            tag: 'store-${widget.store["id"]}',
                            child: Image.asset(
                              widget.store["image"]!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Text(
                          widget.store["name"]!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (widget.store["description"] != null)
                        Text(
                          widget.store["description"]!,
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
        },
      ),
    );
  }
}
