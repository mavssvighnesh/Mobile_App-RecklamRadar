import 'package:recklamradar/constants/app_constants.dart';

import '../services/currency_service.dart';

class PriceFormatter {
  static final CurrencyService _currencyService = CurrencyService();

  static String formatPrice(double price) {
    final currency = _currencyService.selectedCurrency;
    final symbol = AppConstants.currencySymbols[currency] ?? currency;
    
    return price < 100 
        ? '${price.toStringAsFixed(2)} $symbol'  // 99.90 kr
        : '${price.toStringAsFixed(0)} $symbol'; // 100 kr
  }

  static String formatPriceWithCurrency(double price) {
    return _currencyService.formatPriceWithCurrency(price);
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