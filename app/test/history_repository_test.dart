import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phishguard/models/models.dart';
import 'package:phishguard/services/history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final verdict = Verdict.fromJson(
    jsonDecode(File('../contracts/verdict.example.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saves newest first and keeps at most maxEntries', () async {
    final repo = HistoryRepository(maxEntries: 2);
    for (final text in ['first', 'second', 'third']) {
      await repo.save(HistoryEntry(maskedText: text, verdict: verdict));
    }
    final all = await repo.all();
    expect(all.map((e) => e.maskedText), ['third', 'second']);
    expect(all.first.verdict.level, verdict.level);
  });

  test('clear empties the history', () async {
    final repo = HistoryRepository();
    await repo.save(HistoryEntry(maskedText: 'x', verdict: verdict));
    await repo.clear();
    expect(await repo.all(), isEmpty);
  });
}
