import 'package:expense_tracker/features/settings/services/data_export_service.dart';
import 'package:expense_tracker/features/settings/services/data_privacy_service.dart';
import 'package:expense_tracker/features/settings/services/profile_settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileSettingsServiceProvider = Provider<ProfileSettingsService>((ref) {
  return ProfileSettingsService();
});

final dataExportServiceProvider = Provider<DataExportService>((ref) {
  return DataExportService();
});

final dataPrivacyServiceProvider = Provider<DataPrivacyService>((ref) {
  return DataPrivacyService();
});
