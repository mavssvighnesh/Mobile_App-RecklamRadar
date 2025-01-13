import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  
  // Migrate stores
  final stores = [
    {
      'name': 'City Gross',
      'imageUrl': 'https://your-storage-url/city_gross.png',
      'description': 'City Gross supermarket',
    },
    {
      'name': 'Willys',
      'imageUrl': 'https://your-storage-url/willys.png',
      'description': 'Willys supermarket',
    },
    // Add other stores
  ];

  // Upload stores to Firestore
  for (var store in stores) {
    await firestore.collection('stores').add(store);
  }

  // Migrate deals from JSON files
  final willysDeals = json.decode(
    File('assets/json/willys.json').readAsStringSync(),
  );
  
  // Upload deals to Firestore
  for (var deal in willysDeals) {
    await firestore.collection('deals').add({
      ...deal,
      'storeId': 'willys',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Repeat for other stores' deals
} 