import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// One past check, kept only on the phone.
class HistoryEntry {
  const HistoryEntry({required this.maskedText, required this.verdict});

  /// The masked text (personal data already hidden).
  final String maskedText;
  final Verdict verdict;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        maskedText: json['maskedText'] as String,
        verdict: Verdict.fromJson(json['verdict'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'maskedText': maskedText,
        'verdict': verdict.toJson(),
      };
}

/// Local history of checks (newest first), stored with shared_preferences.
class HistoryRepository {
  HistoryRepository({this.maxEntries = 50});

  static const _key = 'history.v1';
  final int maxEntries;

  Future<List<HistoryEntry>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    final entries = <HistoryEntry>[];
    for (final item in raw) {
      try {
        entries.add(HistoryEntry.fromJson(jsonDecode(item) as Map<String, dynamic>));
      } catch (_) {
        // Skip an entry written by an older version.
      }
    }
    return entries;
  }

  Future<void> save(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final updated = [jsonEncode(entry.toJson()), ...raw].take(maxEntries).toList();
    await prefs.setStringList(_key, updated);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
