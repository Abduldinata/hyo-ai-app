import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
            const SnackBar(content: Text('Tidak bisa membuka link.')),
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
    return InkWell(
      onTap: () => _openUrl(context, uri),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB7C5).withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFFB7C5).withOpacity(0.4),
              child: Icon(icon, color: const Color(0xFFF35D9C)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 18, color: Color(0xFFF35D9C)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact me'),
        foregroundColor: const Color(0xFFF35D9C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Created by: Abdul Aziz Dinata',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF35D9C),
              ),
            ),
            const SizedBox(height: 16),
            _linkTile(
              context: context,
              icon: Icons.camera_alt_outlined,
              label: 'Instagram',
              value: instagramUrl,
              uri: Uri.parse(instagramUrl),
            ),
            _linkTile(
              context: context,
              icon: Icons.music_note_outlined,
              label: 'TikTok',
              value: tiktokUrl,
              uri: Uri.parse(tiktokUrl),
            ),
            _linkTile(
              context: context,
              icon: Icons.alternate_email,
              label: 'Email',
              value: email,
              uri: Uri(scheme: 'mailto', path: email),
            ),
            _linkTile(
              context: context,
              icon: Icons.code,
              label: 'GitHub',
              value: githubUrl,
              uri: Uri.parse(githubUrl),
            ),
          ],
        ),
      ),
    );
  }
}
