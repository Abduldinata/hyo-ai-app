import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _appVersion = '2.1.0 (build 6)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        foregroundColor: const Color(0xFFF35D9C),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Credits',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF35D9C),
            ),
          ),
          const SizedBox(height: 12),
          _linkItem('GitHub Copilot', 'https://github.com/features/copilot'),
          _linkItem('Google Gemini API', 'https://ai.google.dev'),
          _linkItem('Typecast TTS', 'https://typecast.ai'),
          _linkItem('VoiceVox TTS', 'https://voicevox.hiroshiba.jp'),
          const SizedBox(height: 24),
          const Text(
            'About this app',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF35D9C),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hyo AI is a personal anime-style assistant with voice, designed to be your friendly companion.',
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Version $_appVersion',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _linkItem(String label, String url) {
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
              const Icon(Icons.star_rounded, color: Color(0xFFFFB7C5), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    color: Color(0xFF6B6460),
                  ),
                ),
              ),
              const Icon(Icons.open_in_new, size: 16, color: Color(0xFF6B6460)),
            ],
          ),
        ),
      ),
    );
  }
}
