import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  static const String _baseUrl = 'http://apilayer.net/api/live';
  static const String _apiKey = '3d5207802c94cd3f344fa072890871bb';
  static const String _baseCurrency = 'SEK';  // Base currency is SEK
  static const String _prefsKey = 'exchange_rates';
  static const String _lastFetchDateKey = 'last_fetch_date';
  
  final Map<String, String> _currencySymbols = {
    'SEK': 'kr',
    'USD': '\$',
    'EUR': '€',
    'INR': '₹',
  };

  Map<String, double>? _exchangeRates;
  String _selectedCurrency = 'SEK';

  String get selectedCurrency => _selectedCurrency;
  String get currencySymbol => _currencySymbols[_selectedCurrency] ?? '';

  Future<void> initializeCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCurrency = prefs.getString('selected_currency') ?? 'SEK';
    await _loadExchangeRates();
  }

  Future<void> _loadExchangeRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchDate = prefs.getString(_lastFetchDateKey);
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Load cached rates first
      final cachedRates = prefs.getString(_prefsKey);
      if (cachedRates != null) {
        _exchangeRates = Map<String, double>.from(
          json.decode(cachedRates).map((key, value) => 
            MapEntry(key, double.parse(value.toString()))));
      }

      // Only fetch new rates if:
      // 1. No cached rates exist, or
      // 2. Last fetch was not today
      if (cachedRates == null || lastFetchDate != today) {
        print('Fetching new rates for $today (last fetch: $lastFetchDate)');
        await _fetchLatestRates();
      } else {
        print('Using cached rates from $lastFetchDate');
      }
    } catch (e) {
      print('Error loading exchange rates: $e');
      _useBackupRates();
    }
  }

  // Updated conversion rates with more precise values
  final Map<String, double> _conversionRates = {
    'SEK': 1.0,
    'USD': 0.095,  // Example: 1 SEK = 0.095 USD
    'EUR': 0.087,  // Example: 1 SEK = 0.087 EUR
    'INR': 7.89,   // Example: 1 SEK = 7.89 INR
  };

  Future<void> _fetchLatestRates() async {
    try {
      print('Making API call to fetch latest rates...');
      final response = await http.get(Uri.parse(
        '$_baseUrl?access_key=$_apiKey&currencies=EUR,USD,INR&source=SEK&format=1'
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final quotes = data['quotes'] as Map<String, dynamic>;
          
          // Calculate and store the conversion rates
          _exchangeRates = {
            'SEK': 1.0,
            'USD': 1.0 / (quotes['USDSEK']?.toDouble() ?? 10.5),
            'EUR': (quotes['USDEUR']?.toDouble() ?? 0.92) / (quotes['USDSEK']?.toDouble() ?? 10.5),
            'INR': (quotes['USDINR']?.toDouble() ?? 83.0) / (quotes['USDSEK']?.toDouble() ?? 10.5),
          };
          
          print('New rates fetched and cached: $_exchangeRates');
          
          // Cache the rates with today's date
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefsKey, json.encode(_exchangeRates));
          await prefs.setString(_lastFetchDateKey, 
            DateTime.now().toIso8601String().split('T')[0]);
        } else {
          print('API Error: ${data['error']?['info']}');
          _useBackupRates();
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        _useBackupRates();
      }
    } catch (e) {
      print('Error fetching rates: $e');
      _useBackupRates();
    }
  }

  void _useBackupRates() {
    // Backup rates if API fails
    _exchangeRates = {
      'SEK': 1.0,
      'USD': 0.095,  // 1 SEK ≈ 0.095 USD
      'EUR': 0.087,  // 1 SEK ≈ 0.087 EUR
      'INR': 7.89,   // 1 SEK ≈ 7.89 INR
    };
    print('Using backup exchange rates: $_exchangeRates');
  }

  Future<void> setSelectedCurrency(String currency) async {
    if (_selectedCurrency != currency) {
      _selectedCurrency = currency;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_currency', currency);
      
      // Don't fetch rates here, just notify of change
      notifyPriceChange();
    }
  }

  double convertPrice(double priceInSEK) {
    if (_selectedCurrency == _baseCurrency) {
      return priceInSEK;
    }
    
    final rate = _exchangeRates?[_selectedCurrency] ?? 1.0;
    final convertedPrice = priceInSEK * rate;
    
    print('Converting $priceInSEK SEK to $_selectedCurrency');
    print('Using rate: $rate');
    print('Result: $convertedPrice ${_currencySymbols[_selectedCurrency]}');
    
    return convertedPrice;
  }

  String formatPrice(double price) {
    // Format with proper currency symbols and positions
    switch (_selectedCurrency) {
      case 'SEK':
        return '${price.toStringAsFixed(2)} kr';
      case 'EUR':
        return '€${price.toStringAsFixed(2)}';
      case 'USD':
        return '\$${price.toStringAsFixed(2)}';
      case 'INR':
        return '₹${price.toStringAsFixed(2)}';
      default:
        return '${price.toStringAsFixed(2)} ${_currencySymbols[_selectedCurrency]}';
    }
  }

  String formatPriceWithCurrency(double price) {
    return '${formatPrice(price)} (${_selectedCurrency})';
  }

  // Only use this for manual refresh if needed
  Future<void> forceRefreshRates() async {
    print('Force refreshing rates (use sparingly)');
    await _fetchLatestRates();
  }

  // Add method to notify when currency changes
  void notifyPriceChange() {
    // This could be used to trigger UI updates when currency changes
    print('Currency changed to $_selectedCurrency');
  }

  // Add this method to manually refresh rates
  Future<void> refreshRates() async {
    print('Manually refreshing rates...');
    await _fetchLatestRates();
  }
} 