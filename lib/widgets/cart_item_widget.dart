import 'package:flutter/material.dart';
import '../models/store_item.dart';
import '../utils/price_formatter.dart';
import '../styles/app_text_styles.dart';
import '../services/currency_service.dart';

class CartItemWidget extends StatelessWidget {
  final StoreItem item;
  final Function(StoreItem) onRemove;
  final Function(StoreItem, bool) onQuantityChanged;
  final CurrencyService currencyService;

  const CartItemWidget({
    Key? key,
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
    required this.currencyService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use SEK prices for calculations
    final basePriceSEK = item.originalSalePriceSEK ?? item.originalPriceSEK;
    final totalPriceSEK = basePriceSEK * item.quantity;

    // Convert only for display
    final displayUnitPrice = currencyService.convertPrice(basePriceSEK);
    final displayTotalPrice = currencyService.convertPrice(totalPriceSEK);
    final displayOriginalPrice = item.originalSalePriceSEK != null ? 
      currencyService.convertPrice(item.originalPriceSEK) : null;

    return Container(
      key: Key('cart_item_${item.id}'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Image section
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              
              // Content section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.bodySmall(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.storeName,
                      style: AppTextStyles.bodySmall(context),
                    ),
                    const SizedBox(height: 4),
                    
                    // Price section
                    if (displayOriginalPrice != null) ...[
                      Text(
                        PriceFormatter.formatPrice(displayOriginalPrice * item.quantity),
                        style: AppTextStyles.price(context, isOnSale: true).copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 12,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              PriceFormatter.formatPrice(displayTotalPrice),
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      Text(
                        PriceFormatter.formatPrice(displayTotalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    
                    // Unit price
                    Text(
                      PriceFormatter.formatPriceWithUnit(displayUnitPrice, item.unit),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Quantity controls
              Column(
                children: [
                  IconButton(
                    key: Key('remove_item_${item.id}'),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => onRemove(item),
                  ),
                  IconButton(
                    key: Key('increment_quantity_${item.id}'),
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => onQuantityChanged(item, true),
                  ),
                  Text(
                    '${item.quantity}',
                    key: Key('quantity_${item.id}'),
                    style: AppTextStyles.bodySmall(context),
                  ),
                  IconButton(
                    key: Key('decrement_quantity_${item.id}'),
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => onQuantityChanged(item, false),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 