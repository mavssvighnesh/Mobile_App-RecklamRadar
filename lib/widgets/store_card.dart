import 'package:flutter/material.dart';

class StoreCard extends StatelessWidget {
  final Map<String, dynamic> store;

  const StoreCard({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            store["image"],
            width: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Text(
            store["name"],
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