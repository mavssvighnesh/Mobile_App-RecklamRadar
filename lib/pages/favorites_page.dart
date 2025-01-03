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
        bool matchesCategory = selectedFilter == null || 
            item.category == selectedFilter;
            
        bool matchesMemberPrice = !showMemberPriceOnly || 
            item.salePrice != null;

        return matchesCategory && matchesMemberPrice;
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
            expandedHeight: SizeConfig.blockSizeVertical * 20,
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: EdgeInsets.only(bottom: 16),
              title: Text(
                'Daily Deals',
                style: AppTextStyles.heading2(context).copyWith(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -10,
                      child: Icon(
                        Icons.local_offer,
                        size: 150,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: 20,
                      child: Icon(
                        Icons.shopping_cart,
                        size: 100,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.search,
                  size: 32,
                  color: Colors.white,
                ),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: StoreSearchDelegate(
                      searchFunction: _searchItems,
                      onItemSelected: (item) {
                        // Handle item selection
                      },
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.filter_list,
                  size: 32,
                  color: Colors.white,
                ),
                onPressed: _showFilterDialog,
              ),
              const SizedBox(width: 12),
            ],
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
            ),
        ],
      ),
    );
  }

  Widget _buildItemCard(StoreItem item) {
    return ThemedCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section with fixed height
              SizedBox(
                height: maxHeight * 0.5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              size: maxWidth * 0.25,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    ),
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
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(((item.price - item.salePrice!) / item.price) * 100).round()}% OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: maxWidth * 0.06,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Content Section
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Store
                      Text(
                        item.name,
                        style: AppTextStyles.cardTitle(context).copyWith(
                          fontSize: maxWidth * 0.1,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.storeName,
                        style: AppTextStyles.cardSubtitle(context).copyWith(
                          fontSize: maxWidth * 0.08,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      // Price Section
                      if (item.salePrice != null) ...[
                        Text(
                          'SEK ${item.price}',
                          style: AppTextStyles.price(context, isOnSale: true).copyWith(
                            fontSize: maxWidth * 0.08,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'SEK ${item.salePrice}',
                          style: AppTextStyles.price(context).copyWith(
                            fontSize: maxWidth * 0.09,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else
                        Text(
                          'SEK ${item.price}',
                          style: AppTextStyles.price(context).copyWith(
                            fontSize: maxWidth * 0.09,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Quantity and Cart Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Quantity Selector
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _buildQuantityButton(
                                  icon: Icons.remove,
                                  onTap: () {
                                    if (item.quantity > 0) {
                                      setState(() => item.quantity--);
                                    }
                                  },
                                  enabled: item.quantity > 0,
                                  size: maxWidth * 0.08,
                                ),
                                Container(
                                  width: maxWidth * 0.15,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: TextStyle(
                                      fontSize: maxWidth * 0.08,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _buildQuantityButton(
                                  icon: Icons.add,
                                  onTap: () {
                                    if (item.quantity < 99) {
                                      setState(() => item.quantity++);
                                    }
                                  },
                                  enabled: item.quantity < 99,
                                  size: maxWidth * 0.08,
                                ),
                              ],
                            ),
                          ),
                          // Cart Button
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  if (item.quantity == 0) {
                                    showMessage(
                                      context, 
                                      'Please select quantity', 
                                      false,
                                    );
                                    return;
                                  }
                                  try {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user != null) {
                                      await _firestoreService.addToCart(
                                        user.uid,
                                        item,
                                        item.storeName,
                                      );
                                      if (mounted) {
                                        showMessage(
                                          context, 
                                          '${item.quantity}x ${item.name} added to cart', 
                                          true,
                                        );
                                        setState(() {
                                          item.quantity = 0; // Reset quantity after adding to cart
                                        });
                                      }
                                    }
                                  } catch (e) {
                                    print('Error adding to cart: $e');
                                    if (mounted) {
                                      showMessage(
                                        context, 
                                        'Failed to add item to cart', 
                                        false,
                                      );
                                    }
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.add_shopping_cart,
                                    size: maxWidth * 0.1,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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