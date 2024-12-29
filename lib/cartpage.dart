import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recklamradar/services/firestore_service.dart';
import 'package:recklamradar/providers/theme_provider.dart';
import 'package:recklamradar/utils/message_utils.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:recklamradar/styles/app_text_styles.dart';

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
  Timer? _debounceTimer;
  final _formKey = GlobalKey<FormState>();
  late Stream<Map<String, List<Map<String, dynamic>>>> _cartStream;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  // ignore: unused_field
  double _titleOpacity = 0.0;
  static const String _budgetKey = 'cart_max_budget';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCartStream();
    _loadSavedBudget();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrollOffset = _scrollController.offset;
    // ignore: unused_local_variable
    final maxScroll = _scrollController.position.maxScrollExtent;
    
    setState(() {
      _isScrolled = scrollOffset > 0;
      _titleOpacity = (scrollOffset / 100).clamp(0.0, 1.0);
      
      // Hide keyboard when scrolling
      FocusScope.of(context).unfocus();
    });
  }

  void _initializeCartStream() {
    if (_auth.currentUser == null) {
      _cartStream = Stream.value({});
      return;
    }

    _cartStream = _firestoreService
        .getCartItems(_auth.currentUser!.uid)
        .map((cartItems) {
      Map<String, List<Map<String, dynamic>>> groupedItems = {};
      for (var item in cartItems) {
        String storeName = item['storeName'] ?? 'Unknown Store';
        if (!groupedItems.containsKey(storeName)) {
          groupedItems[storeName] = [];
        }
        groupedItems[storeName]!.add(item);
      }
      return groupedItems;
    });
  }

  Future<void> _loadSavedBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBudget = prefs.getDouble(_budgetKey);
    if (savedBudget != null && mounted) {
      setState(() {
        maxBudget = savedBudget;
        _budgetController.text = savedBudget.toString();
      });
    }
  }

  void _updateBudget() async {
    if (_formKey.currentState?.validate() ?? false) {
      final newBudget = double.tryParse(_budgetController.text);
      if (newBudget != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_budgetKey, newBudget);
        setState(() => maxBudget = newBudget);
        showMessage(context, "Budget updated successfully", true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounceTimer?.cancel();
    _budgetController.dispose();
    super.dispose();
  }

  double calculateTotal(Map<String, List<Map<String, dynamic>>> items) {
    double total = 0.0;
    items.forEach((store, storeItems) {
      for (var item in storeItems) {
        total += (item["price"] ?? 0.0) * (item["quantity"] ?? 1);
      }
    });
    return total;
  }

  void _removeItem(String store, Map<String, dynamic> item) async {
    await _firestoreService.removeFromCart(_auth.currentUser!.uid, item['id']);
    showMessage(context, "${item['name']} removed from cart", true);
  }

  void _editQuantity(String store, Map<String, dynamic> item) {
    final TextEditingController quantityController = TextEditingController(text: item['quantity'].toString());
    
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
            controller: quantityController,
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
              gradient: Provider.of<ThemeProvider>(context).cardGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () async {
                int? newQuantity = int.tryParse(quantityController.text);
                if (newQuantity != null && newQuantity > 0) {
                  await _firestoreService.updateCartItemQuantity(
                    _auth.currentUser!.uid,
                    item['id'],
                    newQuantity,
                  );
                  Navigator.pop(context);
                  showMessage(context, "Quantity updated", true);
                }
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

  String? _validateBudget(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    if (double.parse(value) <= 0) {
      return 'Budget must be greater than 0';
    }
    return null;
  }

  Widget _buildBudgetField() {
    return Form(
      key: _formKey,
      child: TextField(
        controller: _budgetController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) {
          FocusScope.of(context).unfocus();
          _updateBudget();
        },
        decoration: InputDecoration(
          labelText: 'Set Maximum Budget (SEK)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: const Icon(Icons.account_balance_wallet),
          errorText: _validateBudget(_budgetController.text),
          suffixIcon: IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              FocusScope.of(context).unfocus();
              _updateBudget();
            },
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${total.toStringAsFixed(2)} SEK',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Container(
        decoration: BoxDecoration(
          gradient: _isScrolled 
              ? null 
              : Provider.of<ThemeProvider>(context).cardGradient,
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isScrolled ? 0.0 : 1.0,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Shopping Cart',
                    style: AppTextStyles.heading1(context),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isScrolled ? 0.0 : 1.0,
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _initializeCartStream,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildLoadingOverlay() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isLoading ? 1.0 : 0.0,
      child: _isLoading
          ? Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: Provider.of<ThemeProvider>(context).subtleGradient,
        ),
        child: StreamBuilder<Map<String, List<Map<String, dynamic>>>>(
          stream: _cartStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print('Cart stream error: ${snapshot.error}');
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final cartItems = snapshot.data ?? {};
            final total = calculateTotal(cartItems);
            final balance = (maxBudget ?? 0) - total;

            return Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 20,
                            left: 16,
                            right: 16,
                            bottom: 16,
                          ),
                          child: Column(
                            children: [
                              _buildBudgetField(),
                              if (maxBudget != null) ...[
                                const SizedBox(height: 12),
                                _buildBudgetInfo(balance),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Cart Items
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        sliver: cartItems.isEmpty
                            ? SliverFillRemaining(child: _buildEmptyCart())
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final store = cartItems.keys.elementAt(index);
                                    final storeItems = cartItems[store]!;
                                    return _buildStoreSection(store, storeItems);
                                  },
                                  childCount: cartItems.length,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                _buildTotalSection(total),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBudgetInfo(double balance) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: balance >= 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 1,
        ),
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
    );
  }

  Widget _buildStoreSection(String store, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.store,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                store,
                style: AppTextStyles.heading3(context),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildCartItem(store, item)).toList(),
      ],
    );
  }

  Widget _buildCartItem(String store, Map<String, dynamic> item) {
    return Dismissible(
      key: Key('${store}-${item['name']}'),
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _removeItem(store, item);
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _editQuantity(store, item);
          return false;
        }
        return true;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CachedNetworkImage(
              imageUrl: item['imageUrl'] ?? '',
              placeholder: (context, url) => Container(
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
              errorWidget: (context, url, error) => Icon(
                Icons.error,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              item['name'],
              style: AppTextStyles.cardTitle(context),
            ),
            subtitle: Text(
              '${item['price']} SEK x ${item['quantity']}',
              style: AppTextStyles.bodyMedium(context),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(item['price'] * item['quantity']).toStringAsFixed(2)} SEK',
                  style: AppTextStyles.price(context),
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 1.2,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item['picked'] ? Theme.of(context).primaryColor : Colors.transparent,
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    child: InkWell(
                      onTap: () async {
                        await _firestoreService.updateCartItemPicked(
                          _auth.currentUser!.uid,
                          item['id'],
                          !item['picked'],
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: item['picked']
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : const SizedBox(width: 16, height: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
