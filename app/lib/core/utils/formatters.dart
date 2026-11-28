import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:phishguard/core/utils/l10n.dart';

/// A readable name for the Android package a message was shared from.
String sourceAppName(String? package) {
  if (package == null || package.isEmpty) return '';
  const known = {
    'com.whatsapp': 'WhatsApp',
    'com.whatsapp.w4b': 'WhatsApp Business',
    'com.google.android.apps.messaging': 'Messages',
    'com.samsung.android.messaging': 'Messages',
    'com.android.mms': 'SMS',
    'com.google.android.gm': 'Gmail',
    'com.microsoft.office.outlook': 'Outlook',
    'com.facebook.orca': 'Messenger',
    'com.facebook.katana': 'Facebook',
    'com.instagram.android': 'Instagram',
    'org.telegram.messenger': 'Telegram',
    'com.viber.voip': 'Viber',
    'org.thoughtcrime.securesms': 'Signal',
    'com.android.chrome': 'Chrome',
  };
  final name = known[package];
  if (name != null) return name;
  final last = package.split('.').last;
  return last.isEmpty ? package : '${last[0].toUpperCase()}${last.substring(1)}';
}

String _locale(BuildContext context) => Localizations.localeOf(context).toLanguageTag();

/// Tunisia writes Arabic with Latin digits (0-9), like the scores in the app.
String _latinDigits(String s) => s.replaceAllMapped(
      RegExp('[\u0660-\u0669]'),
      (m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) - 0x0660 + 0x30),
    );

/// Direction of a message from its first letter: Arabic reads right to left,
/// Latin left to right, whatever the interface language.
TextDirection? directionOf(String text) {
  for (final rune in text.runes) {
    if (rune >= 0x0600 && rune <= 0x06FF) return TextDirection.rtl;
    if ((rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A) || (rune >= 0xC0 && rune <= 0x24F)) {
      return TextDirection.ltr;
    }
  }
  return null;
}

/// "14:05"
String formatTime(BuildContext context, DateTime date) =>
    _latinDigits(DateFormat.Hm(_locale(context)).format(date.toLocal()));

/// "22 Nov 2026"
String formatDate(BuildContext context, DateTime date) =>
    _latinDigits(DateFormat.yMMMd(_locale(context)).format(date.toLocal()));

/// "Today", "Yesterday" or the date, for history groups.
String formatDay(BuildContext context, DateTime date, {DateTime? now}) {
  final local = date.toLocal();
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final day = DateUtils.dateOnly(local);
  final diff = today.difference(day).inDays;
  if (diff == 0) return context.l10n.today;
  if (diff == 1) return context.l10n.yesterday;
  return _latinDigits(DateFormat.yMMMMd(_locale(context)).format(local));
}

/// "Today, 14:05" or "22 Nov 2026, 14:05".
String formatMoment(BuildContext context, DateTime date) =>
    context.l10n.dateAtTime(formatDay(context, date), formatTime(context, date));
