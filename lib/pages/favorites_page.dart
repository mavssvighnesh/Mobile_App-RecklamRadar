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
      
      for (String storeNumber in storeNumbers) {
        try {
          final itemsSnapshot = await FirebaseFirestore.instance
              .collection('stores')
              .doc(storeNumber)
              .collection('items')
              .limit(4) // Get 4 random items from each store
              .get();

          for (var doc in itemsSnapshot.docs) {
            final data = doc.data();
            deals.add(StoreItem(
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
        } catch (e) {
          print('Error loading deals from store $storeNumber: $e');
        }
      }

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
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Search Deals',
                style: AppTextStyles.heading1(context),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: Provider.of<ThemeProvider>(context).cardGradient,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFilterActive ? Icons.filter_list_off : Icons.filter_list,
                  color: Colors.white,
                ),
                onPressed: _showFilterDialog,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(SizeConfig.blockSizeVertical * 8),
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.blockSizeHorizontal * 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (query) {
                    _debouncer.run(() {
                      _searchItems(query);
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for items across all stores...',
                    hintStyle: AppTextStyles.bodyMedium(context),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        SizeConfig.blockSizeHorizontal * 3,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
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
                  childAspectRatio: 0.6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
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
                  childAspectRatio: 0.6,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              SizedBox(
                height: maxHeight * 0.55,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: SizedBox.expand(
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
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: maxWidth * 0.2,
                                  color: Colors.grey[400],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (item.salePrice != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
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
                              fontSize: maxWidth * 0.05,
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
                  padding: EdgeInsets.all(maxWidth * 0.03),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Store
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: AppTextStyles.cardTitle(context).copyWith(
                                fontSize: maxWidth * 0.08,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: maxHeight * 0.01),
                            Text(
                              item.storeName,
                              style: AppTextStyles.cardSubtitle(context).copyWith(
                                fontSize: maxWidth * 0.06,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Price and Cart Button
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.salePrice != null) ...[
                                    Text(
                                      'SEK ${item.price}',
                                      style: AppTextStyles.price(context, isOnSale: true).copyWith(
                                        fontSize: maxWidth * 0.06,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    Text(
                                      'SEK ${item.salePrice}',
                                      style: AppTextStyles.price(context).copyWith(
                                        fontSize: maxWidth * 0.07,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ] else
                                    Text(
                                      'SEK ${item.price}',
                                      style: AppTextStyles.price(context).copyWith(
                                        fontSize: maxWidth * 0.07,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Quantity selector
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          if (item.quantity > 0) {
                                            setState(() {
                                              item.quantity--;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(maxWidth * 0.02),
                                          child: Icon(
                                            Icons.remove,
                                            size: maxWidth * 0.06,
                                            color: item.quantity > 0 
                                                ? Theme.of(context).primaryColor 
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: maxWidth * 0.1,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${item.quantity}',
                                          style: TextStyle(
                                            fontSize: maxWidth * 0.06,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          if (item.quantity < 99) {
                                            setState(() {
                                              item.quantity++;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(maxWidth * 0.02),
                                          child: Icon(
                                            Icons.add,
                                            size: maxWidth * 0.06,
                                            color: item.quantity < 99 
                                                ? Theme.of(context).primaryColor 
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: maxWidth * 0.02),
                                // Add to cart button
                                SizedBox(
                                  width: maxWidth * 0.2,
                                  height: maxWidth * 0.1,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.add_shopping_cart,
                                      size: maxWidth * 0.08,
                                    ),
                                    onPressed: () async {
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
                                  ),
                                ),
                              ],
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
} 