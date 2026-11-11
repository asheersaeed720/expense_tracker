import 'package:expense_tracker/config/constants/app_constants.dart';
import 'package:expense_tracker/config/router/route_paths.dart';
import 'package:expense_tracker/core/utils/app_haptics.dart';
import 'package:expense_tracker/core/utils/app_snackbar.dart';
import 'package:expense_tracker/features/accounts/providers/accounts_providers.dart';
import 'package:expense_tracker/features/company/providers/company_providers.dart';
import 'package:expense_tracker/features/company/widgets/company_setup_sheet.dart';
import 'package:expense_tracker/features/settings/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _appVersion;
  bool _companyBusy = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  Future<void> _editName() async {
    final profile = ref.read(profileProvider).valueOrNull;
    final controller = TextEditingController(text: profile?.fullName ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full name'),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    try {
      await ref.read(profileSettingsServiceProvider).updateFullName(controller.text);
      ref.invalidate(profileProvider);
      if (context.mounted) {
        showAppSnackBar(context, message: 'Name updated.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }

  Future<void> _changePassword() async {
    final newPass = TextEditingController();
    final confirm = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final bottom = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Change password', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: newPass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm password'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (newPass.text.length < 6) return;
                  if (newPass.text != confirm.text) return;
                  Navigator.pop(context, true);
                },
                child: const Text('Update password'),
              ),
            ],
          ),
        );
      },
    );

    if (saved != true || !mounted) return;
    if (newPass.text != confirm.text) {
      showAppSnackBar(context, message: 'Passwords do not match.', isError: true);
      return;
    }

    try {
      await ref.read(profileSettingsServiceProvider).updatePassword(newPass.text);
      if (context.mounted) {
        showAppSnackBar(context, message: 'Password updated.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }

  Future<void> _exportData() async {
    await AppHaptics.light();
    try {
      await ref.read(dataExportServiceProvider).exportAndShareCsv();
    } catch (e) {
      if (mounted) showAppSnackBar(context, message: e.toString(), isError: true);
    }
  }

  Future<bool> _tripleConfirmDelete() async {
    final steps = [
      (
        title: 'Delete all data?',
        body:
            'This removes transactions, loans, accounts, custom categories, and the company ledger.',
      ),
      (
        title: 'Are you absolutely sure?',
        body: 'Your profile and login stay intact, but financial records will be wiped.',
      ),
      (
        title: 'Final confirmation',
        body: 'Type DELETE in the next step to proceed.',
      ),
    ];

    for (final step in steps) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(step.title),
          content: Text(step.body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (ok != true) return false;
    }

    final typed = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm DELETE'),
        content: TextField(
          controller: typed,
          decoration: const InputDecoration(hintText: 'Type DELETE'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, typed.text.trim() == 'DELETE'),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<void> _reconcileBalances() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fix account balances?'),
        content: const Text(
          'Recalculates each account from its transactions.\n\n'
          'If a balance still looks wrong, edit transactions on that account '
          'and make sure each one uses the correct account, then run this again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recalculate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(accountsServiceProvider).reconcileBalancesFromTransactions();
      ref.invalidate(accountsProvider);
      if (context.mounted) {
        showAppSnackBar(context, message: 'Account balances updated.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }

  Future<void> _deleteAllData() async {
    if (!await _tripleConfirmDelete() || !mounted) return;

    try {
      await ref.read(dataPrivacyServiceProvider).deleteAllUserData();
      ref.invalidate(accountsProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(companyLedgerProvider);
      if (context.mounted) {
        showAppSnackBar(context, message: 'All data deleted. Defaults restored.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }

  Future<void> _setCompanyMode(bool enabled) async {
    if (_companyBusy) return;
    setState(() => _companyBusy = true);
    try {
      final service = ref.read(companyServiceProvider);
      if (enabled) {
        final ledger = await service.fetchLedger();
        if (!mounted) return;
        if (ledger == null) {
          final result = await showCompanySetupSheet(context);
          if (result == null || !mounted) return;
          await service.createLedger(
            companyName: result.companyName,
            partnerName: result.partnerName,
            mySharePercent: result.mySharePercent,
          );
          if (mounted) {
            showAppSnackBar(context, message: 'Company workspace is on.');
          }
        } else {
          await service.setCompanyMode(true);
        }
      } else {
        await service.setCompanyMode(false);
        if (mounted) {
          showAppSnackBar(
            context,
            message: 'Company workspace hidden. Your company data is still saved.',
          );
        }
      }
      ref.invalidate(profileProvider);
      ref.invalidate(companyLedgerProvider);
    } catch (e) {
      if (mounted) showAppSnackBar(context, message: e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _companyBusy = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await AppHaptics.medium();
    await ref.read(profileSettingsServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final auth = ref.watch(profileSettingsServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Profile', style: Theme.of(context).textTheme.titleSmall),
          ),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(profile?.displayName ?? 'User'),
            subtitle: Text(auth?.email ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editName,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePassword,
          ),
          const Divider(height: 1),
          _NavTile(
            icon: Icons.category_outlined,
            title: 'Categories',
            subtitle: 'Expense and income labels',
            onTap: () => context.push(RoutePaths.categories),
          ),
          _NavTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Accounts',
            subtitle: 'Balances and transfers',
            onTap: () => context.push(RoutePaths.accounts),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Workspace', style: Theme.of(context).textTheme.titleSmall),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.business_outlined),
            title: const Text('Company / Partner Ledger'),
            subtitle: const Text(
              'Track shared business income, expenses & partner splits separately',
            ),
            value: profile?.companyModeEnabled ?? false,
            onChanged: profile == null || _companyBusy ? null : _setCompanyMode,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Data & privacy', style: Theme.of(context).textTheme.titleSmall),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export CSV'),
            subtitle: const Text('Transactions, loans, and company ledger if you have one'),
            onTap: _exportData,
          ),
          ListTile(
            leading: const Icon(Icons.sync_outlined),
            title: const Text('Fix account balances'),
            subtitle: const Text('Recalculate from your transactions'),
            onTap: _reconcileBalances,
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
            title: Text('Delete all data', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            subtitle: const Text('Triple confirmation required'),
            onTap: _deleteAllData,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('About', style: Theme.of(context).textTheme.titleSmall),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppConstants.appName),
            subtitle: Text(
              'Version ${_appVersion ?? '…'}',
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
    );
  }
}
