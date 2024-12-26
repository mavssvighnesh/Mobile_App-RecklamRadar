import 'package:flutter/material.dart';
import 'package:recklamradar/providers/theme_provider.dart';
import 'package:recklamradar/services/firestore_service.dart';
import 'package:recklamradar/utils/message_utils.dart';
import 'package:recklamradar/models/store_item.dart';
import 'package:recklamradar/item_adding_page.dart';
import 'package:recklamradar/models/store_item.dart';
import 'package:recklamradar/utils/size_config.dart';

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
      if (increment) {
        filteredItems[index].quantity += 1;
      } else if (filteredItems[index].quantity > 0) {
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

  void _addToCart(StoreItem item) {
    // Implementation of _addToCart
  }

  void _removeFromCart(StoreItem item) {
    // Implementation of _removeFromCart
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeProvider.subtleGradient,
        ),
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: ThemeProvider.cardGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          widget.storeName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
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
                    if (isSearchActive) ...[
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: searchController,
                          autofocus: true,
                          onChanged: _searchItems,
                          decoration: const InputDecoration(
                            hintText: 'Search items...',
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Items List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: SizeConfig.blockSizeHorizontal * 4),
                            color: Colors.green,
                            child: Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                              size: SizeConfig.blockSizeHorizontal * 8,
                            ),
                          ),
                          onDismissed: (direction) {
                            _addToCart(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item.name} added to cart'),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  onPressed: () => _removeFromCart(item),
                                ),
                              ),
                            );
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
                                          style: TextStyle(
                                            fontSize: SizeConfig.fontSize * 1.1,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          item.category,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'SEK ${item.price}/${item.unit}',
                                              style: item.salePrice != null 
                                                  ? const TextStyle(
                                                      decoration: TextDecoration.lineThrough,
                                                      color: Colors.grey,
                                                    )
                                                  : const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                            ),
                                            if (item.salePrice != null) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                'SEK ${item.salePrice}/${item.unit}',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
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
                      },
                    ),
            ),
          ],
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
                onItemAdded: () {
                  // Reload items when new item is added
                  loadStoreItems();
                },
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