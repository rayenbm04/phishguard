import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:phishguard/app/app.dart';
import 'package:phishguard/app/router.dart';
import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/core/utils/l10n.dart';
import 'package:phishguard/core/widgets/common.dart';
import 'package:phishguard/features/history/presentation/history_controller.dart';
import 'package:phishguard/features/history/presentation/history_screen.dart';
import 'package:phishguard/features/onboarding/presentation/privacy_screen.dart';
import 'package:phishguard/features/settings/domain/app_settings.dart';
import 'package:phishguard/features/settings/presentation/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final language = ref.watch(effectiveLanguageProvider);
    final controller = ref.read(settingsProvider.notifier);
    final historyCount = ref.watch(historyProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.xxl),
        children: [
          SectionHeader(l.languageLabel, padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.sm)),
          _Group(
            child: RadioGroup<Language>(
              groupValue: language,
              onChanged: (value) {
                if (value != null) controller.setLanguage(value);
              },
              child: Column(
                children: [
                  for (final (i, option) in supportedLanguages.indexed) ...[
                    if (i > 0) const Divider(indent: AppSpace.lg, endIndent: AppSpace.lg),
                    RadioListTile<Language>(
                      key: Key('settings-language-${option.code}'),
                      value: option,
                      title: Text(languageName(option)),
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SectionHeader(l.appearance),
          _Group(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.theme, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpace.sm),
                  SegmentedButton<ThemeMode>(
                    key: const Key('themeSelector'),
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.brightness_auto_outlined),
                        label: Text(l.themeSystem),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode_outlined),
                        label: Text(l.themeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode_outlined),
                        label: Text(l.themeDark),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) => controller.setThemeMode(s.first),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Row(
                    children: [
                      Expanded(child: Text(l.textSize, style: theme.textTheme.titleMedium)),
                      Text('${(settings.textScale * 100).round()} %',
                          style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
                    ],
                  ),
                  Row(
                    children: [
                      Text('A', style: theme.textTheme.bodySmall),
                      Expanded(
                        child: Slider(
                          key: const Key('textSizeSlider'),
                          value: settings.textScale,
                          min: AppSettings.minTextScale,
                          max: AppSettings.maxTextScale,
                          divisions: 5,
                          semanticFormatterCallback: (v) => '${(v * 100).round()} %',
                          onChanged: controller.setTextScale,
                        ),
                      ),
                      Text('A', style: theme.textTheme.titleLarge),
                    ],
                  ),
                  Text(l.textSizePreview, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          _Group(
            child: SwitchListTile(
              key: const Key('easyReadSwitch'),
              value: settings.easyRead,
              onChanged: controller.setEasyRead,
              secondary: const Icon(Icons.chrome_reader_mode_outlined),
              title: Text(l.easyRead),
              subtitle: Text(l.easyReadBody),
            ),
          ),
          SectionHeader(l.privacy),
          _Group(
            child: Column(
              children: [
                ListTile(
                  key: const Key('privacyInfo'),
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l.privacyInfo),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showPrivacy(context),
                ),
                const Divider(indent: AppSpace.lg, endIndent: AppSpace.lg),
                ListTile(
                  key: const Key('settingsClearHistory'),
                  enabled: historyCount > 0,
                  leading: Icon(Icons.delete_outline_rounded,
                      color: historyCount > 0 ? scheme.error : null),
                  title: Text(l.clearHistory,
                      style: historyCount > 0 ? TextStyle(color: scheme.error) : null),
                  subtitle: Text(l.historyCount(historyCount)),
                  onTap: () => confirmClearHistory(context, ref),
                ),
              ],
            ),
          ),
          SectionHeader(l.about),
          _Group(
            child: ListTile(
              key: const Key('aboutTile'),
              leading: const BrandMark(size: 28),
              title: Text(l.aboutPhishGuard),
              subtitle: Text(l.versionLabel('1.0.0')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.about),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.privacyTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpace.sm),
              Text(l.privacyIntro, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpace.xl),
              for (final (icon, title, body) in privacyPromises(l))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: theme.colorScheme.primary),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: theme.textTheme.titleMedium),
                            Text(body, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              InfoLine(icon: Icons.info_outline_rounded, text: l.privacyServerNote),
            ],
          ),
        );
      },
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(child: child);
}
