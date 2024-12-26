import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;

  // Sample store data
  final stores = [
    {
      'id': 'willys',
      'name': 'Willys',
      'imageUrl': 'assets/images/stores/willys.png',
      'description': 'Willys Supermarket',
      'items': [
        {
          'name': 'Carrots',
          'category': 'Groceries',
          'price': 11.99,
          'salePrice': 9.99,
          'imageUrl': 'https://example.com/carrots.jpg',
          'unit': 'KG',
          'inStock': true,
        },
        // Add more items...
      ],
    },
    // Add more stores...
  ];

  // Upload data
  for (var store in stores) {
    final storeId = store['id'] as String;
    final items = store['items'] as List;
    
    // Create store document
    await firestore.collection('stores').doc(storeId).set({
      'name': store['name'],
      'imageUrl': store['imageUrl'],
      'description': store['description'],
    });

    // Add items to subcollection
    for (var item in items) {
      await firestore
          .collection('stores')
          .doc(storeId)
          .collection('items')
          .add(item);
    }
  }
} 