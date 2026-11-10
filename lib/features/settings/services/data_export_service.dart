import 'dart:io';

import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataExportService {
  DataExportService({SupabaseClient? client}) : _client = client ?? supabase;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<void> exportAndShareCsv() async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');

    final transactions = await _client
        .from('transactions')
        .select('date, type, amount, description, accounts(name), categories(name)')
        .eq('user_id', userId)
        .order('date', ascending: false);

    final loans = await _client
        .from('loans')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final buffer = StringBuffer()
      ..writeln('Kharcha Data Export')
      ..writeln('Generated,${DateTime.now().toIso8601String()}')
      ..writeln()
      ..writeln('--- Transactions ---')
      ..writeln('date,type,amount,account,category,description');

    for (final row in transactions) {
      final account = row['accounts'];
      final category = row['categories'];
      final accountName = account is Map ? account['name'] : '';
      final categoryName = category is Map ? category['name'] : '';
      buffer.writeln(_csvRow([
        row['date'],
        row['type'],
        row['amount'],
        accountName,
        categoryName,
        row['description'],
      ]));
    }

    buffer
      ..writeln()
      ..writeln('--- Loans ---')
      ..writeln('person_name,type,amount,remaining_amount,status,due_date,description');

    for (final row in loans) {
      buffer.writeln(_csvRow([
        row['person_name'],
        row['type'],
        row['amount'],
        row['remaining_amount'],
        row['status'],
        row['due_date'],
        row['description'],
      ]));
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/kharcha_export_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Kharcha export',
      text: 'Your Kharcha transactions and loans',
    );
  }

  String _csvRow(List<Object?> values) {
    return values.map(_escape).join(',');
  }

  String _escape(Object? value) {
    final raw = (value ?? '').toString();
    if (raw.contains(',') || raw.contains('"') || raw.contains('\n')) {
      return '"${raw.replaceAll('"', '""')}"';
    }
    return raw;
  }
}
