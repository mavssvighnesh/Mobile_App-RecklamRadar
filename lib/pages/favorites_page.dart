import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_item.dart';
import '../utils/size_config.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import '../utils/message_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:recklamradar/styles/app_text_styles.dart';
import 'package:recklamradar/widgets/themed_card.dart';
import '../utils/debouncer.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  List<StoreItem> allItems = [];
  List<StoreItem> filteredItems = [];
  bool isLoading = false;
  String? selectedFilter;
  Set<String> categories = {};
  Set<String> stores = {};
  final _debouncer = Debouncer(milliseconds: 500);
  String selectedSort = 'Name'; // Default sort
  bool showMemberPriceOnly = false;
  bool isFilterActive = false;
  bool isFilterVisible = false;
  List<String> recentSearches = [];
  List<String> popularCategories = [
    'Fruits',
    'Vegetables',
    'Dairy',
    'Meat',
    'Beverages',
    // Add more categories
  ];
  
  String? selectedStore;
  bool isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadRandomDeals(); // Load random deals on start
  }

  Future<void> _loadInitialData() async {
    try {
      final storesSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .get();
      
      if (mounted) {
        setState(() {
          stores = storesSnapshot.docs.map((doc) => doc.id).toSet();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  Future<void> _searchItems(String query) async {
    if (query.isNotEmpty && !recentSearches.contains(query)) {
      setState(() {
        recentSearches.insert(0, query);
        if (recentSearches.length > 5) {
          recentSearches.removeLast();
        }
      });
    }

    if (query.isEmpty) {
      setState(() {
        filteredItems = [];
        return;
      });
    }

    setState(() => isLoading = true);

    try {
      List<StoreItem> searchResults = [];
      
      // Get all numbered store documents (1, 2, 3, etc.)
      final storeNumbers = ['1', '2', '3', '4', '5', '6', '7', '8']; // Add all store numbers you have
      
      // Search through each store
      for (String storeNumber in storeNumbers) {
        try {
          print('Searching in store $storeNumber...'); // Debug print
          
          // Get items subcollection from the store document
          final itemsSnapshot = await FirebaseFirestore.instance
              .collection('stores')
              .doc(storeNumber)
              .collection('items')
              .get();

          print('Found ${itemsSnapshot.docs.length} items in store $storeNumber'); // Debug print

          // Check each item document
          for (var doc in itemsSnapshot.docs) {
            final data = doc.data();
            final itemName = (data['name'] ?? '').toString().toLowerCase();
            
            // Check if item name contains search query
            if (itemName.contains(query.toLowerCase())) {
              print('Match found: ${data['name']} in store $storeNumber'); // Debug print
              
              searchResults.add(StoreItem(
                id: doc.id,
                name: data['name'] ?? '',
                category: data['category'] ?? '',
                price: (data['price'] as num).toDouble(),
                salePrice: data['memberPrice'] != null ? 
                    (data['memberPrice'] as num).toDouble() : null,
                imageUrl: data['imageUrl'] ?? '',
                unit: data['unit'] ?? '',
                inStock: data['inStock'] ?? true,
                quantity: 0,
                storeName: _getStoreName(storeNumber),
              ));
            }
          }
        } catch (e) {
          print('Error searching store $storeNumber: $e'); // Debug print
          continue; // Continue with next store if one fails
        }
      }

      // Sort results by relevance
      searchResults.sort((a, b) {
        final aNameMatch = a.name.toLowerCase().contains(query.toLowerCase());
        final bNameMatch = b.name.toLowerCase().contains(query.toLowerCase());
        
        if (aNameMatch && !bNameMatch) return -1;
        if (!aNameMatch && bNameMatch) return 1;
        
        return a.name.compareTo(b.name);
      });

      if (mounted) {
        setState(() {
          filteredItems = searchResults;
          categories = searchResults.map((item) => item.category).toSet();
          isLoading = false;
        });
        
        print('Total results found: ${searchResults.length}'); // Debug print
      }
    } catch (e) {
      print('Error searching items: $e');
      if (mounted) {
        showMessage(context, 'Error searching items', false);
        setState(() => isLoading = false);
      }
    }
  }

  // Helper function to convert store number to store name
  String _getStoreName(String storeId) {
    switch (storeId) {
      case '1':
        return 'City Gross';
      case '2':
        return 'Willys';
      case '3':
        return 'Lidl';
      case '4':
        return 'ICA Maxi';
      case '6':
        return 'Rusta';
      case '7':
        return 'Xtra';
      case '8':
        return 'Coop';
      default:
        return 'Store $storeId';
    }
  }

  void _applyFilter(String? filter) {
    if (filter == null) {
      setState(() {
        selectedFilter = null;
        _searchItems(_searchController.text);
      });
      return;
    }

    setState(() {
      selectedFilter = filter;
      filteredItems = filteredItems.where((item) {
        return item.category == filter || item.storeName == filter;
      }).toList();
    });
  }

  Future<void> _loadRandomDeals() async {
    setState(() => isLoading = true);
    try {
      List<StoreItem> deals = [];
      final storeNumbers = ['1', '2', '3', '4', '5', '6', '7', '8'];
      
      // Shuffle store numbers to randomize store order
      storeNumbers.shuffle();
      
      for (String storeNumber in storeNumbers) {
        try {
          final itemsSnapshot = await FirebaseFirestore.instance
              .collection('stores')
              .doc(storeNumber)
              .collection('items')
              .get();

          // Convert all items to list and shuffle them
          final items = itemsSnapshot.docs.map((doc) {
            final data = doc.data();
            return StoreItem(
              id: doc.id,
              name: data['name'] ?? '',
              category: data['category'] ?? '',
              price: (data['price'] as num).toDouble(),
              salePrice: data['memberPrice'] != null ? 
                  (data['memberPrice'] as num).toDouble() : null,
              imageUrl: data['imageUrl'] ?? '',
              unit: data['unit'] ?? '',
              inStock: data['inStock'] ?? true,
              quantity: 0,
              storeName: _getStoreName(storeNumber),
            );
          }).toList();

          // Shuffle items and take random number between 2 and 6
          items.shuffle();
          final randomCount = 2 + (DateTime.now().millisecondsSinceEpoch % 4);
          deals.addAll(items.take(randomCount));
        } catch (e) {
          print('Error loading deals from store $storeNumber: $e');
        }
      }

      // Final shuffle of all deals
      deals.shuffle();

      if (mounted) {
        setState(() {
          filteredItems = deals;
          allItems = deals;
          categories = deals.map((item) => item.category).toSet();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading random deals: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _sortItems() {
    setState(() {
      switch (selectedSort) {
        case 'Name':
          filteredItems.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'Price (Low to High)':
          filteredItems.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'Price (High to Low)':
          filteredItems.sort((a, b) => b.price.compareTo(a.price));
          break;
      }
    });
  }

  void _filterItems() {
    setState(() {
      filteredItems = allItems.where((item) {
        // Store filter
        bool matchesStore = selectedStore == null || 
            item.storeName == _getStoreName(selectedStore!);
            
        // Category filter
        bool matchesCategory = selectedFilter == null || 
            item.category == selectedFilter;
            
        // Member price filter - Show items with actual discounts
        bool matchesMemberPrice = !showMemberPriceOnly || 
            (item.salePrice != null && item.salePrice! < item.price);

        return matchesStore && matchesCategory && matchesMemberPrice;
      }).toList();
      
      _sortItems();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Filter & Sort",
                style: AppTextStyles.heading3(context),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Category", style: AppTextStyles.bodyLarge(context)),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: selectedFilter,
                      items: [
                        const DropdownMenuItem(value: null, child: Text("All Categories")),
                        ...categories.map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => selectedFilter = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text("Sort By", style: AppTextStyles.bodyLarge(context)),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: selectedSort,
                      items: [
                        'Name',
                        'Price (Low to High)',
                        'Price (High to Low)',
                      ].map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      )).toList(),
                      onChanged: (value) {
                        setState(() => selectedSort = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Show Only Sale Items",
                          style: AppTextStyles.bodyLarge(context),
                        ),
                        Switch(
                          value: showMemberPriceOnly,
                          onChanged: (value) {
                            setState(() => showMemberPriceOnly = value);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _filterItems();
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: isFilterVisible 
                ? SizeConfig.blockSizeVertical * 45 
                : SizeConfig.blockSizeVertical * 15,
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 0,
            title: isSearchActive 
                ? Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.8)),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.8)),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              isSearchActive = false;
                              _loadRandomDeals();
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (query) {
                        _debouncer.run(() {
                          _searchItems(query);
                        });
                      },
                    ),
                  )
                : Text(
                    'Daily Deals',
                    style: AppTextStyles.heading2(context).copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            actions: [
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
                      _searchController.clear();
                      _loadRandomDeals();
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  isFilterVisible ? Icons.filter_list_off : Icons.filter_list,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    isFilterVisible = !isFilterVisible;
                  });
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: Provider.of<ThemeProvider>(context).cardGradient,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: kToolbarHeight + 20),
                    if (isFilterVisible) ...[
                      const SizedBox(height: 16),
                      // Filter Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Store Selection
                              _buildFilterDropdown(
                                title: 'Store',
                                value: selectedStore,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('All Stores'),
                                  ),
                                  ...['1', '2', '3', '4', '5', '6', '7', '8'].map((store) => 
                                    DropdownMenuItem(
                                      value: store,
                                      child: Text(_getStoreName(store)),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedStore = value as String?;
                                    _filterItems();
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              // Category Selection
                              _buildFilterDropdown(
                                title: 'Category',
                                value: selectedFilter,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('All Categories'),
                                  ),
                                  ...categories.map((category) => 
                                    DropdownMenuItem(
                                      value: category,
                                      child: Text(category),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedFilter = value as String?;
                                    _filterItems();
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              // Sort and Member Price Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFilterDropdown(
                                      title: 'Sort By',
                                      value: selectedSort,
                                      items: [
                                        'Name',
                                        'Price (Low to High)',
                                        'Price (High to Low)',
                                      ].map((option) => DropdownMenuItem(
                                        value: option,
                                        child: Text(option),
                                      )).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedSort = value as String;
                                          _filterItems();
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Member Price Toggle with improved styling
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Member Price',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Switch(
                                          value: showMemberPriceOnly,
                                          onChanged: (value) {
                                            setState(() {
                                              showMemberPriceOnly = value;
                                              _filterItems();
                                            });
                                          },
                                          activeColor: Colors.white,
                                          activeTrackColor: Colors.green,
                                          inactiveThumbColor: Colors.white.withOpacity(0.8),
                                          inactiveTrackColor: Colors.white.withOpacity(0.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_searchController.text.isEmpty)
            SliverPadding(
              padding: EdgeInsets.all(SizeConfig.blockSizeHorizontal * 2),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  childAspectRatio: 0.65, // Slightly taller cards
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildItemCard(filteredItems[index]),
                  childCount: filteredItems.length,
                ),
              ),
            )
          else if (filteredItems.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No items found for "${_searchController.text}"',
                      style: AppTextStyles.bodyLarge(context),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  childAspectRatio: 0.7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildItemCard(filteredItems[index]),
                  childCount: filteredItems.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemCard(StoreItem item) {
    return ThemedCard(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(item.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store name
                    Text(
                      item.storeName,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Item name
                    Text(
                      item.name,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Price with unit
                    Text(
                      item.formattedPrice,
                      style: TextStyle(
                        color: item.salePrice != null ? Colors.green : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: item.salePrice != null ? 16 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Member price badge if applicable
          if (item.salePrice != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'MEMBER PRICE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
    required double size,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            size: size,
            color: enabled 
                ? Theme.of(context).primaryColor 
                : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return ListView(
      children: [
        if (recentSearches.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Recent Searches',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ...recentSearches.map((search) => ListTile(
            leading: const Icon(Icons.history),
            title: Text(search),
            onTap: () {
              _searchController.text = search;
              _searchItems(search);
            },
          )),
          const Divider(),
        ],
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Popular Categories',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ...popularCategories.map((category) => ListTile(
          leading: const Icon(Icons.category),
          title: Text(category),
          onTap: () {
            setState(() {
              selectedFilter = category;
              _filterItems();
            });
          },
        )),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String title,
    required dynamic value,
    required List<DropdownMenuItem> items,
    required Function(dynamic) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton(
              isExpanded: true,
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: Theme.of(context).primaryColor.withOpacity(0.95),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class StoreSearchDelegate extends SearchDelegate<StoreItem> {
  final Future<void> Function(String) searchFunction;
  final Function(StoreItem) onItemSelected;

  StoreSearchDelegate({
    required this.searchFunction,
    required this.onItemSelected,
  });

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, StoreItem(
          id: '',
          name: '',
          category: '',
          price: 0,
          imageUrl: '',
          storeName: '',
          quantity: 0, 
          unit: '',
        ));
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    searchFunction(query);
    return Container(); // Results will be shown in the main page
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(); // You can add search suggestions here
  }
} 