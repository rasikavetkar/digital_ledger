import 'package:intl/intl.dart';

class Formatters {
  // Format amount in Indian format: ₹1,23,456
  static String formatAmount(double amount) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return '₹${formatter.format(amount)}';
  }

  // Format date as "15 Jun 24"
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yy').format(date);
  }

  // Format date time as "15 Jun 24, 10:30 AM"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yy, hh:mm a').format(dateTime);
  }

  // Parse date from string
  static DateTime? parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Get day name from DateTime
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  // Get relative date: "Today", "Yesterday", or "15 Jun 24"
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return formatDate(date);
    }
  }

  // Format vehicle number to uppercase
  static String formatVehicleNumber(String number) {
    return number.toUpperCase();
  }
}
