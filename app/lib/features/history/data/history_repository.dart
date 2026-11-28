import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:phishguard/core/models/models.dart';

/// One past check, kept only on the phone.
class HistoryEntry {
  const HistoryEntry({required this.maskedText, required this.verdict, this.sourceApp});

  /// The masked text (personal data already hidden).
  final String maskedText;
  final Verdict verdict;

  /// Android package of the app the message was shared from, if any.
  final String? sourceApp;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        maskedText: json['maskedText'] as String,
        verdict: Verdict.fromJson(json['verdict'] as Map<String, dynamic>),
        sourceApp: json['sourceApp'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'maskedText': maskedText,
        'verdict': verdict.toJson(),
        if (sourceApp != null) 'sourceApp': sourceApp,
      };
}

/// Local history of checks (newest first). Same key and format as v1.0.
class HistoryRepository {
  HistoryRepository(this._prefs, {this.maxEntries = 50});

  static const key = 'history.v1';
  final SharedPreferences _prefs;
  final int maxEntries;

  List<HistoryEntry> all() {
    final raw = _prefs.getStringList(key) ?? const [];
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
    final raw = _prefs.getStringList(key) ?? const <String>[];
    final updated = [jsonEncode(entry.toJson()), ...raw].take(maxEntries).toList();
    await _prefs.setStringList(key, updated);
  }

  Future<void> clear() => _prefs.remove(key);
}
