class UserProfile {
  const UserProfile({
    required this.id,
    this.fullName,
    this.currency = 'PKR',
  });

  final String id;
  final String? fullName;
  final String currency;

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
    );
  }
}
