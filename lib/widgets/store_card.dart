import 'package:flutter/material.dart';

class StoreCard extends StatelessWidget {
  final Map<String, dynamic> store;
  final int index;

  const StoreCard({
    super.key,
    required this.store,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('store_card_${store["name"]}'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            store["image"],
            width: 80,
            fit: BoxFit.contain,
            key: Key('store_image_${store["name"]}'),
          ),
          const SizedBox(height: 8),
          Text(
            store["name"],
            key: Key('store_name_${store["name"]}'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 