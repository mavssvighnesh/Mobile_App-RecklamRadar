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
  bool isLoading = true;
  String? selectedFilter;
  Set<String> categories = {};
  Set<String> stores = {};

  @override
  void initState() {
    super.initState();
    _loadAllItems();
  }

  Future<void> _loadAllItems() async {
    setState(() => isLoading = true);
    try {
      // Get all stores
      final storesSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .get();
      
      final items = <StoreItem>[];
      
      // For each store, get their items
      for (var store in storesSnapshot.docs) {
        final itemsSnapshot = await store.reference
            .collection('items')
            .get();
            
        items.addAll(
          itemsSnapshot.docs.map((doc) {
            final item = StoreItem.fromFirestore(doc);
            // Add store name to item
            return item.copyWith(storeName: store.id);
          }),
        );
      }

      // Get unique categories and stores
      categories = items.map((item) => item.category).toSet();
      stores = items.map((item) => item.storeName).toSet();

      if (mounted) {
        setState(() {
          allItems = items;
          filteredItems = items;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading items: $e');
      if (mounted) {
        showMessage(context, 'Error loading items', false);
        setState(() => isLoading = false);
      }
    }
  }

  void _filterItems(String query) {
    setState(() {
      filteredItems = allItems.where((item) {
        bool matchesSearch = query.isEmpty ||
            item.name.toLowerCase().contains(query.toLowerCase()) ||
            item.category.toLowerCase().contains(query.toLowerCase()) ||
            item.storeName.toLowerCase().contains(query.toLowerCase());
        
        bool matchesFilter = selectedFilter == null ||
            item.category == selectedFilter ||
            item.storeName == selectedFilter;
            
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Filter Items",
            style: AppTextStyles.heading3(context),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                isExpanded: true,
                value: selectedFilter,
                items: [
                  const DropdownMenuItem(value: null, child: Text("All")),
                  ...stores.map((store) => DropdownMenuItem(
                        value: store,
                        child: Text("Store: $store"),
                      )),
                  ...categories.map((category) => DropdownMenuItem(
                        value: category,
                        child: Text("Category: $category"),
                      )),
                ],
                onChanged: (filter) {
                  setState(() => selectedFilter = filter);
                  _filterItems(_searchController.text);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
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
                'Discover Deals',
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
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(SizeConfig.blockSizeVertical * 8),
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.blockSizeHorizontal * 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterItems,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
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
          else if (filteredItems.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No items found',
                  style: AppTextStyles.bodyLarge(context),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(SizeConfig.blockSizeHorizontal * 4),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  childAspectRatio: 0.75,
                  mainAxisSpacing: SizeConfig.blockSizeVertical * 2,
                  crossAxisSpacing: SizeConfig.blockSizeHorizontal * 4,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.salePrice != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(((item.price - item.salePrice!) / item.price) * 100).round()}% OFF',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Image.network(
              item.imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.cardTitle(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.storeName,
                  style: AppTextStyles.cardSubtitle(context),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.salePrice != null) ...[
                          Text(
                            'SEK ${item.price}',
                            style: AppTextStyles.price(context, isOnSale: true),
                          ),
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
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () async {
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
                                '${item.name} added to cart',
                                true,
                              );
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 