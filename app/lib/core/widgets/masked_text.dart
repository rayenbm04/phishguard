import 'package:flutter/material.dart';

import 'package:phishguard/core/services/personal_data_masker.dart';
import 'package:phishguard/core/utils/formatters.dart';
import 'package:phishguard/core/utils/l10n.dart';

/// A masked message, with each hidden number shown as a small locked tag
/// ("phone hidden") instead of the raw [PHONE] marker.
/// Links are shown as plain text and are never tappable.
class MaskedText extends StatelessWidget {
  const MaskedText(this.text, {super.key, this.style, this.maxLines, this.overflow});

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  static final _tag = RegExp(r'\[(PHONE|CARD|ACCOUNT|CIN)\]');

  /// The text with tags replaced by words, for one-line previews.
  static String plain(BuildContext context, String text) =>
      text.replaceAllMapped(_tag, (m) => '‹${_label(context.l10n, m.group(0)!)}›');

  static String _label(AppLocalizations l, String tag) => switch (tag) {
        PersonalDataMasker.phoneTag => l.tagPhone,
        PersonalDataMasker.cardTag => l.tagCard,
        PersonalDataMasker.accountTag => l.tagAccount,
        _ => l.tagCin,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = style ?? theme.textTheme.bodyLarge;
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _tag.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      final label = _label(context.l10n, m.group(0)!);
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Semantics(
          label: label,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 12, color: scheme.onPrimaryContainer),
                const SizedBox(width: 3),
                Text(label,
                    style: theme.textTheme.labelSmall?.copyWith(color: scheme.onPrimaryContainer)),
              ],
            ),
          ),
        ),
      ));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(
      TextSpan(style: base, children: spans),
      textDirection: directionOf(text),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
