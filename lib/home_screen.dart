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
    return Material(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Your existing content
                  if (isFriday) 
                    Container(
                      // Your Friday container content
                    ),
                  Container(
                    height: constraints.maxHeight * 0.8,
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        crossAxisSpacing: SizeConfig.blockSizeHorizontal * 2,
                        mainAxisSpacing: SizeConfig.blockSizeVertical * 2,
                      ),
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final store = searchResults[index];
                        return StoreCard(store: store);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
