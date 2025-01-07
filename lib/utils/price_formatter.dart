import 'package:recklamradar/constants/app_constants.dart';
import '../services/currency_service.dart';

class PriceFormatter {
  static final CurrencyService _currencyService = CurrencyService();

  static String formatPrice(double price, [String? currencySymbol]) {
    if (price < 0) {
      throw ArgumentError('Price cannot be negative');
    }
    
    final symbol = currencySymbol ?? 
      AppConstants.currencySymbols[_currencyService.selectedCurrency] ?? 
      _currencyService.selectedCurrency;
    
    return '$symbol${price.toStringAsFixed(2)}';
  }

  static String formatPriceWithUnit(double price, String unit, {double? salePrice}) {
    final formattedPrice = formatPrice(price);
    final unitStr = formatUnit(unit);
    return '$formattedPrice/$unitStr';
  }

  static String formatUnit(String unit) {
    return unit.toLowerCase();
  }

  static String calculateDiscount(double originalPrice, double salePrice) {
    final discount = ((originalPrice - salePrice) / originalPrice * 100).round();
    return '$discount% OFF';
  }
} 