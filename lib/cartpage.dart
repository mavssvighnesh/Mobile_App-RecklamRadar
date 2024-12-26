import 'package:flutter/material.dart';
import 'package:recklamradar/models/deal.dart';
import 'package:recklamradar/utils/message_utils.dart';
import 'package:recklamradar/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _budgetController = TextEditingController();
  double? maxBudget;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Example data
  final Map<String, List<Map<String, dynamic>>> cartItems = {
    "Willys": [
      {"name": "Carrot", "price": 9.9, "quantity": 3, "picked": false},
    ],
    "Lidl": [
      {"name": "Cabbage", "price": 8.5, "quantity": 2, "picked": false},
      {"name": "Notebook", "price": 25.0, "quantity": 1, "picked": false},
    ],
    "Xtra": [
      {"name": "Apple", "price": 5.0, "quantity": 4, "picked": false},
    ],
  };

  double calculateTotal() {
    double total = 0.0;
    cartItems.forEach((store, items) {
      for (var item in items) {
        total += item["price"] * item["quantity"];
      }
    });
    return total;
  }

  void updatePickedStatus(String store, int index) {
    setState(() {
      cartItems[store]![index]["picked"] =
          !cartItems[store]![index]["picked"]; // Toggle picked status
    });
  }

  void deleteItem(String store, int index) {
    setState(() {
      cartItems[store]!.removeAt(index);
      if (cartItems[store]!.isEmpty) {
        cartItems.remove(store); // Remove store section if no items are left
      }
    });
  }

  void editItemQuantity(String store, int index, int newQuantity) {
    setState(() {
      cartItems[store]![index]["quantity"] = newQuantity;
    });
  }

  Future<void> addToCart(Deal deal) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestoreService.addToCart(userId, deal);
        showMessage(context, "Added to cart successfully", true);
      }
    } catch (e) {
      showMessage(context, "Error adding to cart: $e", false);
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    try {
      await _firestoreService.removeFromCart(cartItemId);
      showMessage(context, "Removed from cart successfully", true);
    } catch (e) {
      showMessage(context, "Error removing from cart: $e", false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double total = calculateTotal();
    double balance = (maxBudget ?? 0) - total;

    return Material(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.keys.length,
                    itemBuilder: (context, index) {
                      final store = cartItems.keys.elementAt(index);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          ...cartItems[store]!.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, dynamic> item = entry.value;
                            return Dismissible(
                              key: Key("${store}_${item['name']}"),
                              direction: DismissDirection.horizontal,
                              onDismissed: (direction) {
                                if (direction == DismissDirection.startToEnd) {
                                  updatePickedStatus(store, index);
                                } else if (direction ==
                                    DismissDirection.endToStart) {
                                  deleteItem(store, index);
                                }
                              },
                              background: Container(
                                color: Colors.green,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 16),
                                child: const Icon(Icons.check_circle, color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(8),
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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Item Details
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item["name"],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          "${item["price"]} SEK",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          "${item["quantity"]} kg",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Actions
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () {
                                            // Open dialog to edit quantity
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                TextEditingController
                                                    quantityController =
                                                    TextEditingController(
                                                        text: item["quantity"]
                                                            .toString());
                                                return AlertDialog(
                                                 title: Text("Edit Quantity: ${item['name']}"),
                                                  content: TextField(
                                                    controller: quantityController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration: const InputDecoration(
                                                      labelText: "Quantity",
                                                      border: OutlineInputBorder(),
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text("Cancel"),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        int? newQuantity = int
                                                            .tryParse(
                                                                quantityController
                                                                    .text);
                                                        if (newQuantity != null &&
                                                            newQuantity > 0) {
                                                          editItemQuantity(
                                                              store, index,
                                                              newQuantity);
                                                          Navigator.pop(context);
                                                        }
                                                      },
                                                      child: const Text("Save"),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            item["picked"]
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color: item["picked"]
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                          onPressed: () {
                                            updatePickedStatus(store, index);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () {
                                            deleteItem(store, index);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),

                // Floating Total
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total:",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${total.toStringAsFixed(2)} SEK",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
