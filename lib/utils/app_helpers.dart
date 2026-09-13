import 'package:intl/intl.dart';

class AppConstants {
  static const String appName = 'Kuri App';
}

class AppHelpers {
  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatAmount(double amount) {
    return '₹${NumberFormat('#,##,###').format(amount)}';
  }

  static String monthLabel(DateTime startDate, int monthNumber) {
    final date = DateTime(
      startDate.year,
      startDate.month + monthNumber - 1,
    );
    return DateFormat('MMM yyyy').format(date);
  }

  static List<String> generateSearchKeywords(
      String fullName, String memberNumber, String shopMemberId) {
    final keywords = <String>{};
    final name = fullName.toLowerCase();
    final words = name.split(' ');

    for (final word in words) {
      for (int i = 1; i <= word.length; i++) {
        keywords.add(word.substring(0, i));
      }
    }

    final mNum = memberNumber.toLowerCase();
    for (int i = 1; i <= mNum.length; i++) {
      keywords.add(mNum.substring(0, i));
    }

    final fullId = shopMemberId.toLowerCase();
    for (int i = 1; i <= fullId.length; i++) {
      keywords.add(fullId.substring(0, i));
    }

    return keywords.toList();
  }

  static String generateMemberNumber(int count) {
    return 'M${count.toString().padLeft(3, '0')}';
  }

  static bool isPaymentPendingWarning() {
    return DateTime.now().day > 20;
  }
}
