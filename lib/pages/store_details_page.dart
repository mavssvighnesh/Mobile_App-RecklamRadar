import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recklamradar/providers/theme_provider.dart';
import 'package:recklamradar/services/firestore_service.dart';
import 'package:recklamradar/utils/message_utils.dart';
import 'package:recklamradar/models/store_item.dart';
import 'package:recklamradar/item_adding_page.dart';
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
  late final ScrollController _scrollController;
  final _cacheManager = CustomCacheManager.instance;
  final _networkService = NetworkService();
  bool _isLowPerformanceMode = false;
  final CurrencyService _currencyService = CurrencyService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializePerformance();
    _scrollController = ScrollController()..addListener(_onScroll);
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
      final storeItems = await _firestoreService.getStoreItems(widget.storeId);
      
      // Categorize items
      final categorized = <String, List<StoreItem>>{};
      for (var item in storeItems) {
        if (!categorized.containsKey(item.category)) {
          categorized[item.category] = [];
        }
        categorized[item.category]!.add(item);
      }

      setState(() {
        items = storeItems;
        filteredItems = items;
        categorizedItems = categorized;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading store items: $e');
      setState(() => isLoading = false);
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
      setState(() {
        _filterItems(query);
      });
    });
  }

  // ignore: unused_element
  void _addToCart(StoreItem item) {
    // Implementation of _addToCart
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
          filteredItems.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'Price (High to Low)':
          filteredItems.sort((a, b) => b.price.compareTo(a.price));
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

  Widget _buildCartIndicator(StoreItem item) {
    final isInCart = _cartData.containsKey(item.id);
    final quantity = isInCart ? _cartData[item.id]['quantity'] ?? 0 : 0;
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart,
            size: 16,
            color: isInCart ? Colors.green : Colors.black54,
          ),
          if (isInCart && quantity > 0)
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Text(
                quantity.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemCard(StoreItem item, int index) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        final isRight = direction == DismissDirection.endToStart;
        
        // Add haptic feedback
        HapticFeedback.mediumImpact();
        
        // Animate the card
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (isRight) {
          return _handleRemoveFromCart(item);
        } else {
          return _handleAddToCart(item);
        }
      },
      dismissThresholds: const {
        DismissDirection.startToEnd: AnimationConfig.swipeThreshold,
        DismissDirection.endToStart: AnimationConfig.swipeThreshold,
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
      secondaryBackground: AnimatedContainer(
        duration: AnimationConfig.defaultDuration,
        decoration: AnimationConfig.dismissibleBackground,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Remove',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.delete, color: Colors.white.withOpacity(0.9)),
              ],
            ),
          ),
        ),
      ),
      child: TweenAnimationBuilder<double>(
        duration: AnimationConfig.defaultDuration,
        tween: Tween(begin: 0.0, end: 1.0),
        curve: AnimationConfig.defaultCurve,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Card(
          margin: EdgeInsets.only(bottom: SizeConfig.blockSizeVertical * 1.5),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(SizeConfig.blockSizeHorizontal * 3),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: SizeConfig.blockSizeHorizontal * 20,
                        height: SizeConfig.blockSizeHorizontal * 20,
                        child: CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Item details section
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
                          if (item.salePrice != null) ...[
                            Text(
                              CurrencyService().formatPrice(item.price),
                              style: AppTextStyles.price(context, isOnSale: true),
                            ),
                            Text(
                              CurrencyService().formatPrice(item.salePrice!),
                              style: AppTextStyles.price(context),
                            ),
                          ] else
                            Text(
                              CurrencyService().formatPrice(item.price),
                              style: AppTextStyles.price(context),
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
                          constraints: const BoxConstraints(minWidth: 40),
                          padding: EdgeInsets.zero,
                        ),
                        SizedBox(
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
                          constraints: const BoxConstraints(minWidth: 40),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Cart indicator
              Positioned(
                top: 8,
                right: 8,
                child: _buildCartIndicator(item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: searchController,
        onChanged: _searchItems,
        decoration: InputDecoration(
          hintText: 'Search items...',
          hintStyle: AppTextStyles.bodyMedium(context),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final categories = ['All', ...items.map((item) => item.category).toSet().toList()];
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

  Future<bool> _handleAddToCart(StoreItem item) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (item.quantity <= 0) {
          showMessage(context, "Please select quantity first", false);
          return false;
        }
        
        await _firestoreService.addToCart(user.uid, item, widget.storeName);
        if (mounted) {
          showMessage(context, "${item.quantity}x ${item.name} added to cart", true);
          setState(() => item.quantity = 0);
        }
      }
    } catch (e) {
      if (mounted) showMessage(context, "Failed to add to cart", false);
    }
    return false;
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
    return ThemedScaffold(
      appBar: AppBar(
        title: Text(
          widget.storeName,
          style: AppTextStyles.heading2(context),
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
                  filteredItems = items;
                }
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadStoreItems();
          if (mounted) {
            showMessage(context, "Store items refreshed", true);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: Provider.of<ThemeProvider>(context).subtleGradient,
          ),
          child: Column(
            children: [
              if (isSearchActive) _buildSearchBar(),
              if (isFilterActive) 
                _buildFilterSection(),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredItems.isEmpty
                        ? const Center(
                            child: Text('No items found'),
                          )
                        : _buildItemList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
      ),
    );
  }
} 