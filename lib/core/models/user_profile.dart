class UserProfile {
  const UserProfile({
    required this.id,
    this.fullName,
    this.currency = 'PKR',
    this.companyModeEnabled = false,
  });

  final String id;
  final String? fullName;
  final String currency;
  final bool companyModeEnabled;

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'there';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      currency: json['currency'] as String? ?? 'PKR',
      companyModeEnabled: json['company_mode_enabled'] as bool? ?? false,
    );
  }
}
