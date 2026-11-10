import 'package:flutter/material.dart';

class IconNameMapper {
  IconNameMapper._();

  static IconData categoryIcon(String? name) {
    switch (name) {
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'receipt_long':
        return Icons.receipt_long_outlined;
      case 'local_hospital':
        return Icons.local_hospital_outlined;
      case 'movie':
        return Icons.movie_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'payments':
        return Icons.payments_outlined;
      case 'laptop':
        return Icons.laptop_outlined;
      case 'store':
        return Icons.store_outlined;
      case 'card_giftcard':
        return Icons.card_giftcard_outlined;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.category_outlined;
    }
  }

  static IconData accountTypeIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.payments_outlined;
      case 'bank':
        return Icons.account_balance_outlined;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.savings_outlined;
    }
  }
}
