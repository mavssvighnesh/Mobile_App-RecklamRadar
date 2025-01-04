import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:recklamradar/utils/size_config.dart';



class StoreDealsPage extends StatefulWidget {
  final String storeName;

  const StoreDealsPage({super.key, required this.storeName});

  @override
  _StoreDealsPageState createState() => _StoreDealsPageState();
}

class _StoreDealsPageState extends State<StoreDealsPage> {
   List<Map<String, dynamic>> storeItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool isLoading = true;
  bool isSearchActive = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadStoreData(widget.storeName); // Load the data for the selected store
  }

  Future<void> loadStoreData(String storeName) async {
    try {
      String jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/json/${storeName.toLowerCase().replaceAll(' ', '_')}.json');
      List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        storeItems = List<Map<String, dynamic>>.from(jsonData);
        filteredItems = storeItems; // Initially display all items
        isLoading = false;
      });
    } catch (error) {
      print("Error loading JSON: $error");
    }
  }


  void searchItems(String query) {
    setState(() {
      filteredItems = storeItems
          .where((item) =>
              item["name"].toLowerCase().contains(query.toLowerCase()) ||
              (item["category"] ?? "").toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }
 void filterItemsByCategory(String? category) {
    setState(() {
      // ignore: unused_local_variable
      var selectedCategory = category;
      if (category == null) {
        filteredItems = storeItems;
      } else {
        filteredItems = storeItems
            .where((item) => item["category"].toLowerCase() == category.toLowerCase())
            .toList();
      }
    });
  }

  void addToCart(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${item['name']} added to cart")),
    );
  }

  void removeFromCart(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${item['name']} removed from cart")),
    );
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: isSearchActive
            ? TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: "Search products or categories...",
                  border: InputBorder.none,
                ),
                onChanged: searchItems,
              )
            : Text(
                widget.storeName,
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(isSearchActive ? Icons.close : Icons.search, color: Colors.black54),
            onPressed: () {
              setState(() {
                if (isSearchActive) searchController.clear();
                isSearchActive = !isSearchActive;
                filteredItems = storeItems; // Reset search results
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.black54),
            onPressed: () {
              // Open a filter menu
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Filter by Category",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ListTile(
                          title: const Text("All"),
                          onTap: () {
                            filterItemsByCategory(null);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text("Groceries"),
                          onTap: () {
                            filterItemsByCategory("Groceries");
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text("Stationary"),
                          onTap: () {
                            filterItemsByCategory("Stationary");
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text("Household"),
                          onTap: () {
                            filterItemsByCategory("Household");
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text("Drinks"),
                          onTap: () {
                            filterItemsByCategory("Drinks");
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text("Foods"),
                          onTap: () {
                            filterItemsByCategory("Foods");
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: ListView.builder(
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            return Dismissible(
              key: Key(item["name"]),
              direction: DismissDirection.startToEnd,
              onDismissed: (direction) {
                addToCart(item);
              },
              background: Container(
                color: Colors.green,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16),
                child: const Icon(Icons.add_shopping_cart, color: Colors.white),
              ),
              secondaryBackground: Container(
                color: Colors.transparent,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 5,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product Image
                    Container(
                      width: SizeConfig.blockSizeHorizontal * 25,
                      height: SizeConfig.blockSizeVertical * 12,
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item["image"]!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_not_supported, size: 60);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Product Details
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["name"]!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item["category"]!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                "${item["price"]!}/${item['unit']}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: item["memberPrice"] != null 
                                      ? Colors.black54  // Dimmed if there's a member price
                                      : Colors.black87, // Normal black if no member price
                                  decoration: item["memberPrice"] != null 
                                      ? TextDecoration.lineThrough  // Strike through if there's a member price
                                      : null,
                                ),
                              ),
                              if (item["memberPrice"] != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "${item["memberPrice"]!}/${item['unit']}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Quantity Section
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                if (item["quantity"] > 1) item["quantity"]--;
                              });
                            },
                          ),
                          Container(
                            width: 25,
                            height: 25,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              textAlign: TextAlign.center,
                              controller: TextEditingController(
                                text: item["quantity"].toString(),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  item["quantity"] = int.tryParse(value) ?? 0;
                                });
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                item["quantity"]++;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}