import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recklamradar/widgets/glass_container.dart';
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
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _itemsPerPage = 9;  // 3 items from each store
  bool _hasMoreItems = true;

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

  // Add search index for faster lookups
  final Map<String, Set<String>> _searchIndex = {};
  
  // Cache for filtered results
  final Map<String, List<StoreItem>> _filteredCache = {};

  // Add a Set to track unique items
  final Set<String> _loadedItemIds = {};
  
  // Cache for store items
  final Map<String, List<StoreItem>> _storeItemsCache = {};
  
  // Batch size for loading
  static const int _batchSize = 15;

  @override
  void initState() {
    super.initState();
    categories = {'Groceries'};  // Add a default category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SizeConfig().init(context);
        // Load initial data
        _loadRandomDeals(refresh: true).then((_) {
          // Set initial filtered items
          if (mounted) {
            setState(() {
              filteredItems = allItems;
            });
          }
        });
      }
    });
    _currencySubscription = _currencyService.currencyStream.listen((_) {
      if (mounted) setState(() {});
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
    
    setState(() => isLoading = true);
    
    try {
      if (query.isEmpty) {
        await _loadRandomDeals();
        return;
      }

      final queryWords = query.toLowerCase()
          .split(' ')
          .where((word) => word.length > 1)
          .toSet();
      
      if (queryWords.isEmpty) {
        await _loadRandomDeals();
        return;
      }

      // Use indexed search for better performance
      final results = allItems.where((item) {
        if (selectedStore != null && 
            item.storeName != _getStoreName(selectedStore!)) {
          return false;
        }
        
        if (selectedFilter != null && 
            item.category != selectedFilter) {
          return false;
        }

        final searchText = '${item.name} ${item.category}'.toLowerCase();
        return queryWords.any((word) => 
          searchText.contains(word)
        );
      }).toList();

      // Sort results
      _sortItems(results);

      if (mounted) {
        setState(() {
          filteredItems = results;
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
        items.sort((a, b) {
          final aPrice = a.salePrice ?? a.price;
          final bPrice = b.salePrice ?? b.price;
          return aPrice.compareTo(bPrice);
        });
        break;
      case 'Price (High to Low)':
        items.sort((a, b) {
          final aPrice = a.salePrice ?? a.price;
          final bPrice = b.salePrice ?? b.price;
          return bPrice.compareTo(aPrice);
        });
        break;
    }
  }

  // Update filter method to work with current search results
  void _filterItems() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      // If store filter is selected, fetch all items from that store
      if (selectedStore != null) {
        final storeItems = await FirebaseFirestore.instance
            .collection('stores')
            .doc(selectedStore)
            .collection('items')
            .get();

        final items = storeItems.docs.map((doc) {
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
            storeName: _getStoreName(selectedStore!),
          );
        }).toList();

        // Apply category filter if selected
        List<StoreItem> results = items;
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
        _sortItems(results);

        if (mounted) {
          setState(() {
            filteredItems = results;
            categories = results.map((item) => item.category).toSet();
            isLoading = false;
          });
        }
      } else {
        // If no store filter, work with current items
        List<StoreItem> results = List.from(allItems);

        // Apply category filter
        if (selectedFilter != null) {
          results = results.where((item) =>
            item.category == selectedFilter
          ).toList();
        }

        // Apply search filter
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
        _sortItems(results);

        if (mounted) {
          setState(() {
            filteredItems = results;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error filtering items: $e');
      if (mounted) {
        setState(() => isLoading = false);
        showMessage(context, 'Error filtering items', false);
      }
    }
  }

  Future<void> _loadRandomDeals({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreItems = true;
        isLoading = true;
        // Clear everything on refresh
        allItems.clear();
        filteredItems.clear();
        _loadedItemIds.clear();
        _storeItemsCache.clear();
      });
    }

    if (!refresh && (!_hasMoreItems || _isLoadingMore)) return;

    setState(() => _isLoadingMore = true);

    try {
      // Get all store IDs if not cached
      final storeIds = _storeNames.keys.toList();
      final batch = FirebaseFirestore.instance.batch();
      final List<StoreItem> newItems = [];

      // Load items in parallel from each store
      final futures = storeIds.map((storeId) async {
        // Check cache first
        if (_storeItemsCache.containsKey(storeId)) {
          return _storeItemsCache[storeId]!;
        }

        final snapshot = await FirebaseFirestore.instance
            .collection('stores')
            .doc(storeId)
            .collection('items')
            .limit(_batchSize)
            .get(const GetOptions(source: Source.server));

        final items = snapshot.docs
            .where((doc) => !_loadedItemIds.contains(doc.id))
            .map((doc) {
              final data = doc.data();
              return StoreItem(
                id: doc.id,
                name: data['name'] ?? '',
                category: data['category'] ?? '',
                price: (data['price'] as num).toDouble(),
                salePrice: data['salePrice'] != null ? 
                    (data['salePrice'] as num).toDouble() : null,
                imageUrl: data['imageUrl'] ?? '',
                unit: data['unit'] ?? '',
                inStock: data['inStock'] ?? true,
                quantity: 0,
                storeName: _getStoreName(storeId),
              );
            })
            .toList();

        // Cache store items
        _storeItemsCache[storeId] = items;
        return items;
      });

      // Wait for all parallel requests to complete
      final results = await Future.wait(futures);
      
      // Process results
      for (var items in results) {
        for (var item in items) {
          if (_loadedItemIds.add(item.id)) { // Only add if ID is new
            newItems.add(item);
          }
        }
      }

      // Sort items by sale price
      newItems.sort((a, b) {
        final aHasSale = a.salePrice != null;
        final bHasSale = b.salePrice != null;
        if (aHasSale != bHasSale) return aHasSale ? -1 : 1;
        return 0;
      });

      if (mounted) {
        setState(() {
          if (refresh) {
            allItems = newItems;
            filteredItems = newItems;
          } else {
            allItems.addAll(newItems);
            filteredItems.addAll(newItems);
          }
          categories = allItems.map((item) => item.category).toSet();
          isLoading = false;
          _isLoadingMore = false;
          _hasMoreItems = newItems.length >= _batchSize;
        });
      }
    } catch (e) {
      print('Error loading deals: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoadingMore = false;
        });
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
    _searchCache.clear();
    _storeItemsCache.clear();
    _loadedItemIds.clear();
    _debouncer.dispose();
    _searchController.dispose();
    _currencySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadRandomDeals(refresh: true),
        child: CustomScrollView(
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
                  ? _buildSearchField()
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
            SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: filteredItems.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 100),
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No items available'
                                  : 'No results found for "${_searchController.text}"',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 
                            MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        childAspectRatio: 0.75,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filteredItems[index];
                          return _buildItemCard(item);
                        },
                        childCount: filteredItems.length,
                      ),
                    ),
            ),

            // Loading indicator
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(StoreItem item) {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      opacity: 0.15,
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;
          
          // Calculate sizes based on container dimensions
          final imageHeight = maxHeight * 0.5;  // 50% for image
          final contentPadding = maxWidth * 0.03;
          final fontSize = maxWidth * 0.045;
          final iconSize = maxWidth * 0.05;
          final buttonHeight = maxHeight * 0.12;
          
          return Column(
            children: [
              // Image section
              SizedBox(
                height: imageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.image_not_supported,
                            size: iconSize * 2,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    if (item.salePrice != null)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
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
                              fontSize: fontSize * 1.1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content section
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(contentPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and store name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTextStyles.cardTitle(context).copyWith(
                              fontSize: fontSize * 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.storeName,
                            style: AppTextStyles.cardSubtitle(context).copyWith(
                              fontSize: fontSize * 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Price section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.salePrice != null && item.salePrice! < item.price) ...[
                            // Original price (crossed out)
                            Text(
                              PriceFormatter.formatPriceWithUnit(item.price, item.unit),
                              style: AppTextStyles.price(context, isOnSale: true).copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.black54,
                                fontSize: fontSize * 1.1,
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            // Sale price in green container
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user,
                                    size: fontSize * 1.1,
                                    color: Colors.green[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    PriceFormatter.formatPriceWithUnit(item.salePrice!, item.unit),
                                    style: AppTextStyles.price(context).copyWith(
                                      color: Colors.green[700],
                                      fontSize: fontSize * 1.2,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ] else
                            Text(
                              PriceFormatter.formatPriceWithUnit(item.price, item.unit),
                              style: AppTextStyles.price(context).copyWith(
                                fontSize: fontSize * 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                            ),
                          const SizedBox(height: 2),
                          // Unit explanation
                         /* Text(
                            "Price per ${item.unit}",
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: Colors.grey[600],
                              fontSize: fontSize * 1.1,
                            ),
                          ),*/
                        ],
                      ),

                      // Controls section
                      SizedBox(
                        height: buttonHeight,
                        child: Row(
                          children: [
                            // Quantity controls
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: buttonHeight,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildQuantityButton(
                                      icon: Icons.remove,
                                      onTap: () {
                                        if (item.quantity > 0) {
                                          setState(() => item.quantity--);
                                        }
                                      },
                                      enabled: item.quantity > 0,
                                      size: iconSize,
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.bold,
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
                                      size: iconSize,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Cart button
                            SizedBox(
                              height: buttonHeight,
                              width: buttonHeight * 1.2,
                              child: Material(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(6),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => _addToCart(item),
                                  child: Icon(
                                    Icons.shopping_cart_outlined,
                                    size: iconSize,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
    // Ensure items is not null and has unique values
    final uniqueItems = LinkedHashSet<String>.from(
      items.where((item) => item.value != null)  // Filter out null values
          .map((item) => item.value as String)
    ).map((value) => 
      items.firstWhere((item) => item.value == value)
    ).toList();

    // Add "All" option at the beginning
    if (title != 'Sort By') {  // Don't add "All" option for Sort By
      uniqueItems.insert(0, DropdownMenuItem(
        value: null,
        child: Text('All ${title}s'),
      ));
    }

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      opacity: 0.1,
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          value: value,
          items: uniqueItems,
          onChanged: onChanged,
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          dropdownColor: Theme.of(context).cardColor,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).iconTheme.color,
          ),
          hint: Text(
            'Select $title',
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
      ),
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
        // Check if there's a valid sale price (lower than regular price)
        final hasSalePrice = item.originalSalePriceSEK != null && 
            item.originalSalePriceSEK! < item.originalPriceSEK;

        // Use original SEK prices for cart data
        final cartData = {
          'id': item.id,
          'name': item.name,
          'category': item.category,
          'price': hasSalePrice ? item.originalSalePriceSEK : item.originalPriceSEK,  // Use sale price if available
          'salePrice': hasSalePrice ? item.originalSalePriceSEK : null,  // Only set salePrice if it's valid
          'imageUrl': item.imageUrl,
          'unit': item.unit,
          'quantity': item.quantity,
          'storeName': item.storeName.replaceAll('store ', ''),
        };

        await _firestoreService.addToCart(
          user.uid,
          cartData,
          item.storeName.replaceAll('store ', ''),
        );

        if (mounted) {
          // Calculate total using effective SEK price
          final effectivePriceSEK = hasSalePrice 
              ? item.originalSalePriceSEK! 
              : item.originalPriceSEK;
              
          final totalSEK = effectivePriceSEK * item.quantity;
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

  // Add this method for dynamic search
  void _handleSearch(String query) {
    if (!mounted) return;

    // Don't set loading state for instant search
    if (query.isEmpty) {
      setState(() {
        filteredItems = allItems;
      });
      return;
    }

    // Convert query to lowercase once
    final searchQuery = query.toLowerCase();
    
    // Filter items instantly
    final results = allItems.where((item) {
      // Apply store filter
      if (selectedStore != null && 
          item.storeName != _getStoreName(selectedStore!)) {
        return false;
      }
      
      // Apply category filter
      if (selectedFilter != null && 
          item.category != selectedFilter) {
        return false;
      }

      // Search in name and category
      final searchText = '${item.name} ${item.category}'.toLowerCase();
      return searchText.contains(searchQuery);
    }).toList();

    // Sort results
    _sortItems(results);

    // Update UI
    setState(() {
      filteredItems = results;
    });
  }

  // Update the search field widget
  Widget _buildSearchField() {
    return Container(
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
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.8)),
                  onPressed: () {
                    _searchController.clear();
                    _handleSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (query) {
          // Use debouncer for smoother experience
          _debouncer.run(() => _handleSearch(query));
        },
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