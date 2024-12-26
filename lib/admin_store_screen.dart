import 'package:flutter/material.dart' show AppBar, BoxFit, BuildContext, CircularProgressIndicator, Colors, FloatingActionButton, Icon, Icons, Image, ListView, MaterialPageRoute, Navigator, Scaffold, ScaffoldMessenger, SnackBar, StatelessWidget, Text, Theme, Widget;
import 'package:flutter/widgets.dart';
import 'package:recklamradar/providers/theme_provider.dart';
import 'item_adding_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recklamradar/providers/theme_provider.dart';
import 'package:recklamradar/utils/size_config.dart';

class AdminStoreScreen extends StatelessWidget {
  final String storeId;
  final String storeName;

  const AdminStoreScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(storeName),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: ThemeProvider.cardGradient,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeProvider.subtleGradient,
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('stores')
              .doc(storeId)
              .collection('items')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final items = snapshot.data?.docs ?? [];

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index].data() as Map<String, dynamic>;
                return InteractiveItemCard(item: item);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemAddingPage(
                storeId: storeId,
                storeName: storeName,
                onItemAdded: () {
                  // No need to manually refresh with StreamBuilder
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

class InteractiveItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const InteractiveItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    
    final String name = item["name"]!;
    final String price = item["price"]!;
    final String memberPrice = item["memberPrice"] ?? "N/A";
    final String dateRange = item["dateRange"] ?? "No Date Range";
    final String image = item["image"]!;

    return GestureDetector(
      onTap: () {
        // Action when the card is tapped
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name clicked!')),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(
            vertical: SizeConfig.blockSizeVertical,
            horizontal: SizeConfig.blockSizeHorizontal * 4,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      size: 60,
                      color: Colors.grey.shade400,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Regular Price: $price",
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    Text(
                      "Member Price: $memberPrice",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Available: $dateRange",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

