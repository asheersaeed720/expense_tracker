import 'package:expense_tracker/core/enums/category_type.dart';

class DefaultCategories {
  DefaultCategories._();

  static const expenseNames = {
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Entertainment',
    'Education',
    'Other',
  };

  static const incomeNames = {
    'Salary',
    'Freelance',
    'Business',
    'Gift',
    'Other',
  };

  static bool isProtectedName(String name, CategoryType type) {
    if (type == CategoryType.expense) {
      return expenseNames.contains(name);
    }
    return incomeNames.contains(name);
  }

  static const selectableIcons = [
    ('restaurant', 'Food'),
    ('directions_car', 'Transport'),
    ('shopping_bag', 'Shopping'),
    ('receipt_long', 'Bills'),
    ('local_hospital', 'Health'),
    ('movie', 'Entertainment'),
    ('school', 'Education'),
    ('payments', 'Salary'),
    ('laptop', 'Freelance'),
    ('store', 'Business'),
    ('card_giftcard', 'Gift'),
    ('fitness_center', 'Fitness'),
    ('pets', 'Pets'),
    ('home', 'Home'),
    ('flight', 'Travel'),
    ('more_horiz', 'Other'),
  ];
}
