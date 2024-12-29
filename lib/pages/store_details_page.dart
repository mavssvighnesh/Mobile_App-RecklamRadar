import 'package:flutter/material.dart';
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

class _StoreDetailsPageState extends State<StoreDetailsPage> {
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

  @override
  void initState() {
    super.initState();
    loadStoreItems();
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
    setState(() {
      if (query.isEmpty) {
        filteredItems = items;
      } else {
        filteredItems = items
            .where((item) =>
                item.name.toLowerCase().contains(query.toLowerCase()) ||
                item.category.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
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

  Widget _buildItemCard(StoreItem item, int index) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: [
            Icon(Icons.shopping_cart_checkout, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Add to Cart',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              if (item.quantity <= 0) {
                showMessage(context, "Please select quantity first", false);
                return false;
              }
              
              await _firestoreService.addToCart(
                user.uid,
                item,
                widget.storeName,
              );
              
              if (mounted) {
                showMessage(
                  context, 
                  "${item.quantity}x ${item.name} added to cart", 
                  true
                );
                // Reset quantity after adding to cart
                setState(() {
                  item.quantity = 0;
                });
              }
            } else {
              if (mounted) {
                showMessage(context, "Please login to add items to cart", false);
              }
            }
          } catch (e) {
            print('Error adding to cart: $e');
            if (mounted) {
              showMessage(context, "Failed to add item to cart", false);
            }
          }
        }
        return false;
      },
      child: Card(
        margin: EdgeInsets.only(bottom: SizeConfig.blockSizeVertical * 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeConfig.blockSizeHorizontal * 4),
        ),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.blockSizeHorizontal * 3),
          child: Row(
            children: [
              Container(
                width: SizeConfig.getProportionateScreenWidth(80),
                height: SizeConfig.getProportionateScreenWidth(80),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SizeConfig.blockSizeHorizontal * 3),
                  image: DecorationImage(
                    image: NetworkImage(item.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.blockSizeHorizontal * 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.cardTitle(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      item.category,
                      style: AppTextStyles.cardSubtitle(context),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (item.salePrice != null) ...[
                          Text(
                            'SEK ${item.price}',
                            style: AppTextStyles.price(context, isOnSale: true),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'SEK ${item.salePrice}',
                            style: AppTextStyles.price(context),
                          ),
                        ] else
                          Text(
                            'SEK ${item.price}',
                            style: AppTextStyles.price(context),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Quantity Controls
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _updateQuantity(index, false),
                    color: Theme.of(context).primaryColor,
                  ),
                  Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _updateQuantity(index, true),
                    color: Theme.of(context).primaryColor,
                  ),
                ],
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

    return Container(
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
    );
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _buildFilterSection(),
                ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredItems.isEmpty
                        ? const Center(
                            child: Text('No items found'),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return _buildItemCard(item, index);
                            },
                          ),
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