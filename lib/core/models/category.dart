import 'package:expense_tracker/core/enums/category_type.dart';
import 'package:expense_tracker/core/constants/default_categories.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.userId,
  });

  final String id;
  final String name;
  final CategoryType type;
  final String? icon;
  final String? color;
  final String? userId;

  bool get isProtectedDefault =>
      userId != null && DefaultCategories.isProtectedName(name, type);

  factory Category.fromJson(Map<String, dynamic> json) {
    final typeRaw = json['type'] as String?;
    final type = typeRaw == 'income'
        ? CategoryType.income
        : CategoryType.expense;

    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      type: type,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      userId: json['user_id'] as String?,
    );
  }
}
