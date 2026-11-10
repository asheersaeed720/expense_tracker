class RoutePaths {
  RoutePaths._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';

  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String loans = '/loans';
  static const String settings = '/settings';
  static const String accounts = '/accounts';
  static const String categories = '/categories';

  static const String transactionForm = '/transaction/form';
  static const String transactionDetail = '/transaction';

  static String transactionDetailPath(String id) => '$transactionDetail/$id';

  static String transactionFormEditPath(String id) =>
      '$transactionForm?id=$id';
}
