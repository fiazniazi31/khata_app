import 'package:flutter/material.dart';

class ExpenseConstants {
  static const List<String> categoriesList = [
    "Auto and Transport",
    "Health & Medication",
    "Domestic Expenses",
    "Bills & Utilities",
    "Food & Shopping",
    "Others",
  ];

  static IconData getIcon(String category) {
    final cat = category.toLowerCase().trim();
    if (cat.contains("auto") || cat.contains("transport") || cat.contains("transpoart")) {
      return Icons.directions_car_rounded;
    } else if (cat.contains("health") || cat.contains("medic") || cat.contains("medication")) {
      return Icons.medication_rounded;
    } else if (cat.contains("domast") || cat.contains("domest") || cat.contains("home")) {
      return Icons.home_rounded;
    } else if (cat.contains("bill") || cat.contains("utilit")) {
      return Icons.receipt_long_rounded;
    } else if (cat.contains("food") || cat.contains("shop") || cat.contains("shoop") || cat.contains("drink")) {
      return Icons.shopping_bag_rounded;
    } else {
      return Icons.widgets_outlined;
    }
  }

  static Color getColor(String category) {
    final cat = category.toLowerCase().trim();
    if (cat.contains("auto") || cat.contains("transport") || cat.contains("transpoart")) {
      return const Color(0xFF3B82F6); // Blue
    } else if (cat.contains("health") || cat.contains("medic") || cat.contains("medication")) {
      return const Color(0xFF8B5CF6); // Purple
    } else if (cat.contains("domast") || cat.contains("domest") || cat.contains("home")) {
      return const Color(0xFFF59E0B); // Amber
    } else if (cat.contains("bill") || cat.contains("utilit")) {
      return const Color(0xFF10B981); // Emerald
    } else if (cat.contains("food") || cat.contains("shop") || cat.contains("shoop") || cat.contains("drink")) {
      return const Color(0xFFEF4444); // Red
    } else {
      return const Color(0xFF64748B); // Slate
    }
  }
}

class IncomeConstants {
  static const List<String> categoriesList = [
    "Salary",
    "Business",
    "Freelance",
    "Investments",
    "Gifts",
    "Other",
  ];

  static IconData getIcon(String category) {
    switch (category) {
      case "Salary":
        return Icons.monetization_on_rounded;
      case "Business":
        return Icons.storefront_rounded;
      case "Freelance":
        return Icons.computer_rounded;
      case "Investments":
        return Icons.show_chart_rounded;
      case "Gifts":
        return Icons.card_giftcard_rounded;
      case "Other":
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  static Color getColor(String category) {
    switch (category) {
      case "Salary":
        return const Color(0xFF10B981); // Emerald
      case "Business":
        return const Color(0xFF3B82F6); // Blue
      case "Freelance":
        return const Color(0xFF8B5CF6); // Purple
      case "Investments":
        return const Color(0xFFF59E0B); // Amber
      case "Gifts":
        return const Color(0xFFEC4899); // Pink
      case "Other":
      default:
        return const Color(0xFF64748B); // Slate
    }
  }
}
