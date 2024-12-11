
import 'package:flutter/material.dart' show AppBar, BoxFit, BuildContext, Colors, FloatingActionButton, Icon, Icons, Image, ListView, MaterialPageRoute, Navigator, Scaffold, ScaffoldMessenger, SnackBar, StatelessWidget, Text, Widget;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'item_adding_page.dart';

class AdminStoreScreen extends StatelessWidget {
  final String storeName;

  const AdminStoreScreen({super.key, required this.storeName});

  @override
  Widget build(BuildContext context) {
    // List of items with additional data
    final List<Map<String, String>> items = [
      {
        "name": "Carrots",
        "price": "SEK 11.99/KG",
        "memberPrice": "SEK 9.99/KG",
        "dateRange": "2024-01-01 to 2024-01-15",
        "image": "assets/images/carrots.png"
      },
      {
        "name": "Cabbage",
        "price": "SEK 15.99/KG",
        "memberPrice": "SEK 13.99/KG",
        "dateRange": "2024-01-05 to 2024-01-20",
        "image": "assets/images/cabbage.png"
      },
      {
        "name": "Beetroot",
        "price": "SEK 19.99/KG",
        "memberPrice": "SEK 16.99/KG",
        "dateRange": "2024-01-10 to 2024-01-25",
        "image": "assets/images/beetroot.png"
      },

    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(storeName),
      ),
      body: ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final item = items[index];
    return InteractiveItemCard(item: item);
  },
),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ItemAddingPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class InteractiveItemCard extends StatelessWidget {
  final Map<String, String> item;

  const InteractiveItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
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
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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

