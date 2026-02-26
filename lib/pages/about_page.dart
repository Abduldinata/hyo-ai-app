import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/localization_service.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  static final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('about')),
        foregroundColor: colorScheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            t('credits'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          _linkItem(context, 'GitHub Copilot', 'https://github.com/features/copilot'),
          _linkItem(context, 'Google Gemini API', 'https://ai.google.dev'),
          _linkItem(context, 'Typecast TTS', 'https://typecast.ai'),
          _linkItem(context, 'VoiceVox TTS', 'https://voicevox.hiroshiba.jp'),
          const SizedBox(height: 24),
          Text(
            t('about_this_app'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t('about_description'),
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 16),
          FutureBuilder<PackageInfo>(
            future: _packageInfo,
            builder: (context, snapshot) {
              final info = snapshot.data;
              final version = info == null ? '-' : '${info.version}+${info.buildNumber}';
              return Text(
                '${t('version')} $version',
                style: const TextStyle(fontWeight: FontWeight.w600),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _linkItem(BuildContext context, String label, String url) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            // Fallback jika gagal buka browser eksternal
            try {
              await launchUrl(uri);
            } catch (_) {
              // Ignore jika tetap gagal
            }
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.star_rounded, color: colorScheme.secondary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              Icon(
                Icons.open_in_new,
                size: 16,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
