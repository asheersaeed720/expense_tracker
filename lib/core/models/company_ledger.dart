class CompanyLedger {
  const CompanyLedger({
    required this.id,
    required this.userId,
    required this.companyName,
    required this.partnerName,
    required this.mySharePercent,
    required this.partnerSharePercent,
    required this.totalBalance,
    required this.myShareBalance,
    required this.partnerShareBalance,
    this.isActive = true,
  });

  final String id;
  final String userId;
  final String companyName;
  final String partnerName;
  final double mySharePercent;
  final double partnerSharePercent;
  final double totalBalance;
  final double myShareBalance;
  final double partnerShareBalance;
  final bool isActive;

  factory CompanyLedger.fromJson(Map<String, dynamic> json) {
    return CompanyLedger(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyName: json['company_name'] as String,
      partnerName: json['partner_name'] as String,
      mySharePercent: _toDouble(json['my_share_percent']),
      partnerSharePercent: _toDouble(json['partner_share_percent']),
      totalBalance: _toDouble(json['total_balance']),
      myShareBalance: _toDouble(json['my_share_balance']),
      partnerShareBalance: _toDouble(json['partner_share_balance']),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static double _toDouble(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
