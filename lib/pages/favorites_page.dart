import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_item.dart';
import '../utils/size_config.dart';
import '../providers/theme_provider.dart';
import '../services/cart_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:recklamradar/styles/app_text_styles.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  List<StoreItem> allItems = [];
  List<StoreItem> filteredItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllItems();
  }

  Future<void> _loadAllItems() async {
    setState(() => isLoading = true);
    
    try {
      final storesSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .get();
          
      final items = <StoreItem>[];
      
      for (var store in storesSnapshot.docs) {
        final itemsSnapshot = await store.reference
            .collection('items')
            .get();
            
        items.addAll(
          itemsSnapshot.docs.map((doc) => StoreItem.fromFirestore(doc)),
        );
      }
      
      if (mounted) {
        setState(() {
          allItems = items;
          filteredItems = items;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading items: $e');
      setState(() => isLoading = false);
    }
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredItems = allItems;
      } else {
        filteredItems = allItems
            .where((item) =>
                item.name.toLowerCase().contains(query.toLowerCase()) ||
                item.category.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _addToCart(StoreItem item, String storeId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get store name from Firestore
        final storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(storeId)
            .get();
        
        String storeName = storeDoc.data()?['name'] ?? 'Unknown Store';
        
        await _firestoreService.addToCart(user.uid, item, storeName);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item.name} added to cart')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to add items to cart')),
        );
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add item to cart')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    
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
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(SizeConfig.blockSizeVertical * 8),
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.blockSizeHorizontal * 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterItems,
                  decoration: InputDecoration(
                    hintText: 'Search for deals...',
                    hintStyle: AppTextStyles.bodyMedium(context),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        SizeConfig.blockSizeHorizontal * 3,
                      ),
                    ),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
          ),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(SizeConfig.blockSizeHorizontal * 4),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  mainAxisSpacing: SizeConfig.blockSizeVertical * 2,
                  crossAxisSpacing: SizeConfig.blockSizeHorizontal * 4,
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
        ],
      ),
    );
  }

  Widget _buildItemCard(StoreItem item) {
    return GestureDetector(
      onTap: () => _addToCart(item, item.id.split('/')[0]), // Assuming storeId is first part of item.id
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeConfig.blockSizeHorizontal * 4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(SizeConfig.blockSizeHorizontal * 4),
                  ),
                  child: Image.network(
                    item.imageUrl,
                    height: SizeConfig.blockSizeVertical * 15,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (item.salePrice != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(((item.price - (item.salePrice ?? 0)) / item.price) * 100).round()}% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: SizeConfig.fontSize * 0.8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(SizeConfig.blockSizeHorizontal * 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.cardTitle(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: SizeConfig.blockSizeVertical),
                  Text(
                    item.category,
                    style: AppTextStyles.cardSubtitle(context),
                  ),
                  SizedBox(height: SizeConfig.blockSizeVertical),
                  Row(
                    children: [
                      Text(
                        'SEK ${item.price}',
                        style: AppTextStyles.price(context, isOnSale: item.salePrice != null),
                      ),
                      if (item.salePrice != null) ...[
                        SizedBox(width: SizeConfig.blockSizeHorizontal * 2),
                        Text(
                          'SEK ${item.salePrice}',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: SizeConfig.fontSize * 0.9,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 