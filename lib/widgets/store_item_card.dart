import 'package:flutter/material.dart';

class StoreItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const StoreItemCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(item['name']),
        subtitle: Text(item['price'].toString()),
        leading: Image.network(item['imageUrl'], width: 50, height: 50),
      ),
    );
  }
} 