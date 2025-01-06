import 'dart:async';
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
import '../services/currency_service.dart';
import '../utils/price_formatter.dart';

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
  final CurrencyService _currencyService = CurrencyService();
  StreamSubscription? _currencySubscription;

  // Update the store mapping
  final Map<String, String> _storeNames = {
    '1': 'City Gross',
    '2': 'Willys',
    '3': 'Lidl',
    '4': 'ICA Maxi',
    '5': 'JYSK',
    '6': 'Rusta',
    '7': 'Xtra',
    '8': 'Coop',
  };

  // Add caching for search results
  final Map<String, List<StoreItem>> _searchCache = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadRandomDeals(); // Load random deals on start
    _currencySubscription = _currencyService.currencyStream.listen((_) {
      if (mounted) setState(() {}); // Refresh to update prices
    });
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
    if (!mounted) return;
    
    _debouncer.run(() async {
      setState(() => isLoading = true);
      
      try {
        if (query.isEmpty) {
          await _loadRandomDeals();
          return;
        }

        // Check cache first
        final cacheKey = query.toLowerCase();
        if (_searchCache.containsKey(cacheKey)) {
          setState(() {
            filteredItems = _searchCache[cacheKey]!;
            categories = filteredItems.map((item) => item.category).toSet();
            isLoading = false;
          });
          return;
        }

        // Optimize query
        final queryWords = query.toLowerCase().split(' ')
            .where((word) => word.length > 1)  // Ignore single characters
            .toSet()  // Remove duplicates
            .toList();
        
        if (queryWords.isEmpty) {
          await _loadRandomDeals();
          return;
        }

        List<StoreItem> searchResults = [];
        final storeNumbers = _storeNames.keys.toList();
        
        // Parallel store fetching
        final futures = storeNumbers.map((storeNumber) async {
          try {
            final snapshot = await FirebaseFirestore.instance
                .collection('stores')
                .doc(storeNumber)
                .collection('items')
                .get();

            return snapshot.docs
                .where((doc) {
                  final data = doc.data();
                  final searchText = '${data['name']} ${data['category']}'.toLowerCase();
                  return queryWords.any((word) => 
                    searchText.contains(word) || 
                    _findSimilarMatches(searchText, word)
                  );
                })
                .map((doc) {
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
                })
                .toList();
          } catch (e) {
            print('Error searching store $storeNumber: $e');
            return <StoreItem>[];
          }
        });

        // Wait for all store searches to complete
        final results = await Future.wait(futures);
        searchResults = results.expand((x) => x).toList();

        // Cache results
        _searchCache[cacheKey] = searchResults;

        if (mounted) {
          setState(() {
            filteredItems = searchResults;
            categories = searchResults.map((item) => item.category).toSet();
            isLoading = false;
          });
        }
      } catch (e) {
        print('Error searching items: $e');
        if (mounted) {
          setState(() => isLoading = false);
          showMessage(context, 'Error searching items', false);
        }
      }
    });
  }

  // Add helper method for similar word matching
  bool _findSimilarMatches(String text, String query) {
    // Dictionary for similar words
    final similarWords = {
      'fruit': ['fruits', 'frukt', 'frukter'],
      'veg': ['vegetable', 'vegetables', 'grönsaker'],
      'milk': ['mjölk', 'dairy', 'mejeri'],
      'bread': ['bröd', 'loaf', 'bageri'],
      'meat': ['kött', 'beef', 'pork', 'chicken', 'fläsk'],
      'fish': ['fisk', 'seafood', 'skaldjur'],
      'drink': ['dryck', 'beverage', 'läsk'],
      // Add more similar words as needed
    };

    // Check similar words
    for (var entry in similarWords.entries) {
      if (entry.key.contains(query) || entry.value.any((word) => word.contains(query))) {
        if (text.contains(entry.key)) return true;
      }
    }

    // Check for partial matches if word is at least 3 characters
    if (query.length >= 3) {
      return text.split(' ').any((word) => 
        word.startsWith(query) || 
        _calculateSimilarity(word, query) > 0.7
      );
    }

    return false;
  }

  // Add helper method for sorting
  void _sortItems(List<StoreItem> items) {
    switch (selectedSort) {
      case 'Name':
        items.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Price (Low to High)':
        items.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price (High to Low)':
        items.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
  }

  // Update filter method to work with current search results
  void _filterItems() {
    if (!mounted) return;

    setState(() {
      // Start with all items
      List<StoreItem> results = List.from(allItems);

      // Apply store filter if selected
      if (selectedStore != null) {
        results = results.where((item) =>
          item.storeName == _getStoreName(selectedStore!)
        ).toList();
      }

      // Apply category filter if selected
      if (selectedFilter != null) {
        results = results.where((item) =>
          item.category == selectedFilter
        ).toList();
      }

      // Apply search filter if there's a query
      if (_searchController.text.isNotEmpty) {
        final queryWords = _searchController.text.toLowerCase().split(' ');
        results = results.where((item) {
          final searchText = '${item.name} ${item.category}'.toLowerCase();
          return queryWords.every((word) =>
            searchText.contains(word) ||
            _findSimilarMatches(searchText, word)
          );
        }).toList();
      }

      // Apply sorting
      switch (selectedSort) {
        case 'Name':
          results.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'Price (Low to High)':
          results.sort((a, b) {
            final priceA = a.salePrice ?? a.price;
            final priceB = b.salePrice ?? b.price;
            return priceA.compareTo(priceB);
          });
          break;
        case 'Price (High to Low)':
          results.sort((a, b) {
            final priceA = a.salePrice ?? a.price;
            final priceB = b.salePrice ?? b.price;
            return priceB.compareTo(priceA);
          });
          break;
      }

      filteredItems = results;
    });
  }

  Future<void> _loadRandomDeals() async {
    setState(() => isLoading = true);
    try {
      List<StoreItem> deals = [];
      final storeNumbers = _storeNames.keys.toList();
      storeNumbers.shuffle();

      for (String storeNumber in storeNumbers) {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('stores')
              .doc(storeNumber)
              .collection('items')
              .get();

          final items = snapshot.docs.map((doc) {
            final data = doc.data();
            final regularPrice = (data['price'] as num).toDouble();
            final memberPrice = data['memberPrice'] != null ? 
                (data['memberPrice'] as num).toDouble() : null;

            return StoreItem(
              id: doc.id,
              name: data['name'] ?? '',
              category: data['category'] ?? '',
              price: regularPrice,
              salePrice: memberPrice != null && memberPrice < regularPrice ? memberPrice : null,
              imageUrl: data['imageUrl'] ?? '',
              unit: data['unit'] ?? '',
              inStock: data['inStock'] ?? true,
              quantity: 0,
              storeName: _getStoreName(storeNumber),
            );
          }).toList();

          // If member price filter is on, only add items with valid member prices

          items.shuffle();
          deals.addAll(items.take(3));
        } catch (e) {
          print('Error loading deals from store $storeNumber: $e');
        }
      }

      if (mounted) {
        setState(() {
          allItems = deals;
          filteredItems = deals;
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
                      children: [
                        Expanded(
                          flex: 3,
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
    _currencySubscription?.cancel();
    _searchCache.clear();
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
                ? MediaQuery.of(context).size.height * 0.32 
                : MediaQuery.of(context).size.height * 0.12,
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
                    'Deals',
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
                    const SizedBox(height: kToolbarHeight + 10),
                    if (isFilterVisible) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                              const SizedBox(height: 8),
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
                              const SizedBox(height: 8),
                              _buildFilterDropdown(
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
                  childAspectRatio: 0.95,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
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
                  childAspectRatio: 0.95,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
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
              // Image Section with adjusted height
              SizedBox(
                height: maxHeight * 0.45,
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
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_offer,
                                color: Colors.white,
                                size: maxWidth * 0.05,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(((item.price - item.salePrice!) / item.price) * 100).round()}% OFF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: maxWidth * 0.05,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Content Section with adjusted spacing
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item.name,
                        style: AppTextStyles.cardTitle(context).copyWith(
                          fontSize: maxWidth * 0.07,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      
                      // Store name
                      Text(
                        item.storeName,
                        style: AppTextStyles.cardSubtitle(context).copyWith(
                          fontSize: maxWidth * 0.05,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const Spacer(),

                      // Price section with unit pricing
                      if (item.salePrice != null) ...[
                        Text(
                          PriceFormatter.formatPriceWithUnit(item.price, item.unit),
                          style: AppTextStyles.price(context, isOnSale: true).copyWith(
                            fontSize: maxWidth * 0.06,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          PriceFormatter.formatPriceWithUnit(item.salePrice!, item.unit),
                          style: AppTextStyles.price(context).copyWith(
                            fontSize: maxWidth * 0.07,
                            color: Colors.red,
                          ),
                        ),
                      ] else
                        Text(
                          PriceFormatter.formatPriceWithUnit(item.price, item.unit),
                          style: AppTextStyles.price(context).copyWith(
                            fontSize: maxWidth * 0.07,
                          ),
                        ),

                      const SizedBox(height: 4),

                      // Quantity and Cart controls with adjusted sizes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: maxHeight * 0.16,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
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
                                  size: maxWidth * 0.06,
                                ),
                                SizedBox(
                                  width: maxWidth * 0.16,
                                  child: Text(
                                    '${item.quantity}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: maxWidth * 0.06,
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
                                  size: maxWidth * 0.06,
                                ),
                              ],
                            ),
                          ),
                          
                          // Cart button with adjusted size and better design
                          Container(
                            height: maxHeight * 0.18,
                            width: maxHeight * 0.18,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () async {
                                  if (item.quantity == 0) {
                                    showMessage(context, 'Please select quantity', false);
                                    return;
                                  }
                                  try {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user != null) {
                                      // Get correct store name using the mapping
                                      final storeName = _getStoreName(item.storeName);  // Use the mapping function
                                      
                                      // Create map with base SEK prices
                                      final cartData = {
                                        'id': item.id,
                                        'name': item.name,
                                        'category': item.category,
                                        'price': item.originalPriceSEK,        // Base SEK price
                                        'salePrice': item.originalSalePriceSEK, // Base SEK sale price
                                        'imageUrl': item.imageUrl,
                                        'unit': item.unit,
                                        'quantity': item.quantity,
                                        'storeName': storeName,  // Use mapped store name
                                      };
                                      
                                      await _firestoreService.addToCart(
                                        user.uid,
                                        cartData,
                                        storeName,  // Use mapped store name
                                      );
                                      
                                      if (mounted) {
                                        final totalSEK = (item.originalSalePriceSEK ?? item.originalPriceSEK) * item.quantity;
                                        final displayTotal = _currencyService.convertPrice(totalSEK);
                                        
                                        showMessage(
                                          context, 
                                          '${item.quantity}x ${item.name} from $storeName\n${PriceFormatter.formatPrice(displayTotal)}', 
                                          true,
                                        );
                                        setState(() => item.quantity = 0);
                                      }
                                    }
                                  } catch (e) {
                                    print('Error adding to cart: $e');
                                    if (mounted) {
                                      showMessage(context, 'Failed to add item to cart', false);
                                    }
                                  }
                                },
                                child: Icon(
                                  Icons.shopping_cart_outlined,
                                  size: maxWidth * 0.06,
                                  color: Colors.white,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
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
                fontSize: 14,
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method for calculating string similarity
  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0;
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();
    
    int matches = 0;
    final shorter = s1.length < s2.length ? s1 : s2;
    final longer = s1.length < s2.length ? s2 : s1;
    
    for (int i = 0; i < shorter.length; i++) {
      if (i < longer.length && shorter[i] == longer[i]) matches++;
    }
    
    return matches / longer.length;
  }

  // Helper method to convert store number to store name
  String _getStoreName(String storeId) {
    // Remove any 'store ' prefix from the store ID before lookup
    final cleanId = storeId.replaceAll('store ', '');
    return _storeNames[cleanId] ?? cleanId;  // Return clean store name
  }

  Future<void> _addToCart(StoreItem item) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && item.quantity > 0) {
        // Create map with base SEK prices
        final cartData = {
          'id': item.id,
          'name': item.name,
          'category': item.category,
          'price': item.originalPriceSEK,        
          'salePrice': item.originalSalePriceSEK, 
          'imageUrl': item.imageUrl,
          'unit': item.unit,
          'quantity': item.quantity,
          'storeName': item.storeName.replaceAll('store ', ''), // Remove 'store ' prefix if present
        };

        await _firestoreService.addToCart(
          user.uid,
          cartData,
          item.storeName.replaceAll('store ', ''), // Remove 'store ' prefix here too
        );

        if (mounted) {
          final totalSEK = (item.originalSalePriceSEK ?? item.originalPriceSEK) * item.quantity;
          final displayTotal = _currencyService.convertPrice(totalSEK);
          
          showMessage(
            context, 
            '${item.quantity}x ${item.name}\n${PriceFormatter.formatPrice(displayTotal)}', 
            true,
          );
          setState(() => item.quantity = 0);
        }
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (mounted) {
        showMessage(context, 'Failed to add item to cart', false);
      }
    }
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