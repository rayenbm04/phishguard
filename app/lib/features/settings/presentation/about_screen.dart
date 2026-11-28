import 'package:flutter/material.dart';

import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/services/api_client.dart';
import 'package:phishguard/core/utils/l10n.dart';
import 'package:phishguard/core/widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const team = [
    'BEN MIMOUN Rayen',
    'BEN TAMARZIZT Mahdi',
    'GARMA Nour El Houda',
    'TOUHAMI Ayoub',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Scaffold(
      appBar: AppBar(title: Text(l.aboutPhishGuard)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.md, AppSpace.page, AppSpace.xxl),
        children: [
          Row(
            children: [
              const BrandMark(size: 56),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PhishGuard', style: theme.textTheme.headlineSmall),
                    Text(l.versionLabel(ApiClient.appVersion), style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          Text(l.aboutBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpace.lg),
          Text(l.aboutRules, style: muted),
          SectionHeader(l.aboutTeam),
          Text(l.aboutSchool, style: muted),
          const SizedBox(height: AppSpace.sm),
          for (final name in team)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(name, style: theme.textTheme.bodyLarge),
            ),
          const SizedBox(height: AppSpace.sm),
          Text(l.aboutSupervisor('Dr. Maroua Nouioua'), style: muted),
          SectionHeader(l.aboutServer),
          SelectableText(ApiClient.defaultBaseUrl, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpace.xl),
          OutlinedButton.icon(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'PhishGuard',
              applicationVersion: ApiClient.appVersion,
            ),
            icon: const Icon(Icons.description_outlined),
            label: Text(l.licenses),
          ),
        ],
      ),
    );
  }
}
