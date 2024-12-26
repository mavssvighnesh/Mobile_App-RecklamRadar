import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recklamradar/services/firestore_service.dart';
import 'package:recklamradar/providers/theme_provider.dart';
import 'package:recklamradar/utils/message_utils.dart';

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

  void _removeItem(String store, Map<String, dynamic> item) {
    setState(() {
      cartItems[store]?.remove(item);
      if (cartItems[store]?.isEmpty ?? false) {
        cartItems.remove(store);
      }
    });
    showMessage(context, "${item['name']} removed from cart", true);
  }

  void _editQuantity(String store, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        title: Text(
          'Edit ${item['name']} Quantity',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'New Quantity',
              labelStyle: TextStyle(color: Theme.of(context).primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                Icons.shopping_cart,
                color: Theme.of(context).primaryColor,
              ),
            ),
            controller: TextEditingController(text: item['quantity'].toString()),
            onChanged: (value) {
              int? newQuantity = int.tryParse(value);
              if (newQuantity != null && newQuantity > 0) {
                setState(() {
                  item['quantity'] = newQuantity;
                });
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: ThemeProvider.cardGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showMessage(context, "Quantity updated", true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double total = calculateTotal();
    double balance = (maxBudget ?? 0) - total;

    return Material(
      child: Container(
        decoration: BoxDecoration(
          gradient: ThemeProvider.subtleGradient,
        ),
        child: Column(
          children: [
            // Budget Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: ThemeProvider.cardGradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Shopping Cart',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Set Maximum Budget (SEK)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                      ),
                      onChanged: (value) {
                        setState(() {
                          maxBudget = double.tryParse(value);
                        });
                      },
                    ),
                  ),
                  if (maxBudget != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: balance >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            balance >= 0 ? Icons.check_circle : Icons.warning,
                            color: balance >= 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remaining: ${balance.toStringAsFixed(2)} SEK',
                            style: TextStyle(
                              color: balance >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Cart Items List
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final store = cartItems.keys.elementAt(index);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.store, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              store,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...cartItems[store]!.map((item) => _buildCartItem(store, item)).toList(),
                    ],
                  );
                },
              ),
            ),

            // Total Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: ThemeProvider.cardGradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${total.toStringAsFixed(2)} SEK',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Implement checkout
                        showMessage(context, "Proceeding to checkout...", true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Proceed to Checkout',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(String store, Map<String, dynamic> item) {
    return Dismissible(
      key: Key('${store}-${item['name']}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.blue,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _removeItem(store, item);
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          _editQuantity(store, item);
          return false;
        }
        return true;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_cart,
              color: Theme.of(context).primaryColor,
            ),
          ),
          title: Text(
            item['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${item['price']} SEK x ${item['quantity']}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(item['price'] * item['quantity']).toStringAsFixed(2)} SEK',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Checkbox(
                value: item['picked'],
                onChanged: (bool? value) {
                  setState(() {
                    item['picked'] = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
