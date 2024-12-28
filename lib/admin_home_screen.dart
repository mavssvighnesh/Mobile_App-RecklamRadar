import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recklamradar/providers/theme_provider.dart';

import 'admin_store_screen.dart';
import 'package:recklamradar/item_adding_page.dart';
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stores = [
      {'id': 'citygross', 'name': 'City Gross'},
      {'id': 'willys', 'name': 'Willys'},
      {'id': 'lidl', 'name': 'Lidl'},
      {'id': 'icamaxi', 'name': 'ICA Maxi'},
      {'id': 'rusta', 'name': 'Rusta'},
      {'id': 'xtra', 'name': 'Xtra'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stores Available'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Provider.of<ThemeProvider>(context).cardGradient,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: Provider.of<ThemeProvider>(context).subtleGradient,
        ),
        child: ListView.builder(
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final store = stores[index];
            return StoreTile(
              storeId: store['id']!,
              storeName: store['name']!,
            );
          },
        ),
      ),
    );
  }
}

class StoreTile extends StatelessWidget {
  final String storeId;
  final String storeName;

  const StoreTile({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(storeName),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminStoreScreen(
                storeId: storeId,
                storeName: storeName,
              ),
            ),
          );
        },
      ),
    );
  }
}
