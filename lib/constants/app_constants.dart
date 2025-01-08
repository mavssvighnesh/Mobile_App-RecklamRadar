class AppConstants {
  // Currency related
  static const String defaultCurrency = 'SEK';
  static const Map<String, String> currencySymbols = {
    'SEK': 'kr',
    'USD': '\$',
    'EUR': '€',
    'INR': '₹',
  };

  // API related
  static const String apiBaseUrl = 'http://apilayer.net/api/live';
  static const String apiKey = '1qflRbfP5gbNMfaNSrOU53mC7RAF4oFn';

  // Storage keys
  static const String currencyPrefsKey = 'selected_currency';
  static const String exchangeRatesKey = 'exchange_rates';
  static const String lastFetchDateKey = 'last_fetch_date';
  static const String budgetAmountKey = 'budget_amount';
  static const String budgetCurrencyKey = 'budget_currency';

  // UI related
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const Duration snackBarDuration = Duration(seconds: 3);
} 