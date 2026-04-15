import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class Formatters {
  /// Format amount as currency (₹)
  static String formatCurrency(double amount) {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }

  /// Format amount without currency symbol
  static String formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  /// Format date
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  /// Format date and time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  /// Format time only
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Format relative time (e.g., "2 hours ago", "yesterday")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDate(dateTime);
    }
  }

  /// Format balance with color indicator
  static String formatBalance(double balance) {
    if (balance > 0) {
      return '+$currencySymbol${balance.toStringAsFixed(2)}';
    } else if (balance < 0) {
      return '-$currencySymbol${(-balance).toStringAsFixed(2)}';
    } else {
      return '$currencySymbol${balance.toStringAsFixed(2)}';
    }
  }

  /// Get balance status (what user owes or is owed)
  static String getBalanceStatus(double balance) {
    if (balance > 0) {
      return 'Owed to you';
    } else if (balance < 0) {
      return 'You owe';
    } else {
      return 'Settled';
    }
  }
}
