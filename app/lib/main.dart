import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phishguard/app/app.dart';
import 'package:phishguard/core/providers.dart';

export 'package:phishguard/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const PhishGuardApp(),
  ));
}

/// The bundled fonts are under the SIL Open Font License.
void _registerFontLicenses() {
  const fonts = {
    'Readex Pro': 'assets/fonts/OFL-readexpro.txt',
    'IBM Plex Sans': 'assets/fonts/OFL-ibmplexsans.txt',
    'Noto Sans Arabic': 'assets/fonts/OFL-notosansarabic.txt',
  };
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: path) in fonts.entries) {
      yield LicenseEntryWithLineBreaks([name], await rootBundle.loadString(path));
    }
  });
}
