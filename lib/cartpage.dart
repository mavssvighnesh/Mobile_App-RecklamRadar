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
import 'package:recklamradar/services/currency_service.dart';
import 'package:recklamradar/widgets/glass_container.dart';
import 'package:recklamradar/widgets/glass_dialog.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final CurrencyService _currencyService = CurrencyService();
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
  final bool _isLoading = false;
  late StreamSubscription _currencySubscription;
  String _budgetCurrency = 'SEK';

  @override
  void initState() {
    super.initState();
    _initializeCartStream();
    _loadSavedBudget();
    _scrollController.addListener(_onScroll);
    
    // Listen to currency changes
    _currencySubscription = _currencyService.currencyStream.listen((newCurrency) {
      _updateBudgetForNewCurrency(_budgetCurrency, newCurrency);
      _budgetCurrency = newCurrency;
      setState(() {});
    });
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
    final budgetData = await _currencyService.loadBudget();
    if (budgetData['amount'] != null && mounted) {
      final convertedAmount = _currencyService.convertBetweenCurrencies(
        budgetData['amount']!,
        budgetData['currency']!,
        _currencyService.selectedCurrency,
      );
      setState(() {
        maxBudget = convertedAmount;
        _budgetController.text = convertedAmount.toStringAsFixed(2);
        _budgetCurrency = _currencyService.selectedCurrency;
      });
    }
  }

  void _updateBudgetForNewCurrency(String oldCurrency, String newCurrency) {
    if (maxBudget != null) {
      final convertedBudget = _currencyService.convertBetweenCurrencies(
        maxBudget!,
        oldCurrency,
        newCurrency,
      );
      setState(() {
        maxBudget = convertedBudget;
        _budgetController.text = convertedBudget.toStringAsFixed(2);
      });
    }
  }

  void _updateBudget() async {
    if (_formKey.currentState?.validate() ?? false) {
      final newBudget = double.tryParse(_budgetController.text);
      if (newBudget != null) {
        await _currencyService.saveBudget(
          newBudget,
          _currencyService.selectedCurrency,
        );
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
    _currencySubscription.cancel(); // Cancel the subscription
    super.dispose();
  }

  double calculateTotal(Map<String, List<Map<String, dynamic>>> items) {
    double totalSEK = 0.0;
    items.forEach((store, itemList) {
      for (var item in itemList) {
        // Always use sale price if available, otherwise use regular price
        final effectivePriceSEK = item['salePrice'] ?? item['price'];
        final quantity = item['quantity'] ?? 1;
        totalSEK += effectivePriceSEK * quantity;
      }
    });
    
    // Convert only the final total for display
    return _currencyService.convertPrice(totalSEK);
  }

  void _removeItem(String store, Map<String, dynamic> item) async {
    await _firestoreService.removeFromCart(_auth.currentUser!.uid, item['id']);
    showMessage(context, "${item['name']} removed from cart", true);
  }

  void _editQuantity(String store, Map<String, dynamic> item) {
    final TextEditingController quantityController = TextEditingController(
      text: item['quantity'].toString(),
    );
    
    showDialog(
      context: context,
      builder: (context) => GlassDialog(
        title: 'Edit ${item['name']} Quantity',
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'New Quantity',
            labelStyle: TextStyle(color: Theme.of(context).primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(
              Icons.shopping_cart,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
            child: const Text('Update'),
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) {
          FocusScope.of(context).unfocus();
          _updateBudget();
        },
        decoration: InputDecoration(
          labelText: 'Set Maximum Budget (${_currencyService.selectedCurrency})',
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
            '${_currencyService.formatPrice(total)} ${_currencyService.selectedCurrency}',
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
            'Remaining: ${_currencyService.formatPrice(balance)} ${_currencyService.selectedCurrency}',
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
        GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        ...items.map((item) => _buildCartItem(store, item)),
      ],
    );
  }

  Widget _buildCartItem(String store, Map<String, dynamic> item) {
    // Get SEK prices from Firestore and use sale price when available
    final hasDiscount = item['salePrice'] != null;
    final effectivePriceSEK = hasDiscount ? item['salePrice'] : item['price'];
    final quantity = item['quantity'] ?? 1;
    
    // Calculate total in SEK using effective price
    final totalSEK = effectivePriceSEK * quantity;
    
    // Convert for display
    final displayUnitPrice = _currencyService.convertPrice(effectivePriceSEK);
    final displayTotal = _currencyService.convertPrice(totalSEK);
    
    // Only show original price if there's a discount
    final displayOriginalPrice = hasDiscount ? 
      _currencyService.convertPrice(item['price']) : null;

    return Dismissible(
      key: Key('$store-${item['name']}'),
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
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 50,
                height: 50,
                child: CachedNetworkImage(
                  imageUrl: item['imageUrl'] ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.error,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item['name'],
                    style: AppTextStyles.cardTitle(context).copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_currencyService.formatPrice(displayUnitPrice)} × $quantity',
                    style: AppTextStyles.bodyMedium(context).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (displayOriginalPrice != null)
                  Text(
                    _currencyService.formatPrice(displayOriginalPrice * quantity),
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                Text(
                  _currencyService.formatPrice(displayTotal),
                  style: AppTextStyles.price(context).copyWith(fontSize: 14),
                ),
                Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    value: item['picked'] ?? false,
                    onChanged: (value) async {
                      await _firestoreService.updateCartItemPicked(
                        _auth.currentUser!.uid,
                        item['id'],
                        value ?? false,
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
