import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recklamradar/providers/theme_provider.dart';
import 'package:recklamradar/services/firestore_service.dart';
import 'package:recklamradar/styles/app_styles.dart';
import 'package:recklamradar/utils/message_utils.dart';
import 'package:recklamradar/models/store_item.dart';
import 'package:recklamradar/item_adding_page.dart';
import 'package:recklamradar/utils/price_formatter.dart';
import 'package:recklamradar/utils/size_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recklamradar/widgets/themed_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:recklamradar/styles/app_text_styles.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recklamradar/utils/debouncer.dart';
import 'package:recklamradar/utils/image_cache_manager.dart';
import 'package:recklamradar/widgets/lazy_list.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:recklamradar/utils/animation_config.dart';
import 'package:recklamradar/utils/performance_config.dart';
import 'package:recklamradar/services/network_service.dart';
import 'package:recklamradar/services/currency_service.dart';
import 'dart:ui';
import 'package:recklamradar/widgets/glass_container.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class StoreDetailsPage extends StatefulWidget {
  final String storeId;
  final String storeName;

  const StoreDetailsPage({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<StoreDetailsPage> createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = true;
  List<StoreItem> items = [];
  List<StoreItem> filteredItems = [];
  Map<String, List<StoreItem>> categorizedItems = {};
  bool isSearchActive = false;
  final TextEditingController searchController = TextEditingController();
  String? selectedCategory;
  String selectedSort = 'Name'; // Default sort
  bool showMemberPriceOnly = false;
  bool isFilterActive = false;
  Map<String, dynamic> _cartData = {};
  final _debouncer = Debouncer();
  final ScrollController _scrollController = ScrollController();
  final _cacheManager = CustomCacheManager.instance;
  final _networkService = NetworkService();
  bool _isLowPerformanceMode = false;
  final CurrencyService _currencyService = CurrencyService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize SizeConfig first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SizeConfig().init(context);
      }
    });
    _initializePerformance();
    _scrollController.addListener(_onScroll);
    loadStoreItems();
    _initCartStream();
  }

  Future<void> _initializePerformance() async {
    final isLowBandwidth = !await _networkService.hasHighBandwidth();
    if (mounted) {
      setState(() {
        _isLowPerformanceMode = isLowBandwidth;
      });
    }
  }

  void _onScroll() {
    // Implement efficient scroll handling
    if (!_scrollController.hasClients) return;
    
    // Use frame callback for smooth scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Your scroll logic here
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _scrollController.dispose();
    PerformanceConfig.releaseMemory();
    super.dispose();
  }

  void _initCartStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService.getCartItemStream(user.uid).listen((cartData) {
        if (mounted) {
          setState(() {
            _cartData = cartData;
          });
        }
      });
    }
  }

  Future<void> loadStoreItems() async {
    try {
      setState(() => isLoading = true);
      
      // Clear existing items first
      items.clear();
      filteredItems.clear();
      categorizedItems.clear();

      // Get fresh data from Firebase
      final storeRef = FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('items');
          
      final snapshot = await storeRef.get(const GetOptions(
        source: Source.server, // Force server fetch, don't use cache
      ));
      
      final storeItems = snapshot.docs.map((doc) {
        final data = doc.data();
        final regularPrice = (data['price'] as num).toDouble();
        final salePrice = data['salePrice'] != null ? 
            (data['salePrice'] as num).toDouble() : 
            (data['memberPrice'] as num?)?.toDouble();

        return StoreItem(
          id: doc.id,
          name: data['name'] ?? '',
          category: data['category'] ?? '',
          price: regularPrice,
          salePrice: salePrice,
          imageUrl: data['imageUrl'] ?? '',
          unit: data['unit'] ?? '',
          inStock: data['inStock'] ?? true,
          quantity: 0,
          storeName: widget.storeName,
        );
      }).toList();

      // Categorize items
      final categorized = <String, List<StoreItem>>{};
      for (var item in storeItems) {
        if (!categorized.containsKey(item.category)) {
          categorized[item.category] = [];
        }
        categorized[item.category]!.add(item);
      }

      if (mounted) {
        setState(() {
          items = storeItems;
          filteredItems = items;
          categorizedItems = categorized;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading store items: $e');
      if (mounted) {
        setState(() => isLoading = false);
        showMessage(context, "Error refreshing items", false);
      }
    }
  }

  void _updateQuantity(int index, bool increment) {
    setState(() {
      if (increment && filteredItems[index].quantity < 99) {
        filteredItems[index].quantity += 1;
      } else if (!increment && filteredItems[index].quantity > 0) {
        filteredItems[index].quantity -= 1;
      }
    });
  }

  void _searchItems(String query) {
    _debouncer.run(() {
      if (query.isEmpty) {
        setState(() {
          filteredItems = items;
        });
        return;
      }

      // Optimize query
      final queryWords = query.toLowerCase().split(' ')
          .where((word) => word.length > 1)  // Ignore single characters
          .toSet()  // Remove duplicates
          .toList();

      if (queryWords.isEmpty) {
        setState(() {
          filteredItems = items;
        });
        return;
      }

      setState(() {
        filteredItems = items.where((item) {
          final searchText = '${item.name} ${item.category}'.toLowerCase();
          return queryWords.any((word) => 
            searchText.contains(word) || 
            _findSimilarMatches(searchText, word)
          );
        }).toList();
      });

      _sortItems();
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

  // Add helper method for calculating string similarity
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

  Future<bool> _handleAddToCart(StoreItem item) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (item.quantity <= 0) {
          showMessage(context, "Please select quantity first", false);
          return false;
        }

        // Create cart data with SEK prices - directly use sale price if available
        final cartData = {
          'id': item.id,
          'name': item.name,
          'category': item.category,
          'price': item.originalSalePriceSEK ?? item.originalPriceSEK, // Use sale price directly if available
          'imageUrl': item.imageUrl,
          'unit': item.unit,
          'quantity': item.quantity,
          'storeName': widget.storeName,
        };

        await _firestoreService.addToCart(
          user.uid,
          cartData,
          widget.storeName,
        );
        
        if (mounted) {
          // Calculate total using the effective price
          final totalSEK = (cartData['price'] as num?)?.toDouble() ?? 0.0 * item.quantity;
          final displayTotal = _currencyService.convertPrice(totalSEK);
          
          showMessage(
            context, 
            "${item.quantity}x ${item.name} added to cart\n${PriceFormatter.formatPrice(displayTotal)}", 
            true
          );
          setState(() => item.quantity = 0);
        }
      }
    } catch (e) {
      if (mounted) showMessage(context, "Failed to add to cart", false);
    }
    return false;
  }

  // ignore: unused_element
  void _removeFromCart(StoreItem item) {
    // Implementation of _removeFromCart
  }

  void _sortItems() {
    setState(() {
      switch (selectedSort) {
        case 'Name':
          filteredItems.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'Price (Low to High)':
          filteredItems.sort((a, b) => 
            (a.originalSalePriceSEK ?? a.originalPriceSEK)
            .compareTo(b.originalSalePriceSEK ?? b.originalPriceSEK));
          break;
        case 'Price (High to Low)':
          filteredItems.sort((a, b) => 
            (b.originalSalePriceSEK ?? b.originalPriceSEK)
            .compareTo(a.originalSalePriceSEK ?? a.originalPriceSEK));
          break;
      }
    });
  }

  void _filterItems(String? query) {
    setState(() {
      filteredItems = items.where((item) {
        bool matchesSearch = query == null || query.isEmpty ||
            item.name.toLowerCase().contains(query.toLowerCase()) ||
            item.category.toLowerCase().contains(query.toLowerCase());
            
        bool matchesCategory = selectedCategory == null || 
            selectedCategory == 'All' ||
            item.category == selectedCategory;
            
        bool matchesMemberPrice = !showMemberPriceOnly || item.salePrice != null;

        return matchesSearch && matchesCategory && matchesMemberPrice;
      }).toList();
      
      _sortItems();
    });
  }

  Widget _buildItemCard(StoreItem item, int index) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 200));
        return _handleAddToCart(item);
      },
      dismissThresholds: const {
        DismissDirection.startToEnd: AnimationConfig.swipeThreshold,
      },
      movementDuration: AnimationConfig.defaultDuration,
      background: AnimatedContainer(
        duration: AnimationConfig.defaultDuration,
        decoration: AnimationConfig.dismissibleBackground,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              children: [
                Icon(Icons.add_shopping_cart, color: Colors.white.withOpacity(0.9)),
                const SizedBox(width: 8),
                Text(
                  'Add to Cart',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      secondaryBackground: Container(
        color: Colors.transparent,
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.015),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: EdgeInsets.all(SizeConfig.blockSizeHorizontal * 3),
              child: Row(
                children: [
                  // Image section
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: SizeConfig.blockSizeHorizontal * 20,
                      height: SizeConfig.blockSizeHorizontal * 20,
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200]?.withOpacity(0.3),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200]?.withOpacity(0.3),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Details section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTextStyles.cardTitle(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.category,
                          style: AppTextStyles.cardSubtitle(context),
                        ),
                        const SizedBox(height: 6),
                        // Price section remains the same
                        if (item.salePrice != null) ...[
                          Text(
                            PriceFormatter.formatPriceWithUnit(item.price, item.unit),
                            style: AppTextStyles.price(context, isOnSale: true).copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
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
                                  size: 10,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  PriceFormatter.formatPriceWithUnit(item.salePrice!, item.unit),
                                  style: AppTextStyles.price(context).copyWith(
                                    color: Colors.green[700],
                                  
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else
                          Text(
                            PriceFormatter.formatPriceWithUnit(item.price, item.unit),
                            style: AppTextStyles.price(context).copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        // Add unit explanation if needed
                        Text(
                          "Price per ${item.unit}",
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Quantity controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _updateQuantity(index, false),
                        color: Theme.of(context).primaryColor.withOpacity(0.8),
                      ),
                      Container(
                        width: 32,
                        child: Text(
                          '${item.quantity}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _updateQuantity(index, true),
                        color: Theme.of(context).primaryColor.withOpacity(0.8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search items...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        onChanged: _searchItems,
      ),
    );
  }

  Widget _buildFilterSection() {
    final categories = ['All', ...items.map((item) => item.category).toSet()];
    final sortOptions = ['Name', 'Price (Low to High)', 'Price (High to Low)'];

    return AnimatedContainer(
      duration: AnimationConfig.defaultDuration,
      curve: AnimationConfig.defaultCurve,
      height: isFilterActive ? null : 0,
      child: ClipRRect(
        child: AnimatedOpacity(
          duration: AnimationConfig.defaultDuration,
          opacity: isFilterActive ? 1.0 : 0.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: Provider.of<ThemeProvider>(context).cardGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Category Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory ?? 'All',
                      isExpanded: true,
                      dropdownColor: Theme.of(context).primaryColor,
                      style: const TextStyle(color: Colors.white),
                      hint: const Text('Select Category', style: TextStyle(color: Colors.white)),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value == 'All' ? null : value;
                          _filterItems(searchController.text);
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sort Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedSort,
                      isExpanded: true,
                      dropdownColor: Theme.of(context).primaryColor,
                      style: const TextStyle(color: Colors.white),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      items: sortOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSort = value!;
                          _sortItems();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Member Price Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Member Price Only',
                        style: TextStyle(color: Colors.white),
                      ),
                      Switch(
                        value: showMemberPriceOnly,
                        onChanged: (value) {
                          setState(() {
                            showMemberPriceOnly = value;
                            _filterItems(searchController.text);
                          });
                        },
                        activeColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Update the ListView.builder with better performance
  Widget _buildItemList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) => _buildItemCard(filteredItems[index], index),
    );
  }

  // Optimize image loading in item cards
  Widget _buildItemImage(String imageUrl) {
    return Hero(
      tag: imageUrl,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        cacheManager: _cacheManager,
        memCacheWidth: _isLowPerformanceMode ? 150 : 300,
        maxWidthDiskCache: _isLowPerformanceMode ? 300 : 600,
        fadeInDuration: _isLowPerformanceMode ? 
            const Duration(milliseconds: 100) : 
            const Duration(milliseconds: 200),
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.error_outline),
        ),
      ),
    );
  }

  Future<bool> _handleRemoveFromCart(StoreItem item) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestoreService.removeFromCart(user.uid, item.id);
        if (mounted) showMessage(context, "${item.name} removed from cart", true);
      }
    } catch (e) {
      if (mounted) showMessage(context, "Failed to remove from cart", false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.email == 'vv@gmail.com';

    return ThemedScaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isSearchActive 
            ? _buildSearchField()
            : Text(
                widget.storeName,
                style: AppTextStyles.heading2(context),
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFilterActive ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isFilterActive = !isFilterActive;
              });
            },
          ),
          IconButton(
            icon: Icon(
              isSearchActive ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isSearchActive = !isSearchActive;
                if (!isSearchActive) {
                  searchController.clear();
                  _filterItems(null);
                }
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await loadStoreItems();
            if (mounted) {
              // Re-apply any active filters after refresh
              if (selectedCategory != null || selectedSort != 'Name' || showMemberPriceOnly) {
                _filterItems(searchController.text);
              }
              showMessage(context, "Items updated", true);
            }
          } catch (e) {
            if (mounted) {
              showMessage(context, "Failed to refresh items", false);
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: Provider.of<ThemeProvider>(context).subtleGradient,
          ),
          child: Column(
            children: [
              if (isFilterActive) 
                _buildFilterSection(),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('No items found'),
                                TextButton(
                                  onPressed: loadStoreItems,
                                  child: const Text('Refresh'),
                                ),
                              ],
                            ),
                          )
                        : _buildItemList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isAdmin ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemAddingPage(
                storeId: widget.storeId,
                storeName: widget.storeName,
                onItemAdded: loadStoreItems,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        backgroundColor: Theme.of(context).primaryColor,
      ) : null,
    );
  }
} 