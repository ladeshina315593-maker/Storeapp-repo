import 'package:shared_preferences/shared_preferences.dart';

class PikkXCurrency {
  static const Map<String, String> symbols = {
    'NGN': '₦',
    'USD': '\$',
    'GBP': '£',
    'EUR': '€',
    'CAD': 'CA\$',
    'AUD': 'A\$',
    'ZAR': 'R',
    'GHS': '₵',
    'KES': 'KSh',
    'INR': '₹',
  };

  static const Map<String, String> countryCurrencies = {
    'NG': 'NGN',
    'US': 'USD',
    'GB': 'GBP',
    'CA': 'CAD',
    'AU': 'AUD',
    'ZA': 'ZAR',
    'GH': 'GHS',
    'KE': 'KES',
    'IN': 'INR',
  };

  static String currencyForCountry(String countryCode) {
    return countryCurrencies[countryCode.toUpperCase()] ?? 'USD';
  }

  static String symbol(String currencyCode) {
    return symbols[currencyCode.toUpperCase()] ?? currencyCode;
  }

  static String format(double amount, String currencyCode) {
    return '${symbol(currencyCode)}${amount.toStringAsFixed(2)}';
  }

  static Future<String> loadSavedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_currency') ?? 'USD';
  }

  static Future<void> saveCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'selected_currency',
      currencyCode.toUpperCase(),
    );
  }
}
