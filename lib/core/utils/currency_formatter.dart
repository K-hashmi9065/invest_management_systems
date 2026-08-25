import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    symbol: '₹',
    locale: 'en_IN',
    decimalDigits: 2,
  );

  /// Format minor units (paise) into INR currency string
  /// e.g. 10000000 paise -> ₹1,00,000.00
  static String formatPaise(int paise) {
    final double amount = paise / 100.0;
    return _formatter.format(amount);
  }

  /// Compact format for dashboard badges/cards
  /// e.g. 10000000 paise -> ₹1L or ₹1.00L
  static String formatPaiseCompact(int paise) {
    final double amount = paise / 100.0;
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return _formatter.format(amount);
  }

  /// Parse double/rupee input from text fields into integer paise
  /// e.g. 50000.50 -> 5000050
  static int rupeesToPaise(double rupees) {
    return (rupees * 100).round();
  }

  /// Convert paise back to rupees double for text form field pre-fills
  static double paiseToRupees(int paise) {
    return paise / 100.0;
  }
}
