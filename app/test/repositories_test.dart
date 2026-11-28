import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/core/services/link_opener.dart';
import 'package:phishguard/features/history/data/history_repository.dart';
import 'package:phishguard/features/settings/data/settings_repository.dart';

import 'helpers.dart';

void main() {
  final verdict = exampleVerdict();

  group('HistoryRepository', () {
    test('saves newest first and keeps at most maxEntries', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = HistoryRepository(await SharedPreferences.getInstance(), maxEntries: 2);
      for (final text in ['first', 'second', 'third']) {
        await repo.save(HistoryEntry(maskedText: text, verdict: verdict));
      }
      final all = repo.all();
      expect(all.map((e) => e.maskedText), ['third', 'second']);
      expect(all.first.verdict.level, verdict.level);
    });

    test('reads entries written by v1.0 (same key, no sourceApp)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await HistoryRepository(prefs).save(HistoryEntry(maskedText: 'x', verdict: verdict));
      expect(prefs.getStringList('history.v1'), hasLength(1));
      expect(prefs.getStringList('history.v1')!.single, isNot(contains('sourceApp')));
      expect(HistoryRepository(prefs).all().single.sourceApp, isNull);
    });

    test('clear empties the history', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = HistoryRepository(await SharedPreferences.getInstance());
      await repo.save(HistoryEntry(maskedText: 'x', verdict: verdict));
      await repo.clear();
      expect(repo.all(), isEmpty);
    });
  });

  group('SettingsRepository', () {
    test('keeps the v1.0 consent and language', () async {
      SharedPreferences.setMockInitialValues(setupDone);
      final settings = SettingsRepository(await SharedPreferences.getInstance()).load();
      expect(settings.setupDone, isTrue);
      expect(settings.language, Language.english);
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.textScale, 1.0);
      expect(settings.easyRead, isFalse);
    });

    test('saves theme, text size and easy-read', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      await repo.saveThemeMode(ThemeMode.dark);
      await repo.saveTextScale(1.2);
      await repo.saveEasyRead(true);
      final settings = repo.load();
      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.textScale, 1.2);
      expect(settings.easyRead, isTrue);
      expect(settings.effectiveTextScale, closeTo(1.38, 0.001));
    });
  });

  test('LinkOpener only opens websites and phone numbers', () {
    expect(LinkOpener.uriOf('https://www.ancs.tn')!.toString(), 'https://www.ancs.tn');
    expect(LinkOpener.uriOf('www.poste.tn')!.toString(), 'https://www.poste.tn');
    expect(LinkOpener.uriOf('71 846 000')!.scheme, 'tel');
    expect(LinkOpener.uriOf('Call your bank'), isNull);
  });
}
