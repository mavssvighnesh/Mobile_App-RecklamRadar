import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recklamradar/models/deal.dart';
import 'package:recklamradar/services/firestore_service.dart';
import 'package:recklamradar/models/deal.dart';
import 'package:recklamradar/utils/message_utils.dart';
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> deals = [];
  List<Map<String, dynamic>> displayedDeals = [];
  TextEditingController searchController = TextEditingController();
  bool isSearchActive = false;
  String? selectedFilter;

  @override
  void initState() {
    super.initState();
    loadDeals();
  }

  Future<void> loadDeals() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      final List<Map<String, dynamic>> allDeals = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        // Fetch the actual deal details
        final dealDoc = await FirebaseFirestore.instance
            .collection('deals')
            .doc(data['dealId'])
            .get();
            
        if (dealDoc.exists) {
          final dealData = dealDoc.data()!;
          allDeals.add({
            'id': dealDoc.id,
            'name': dealData['name'],
            'store': dealData['store'],
            'price': dealData['price'],
            'memberPrice': dealData['memberPrice'],
            'category': dealData['category'],
            'imageUrl': dealData['imageUrl'],
            'startDate': dealData['startDate'],
            'endDate': dealData['endDate'],
          });
        }
      }

      setState(() {
        deals = allDeals;
        displayedDeals = deals;
      });
    } catch (e) {
      print("Error loading favorites: $e");
    }
  }

  void filterDeals(String? filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == null || filter.isEmpty) {
        displayedDeals = deals;
      } else {
        displayedDeals = deals
            .where((deal) =>
                deal['store'] == filter || deal['category'] == filter)
            .toList();
      }
    });
  }

  void searchDeals(String query) {
    setState(() {
      if (query.isEmpty) {
        displayedDeals = deals;
      } else {
        displayedDeals = deals
            .where((deal) =>
                deal['name'].toLowerCase().contains(query.toLowerCase()) ||
                deal['store'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> toggleFavorite(String dealId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestoreService.toggleFavorite(userId, dealId);
        showMessage(
          context, 
          "Updated favorites successfully", 
          true
        );
      }
    } catch (e) {
      showMessage(context, "Error updating favorites: $e", false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getFavoriteDeals(_auth.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final deals = snapshot.data?.docs
              .map((doc) => Deal.fromFirestore(doc))
              .toList() ?? [];

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3 / 4,
            ),
            itemCount: deals.length,
            itemBuilder: (context, index) {
              final deal = deals[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 5,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      child: Image.network(
                        deal.imageUrl,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Text("Image not found"));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deal.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${deal.price} SEK",
                            style: const TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            "${deal.price}  at ${deal.name} ",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Add to cart functionality
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Add to Cart"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filter"),
          content: DropdownButton<String>(
            isExpanded: true,
            value: selectedFilter,
            items: const [
              DropdownMenuItem(value: null, child: Text("All")),
              DropdownMenuItem(value: "Willys", child: Text("Willys")),
              DropdownMenuItem(value: "Lidl", child: Text("Lidl")),
              DropdownMenuItem(value: "Groceries", child: Text("Groceries")),
              DropdownMenuItem(value: "Stationery", child: Text("Stationery")),
            ],
            onChanged: (filter) {
              filterDeals(filter);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}
