import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/localization_service.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({
    super.key,
    required this.githubUrl,
    required this.instagramUrl,
    required this.tiktokUrl,
    required this.email,
  });

  final String githubUrl;
  final String instagramUrl;
  final String tiktokUrl;
  final String email;

  Future<void> _openUrl(BuildContext context, Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback tanpa mode
      try {
        await launchUrl(uri);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('cannot_open_link'))),
          );
        }
      }
    }
  }

  Widget _linkTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Uri uri,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _openUrl(context, uri),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.secondary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.secondary.withOpacity(0.35),
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 18, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('contact_me')),
        foregroundColor: colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('created_by'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _linkTile(
              context: context,
              icon: Icons.camera_alt_outlined,
              label: t('instagram'),
              value: instagramUrl,
              uri: Uri.parse(instagramUrl),
            ),
            _linkTile(
              context: context,
              icon: Icons.music_note_outlined,
              label: t('tiktok'),
              value: tiktokUrl,
              uri: Uri.parse(tiktokUrl),
            ),
            _linkTile(
              context: context,
              icon: Icons.alternate_email,
              label: t('email'),
              value: email,
              uri: Uri(scheme: 'mailto', path: email),
            ),
            _linkTile(
              context: context,
              icon: Icons.code,
              label: t('github'),
              value: githubUrl,
              uri: Uri.parse(githubUrl),
            ),
          ],
        ),
      ),
    );
  }
}
