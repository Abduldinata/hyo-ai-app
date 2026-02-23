import 'package:flutter/material.dart';

import '../data/memory_store.dart';
import '../localization/localization_service.dart';
import '../localization/localization_service.dart' show t;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final MemoryStore _memoryStore = MemoryStore.instance;
  bool _autoTranslateEnabled = false;
  String _autoTranslateTarget = 'id';
  bool _ttsEnabled = true;
  String _ttsTextMode = 'jp';
  String _appLanguage = 'auto'; // 'auto', 'en', 'id'
  bool _loading = true;
  final TextEditingController _voicevoxUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _voicevoxUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await _memoryStore.getPreferences();
    if (!mounted) {
      return;
    }
    setState(() {
      _autoTranslateEnabled = prefs['auto_translate'] == '1';
      _autoTranslateTarget = prefs['auto_translate_target'] == 'en' ? 'en' : 'id';
      _ttsEnabled = prefs['tts_enabled'] != '0';
      final ttsTextMode = prefs['tts_text_mode'];
      if (ttsTextMode == 'jp' || ttsTextMode == 'romaji' || ttsTextMode == 'original') {
        _ttsTextMode = ttsTextMode ?? 'jp';
      }
      _voicevoxUrlController.text = prefs['voicevox_server_url'] ?? '';
      _appLanguage = LocalizationService.instance.currentLanguage;
      _loading = false;
    });
  }

  Future<void> _updatePreference(String key, String value) async {
    await _memoryStore.upsertPreference(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('settings')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Language Settings
                Text(
                  t('language'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  t('language_selected'),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 12),
                // Auto
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t('auto')),
                  value: 'auto',
                  groupValue: _appLanguage,
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() => _appLanguage = value);
                    await LocalizationService.instance.setLanguage(value);
                  },
                ),
                // English
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t('english')),
                  value: 'en',
                  groupValue: _appLanguage,
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() => _appLanguage = value);
                    await LocalizationService.instance.setLanguage(value);
                  },
                ),
                // Indonesian
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t('indonesian')),
                  value: 'id',
                  groupValue: _appLanguage,
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() => _appLanguage = value);
                    await LocalizationService.instance.setLanguage(value);
                  },
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 24),
                // Auto Translate
                Text(
                  t('auto_translate'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t('auto_translate')),
                  subtitle: Text(t('auto_translate_desc')),
                  value: _autoTranslateEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _autoTranslateEnabled = value;
                    });
                    await _updatePreference(
                      'auto_translate',
                      value ? '1' : '0',
                    );
                  },
                ),
                const SizedBox(height: 8),
                if (_autoTranslateEnabled)
                  DropdownButtonFormField<String>(
                    value: _autoTranslateTarget,
                    decoration: InputDecoration(
                      labelText: t('auto_translate'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'id',
                        child: Text('🇮🇩 ${t('indonesian')}'),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('🇬🇧 ${t('english')}'),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _autoTranslateTarget = value;
                      });
                      await _updatePreference('auto_translate_target', value);
                    },
                  ),
                if (_autoTranslateEnabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '📝 Auto Translate: Jawaban Hyo akan diterjemahkan ke bahasa pilihan sebelum disuarakan. Berguna jika Hyo menjawab dalam bahasa lain.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF6B6460)),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Text-to-Speech (TTS)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('TTS aktif'),
                  subtitle: const Text('Matikan jika tidak ingin suara.'),
                  value: _ttsEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _ttsEnabled = value;
                    });
                    await _updatePreference(
                      'tts_enabled',
                      value ? '1' : '0',
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  t('tts_text_mode'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B6460)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _ttsTextMode,
                  decoration: InputDecoration(
                    labelText: 'Pilih mode',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'jp',
                      child: Text('🇯🇵 ${t('jp')} (Auto Translate ke Jepang)'),
                    ),
                    DropdownMenuItem(
                      value: 'romaji',
                      child: Text('🔤 ${t('romaji')} (Konversi ke huruf Latin)'),
                    ),
                    DropdownMenuItem(
                      value: 'original',
                      child: Text('📝 ${t('original')} (Tetap original)'),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _ttsTextMode = value;
                    });
                    await _updatePreference('tts_text_mode', value);
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '📖 Penjelasan Mode Text:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B6460)),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '🇯🇵 Japanese: Teks diterjemahkan ke Bahasa Jepang, lebih natural untuk voice Jepang (butuh internet, lebih lambat)\n\n🔤 Romaji: Teks dikonversi ke huruf Latin (a, e, i, o, u). Eksperimental, kadang tidak akurat.\n\n📝 Original: Gunakan teks asli (Indonesia/English). Cocok untuk testing, tapi mungkin pronunciation kurang natural.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B6460), height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '💡 Catatan: Mode TTS (Typecast/System/VoiceVox) bisa diubah di chat. Jika VoiceVox error/timeout, app otomatis pakai System TTS (Google).',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B6460), fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 24),
                Text(
                  'VoiceVox Server',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _voicevoxUrlController,
                  decoration: InputDecoration(
                    labelText: t('voicevox_server_url'),
                    hintText: 'http://192.168.1.2:50021',
                    helperText: 'Kosongkan untuk gunakan default dari .env',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) async {
                    await _updatePreference('voicevox_server_url', value.trim());
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Isi URL server VoiceVox di sini jika IP PC berubah. Restart app setelah mengubah.',
                  style: TextStyle(color: Color(0xFF6B6460)),
                ),
              ],
            ),
    );
  }
}
