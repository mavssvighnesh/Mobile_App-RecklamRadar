import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter/services.dart';


class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
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
      List<Map<String, dynamic>> allDeals = [];
      // Load data from JSON files
      final willysData =
          await rootBundle.loadString('assets/json/willys.json');
      final lidlData =
          await rootBundle.loadString('assets/json/lidl.json');
      final citygrossData =
          await rootBundle.loadString('assets/json/city_gross.json');
      final rustaData =
          await rootBundle.loadString('assets/json/rusta.json');

      // Parse and add products to allDeals
      allDeals.addAll(List<Map<String, dynamic>>.from(json.decode(willysData)));
      allDeals.addAll(List<Map<String, dynamic>>.from(json.decode(lidlData)));
      allDeals.addAll(List<Map<String, dynamic>>.from(json.decode(citygrossData)));
      allDeals.addAll(List<Map<String, dynamic>>.from(json.decode(rustaData)));

      setState(() {
        deals = allDeals;
        displayedDeals = deals;
      });
    } catch (e) {
      print("Error loading JSON data: $e");
    }
  }

  void filterDeals(String? filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == null || filter.isEmpty) {
        displayedDeals = deals; // Show all if no filter
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearchActive
            ? TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: "Search for products",
                  border: InputBorder.none,
                ),
                onChanged: (query) => searchDeals(query),
              )
            : const Text(
                "Deals",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isSearchActive ? Icons.close : Icons.search,
              color: Colors.black54,
            ),
            onPressed: () {
              setState(() {
                if (isSearchActive) {
                  searchController.clear();
                  displayedDeals = deals; // Reset when closing search
                }
                isSearchActive = !isSearchActive;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.black54),
            onPressed: () {
              showFilterDialog();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two items per row
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 3 / 4,
          ),
          itemCount: displayedDeals.length,
          itemBuilder: (context, index) {
            final deal = displayedDeals[index];
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
                    child: Image.asset(
                      deal["image"],
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
                          deal["name"],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${deal["price"]} SEK",
                          style: const TextStyle(
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          "${deal["memberPrice"]}  at ${deal["store"]} ",
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
        ),
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