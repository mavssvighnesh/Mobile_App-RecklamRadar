
import 'package:flutter/material.dart';

import 'admin_store_screen.dart';
import 'item_adding_page.dart';
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stores Available'),
      ),
      body: ListView(
        children: const [
          StoreTile(storeName: 'City Gross'),
          StoreTile(storeName: 'Willys'),
          StoreTile(storeName: 'Lidl'),
          StoreTile(storeName: 'ICA Maxi'),
          StoreTile(storeName: 'Rusta'),
          StoreTile(storeName: 'Xtra'),
        ],
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

class StoreTile extends StatelessWidget {
  final String storeName;

  const StoreTile({super.key, required this.storeName});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(storeName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AdminStoreScreen(storeName: storeName)),
        );
      },
    );
  }
}
