import 'package:flutter/material.dart';

import '../data/memory_store.dart';

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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Auto Translate',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktifkan auto translate'),
                  subtitle: const Text('Teks balasan akan diterjemahkan otomatis.'),
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
                      labelText: 'Bahasa output',
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
                    items: const [
                      DropdownMenuItem(
                        value: 'id',
                        child: Text('Indonesia'),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('English'),
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
                const SizedBox(height: 24),
                const Text(
                  'Text-to-Speech',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _ttsTextMode,
                  decoration: InputDecoration(
                    labelText: 'TTS text mode (VoiceVox)',
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
                  items: const [
                    DropdownMenuItem(
                      value: 'jp',
                      child: Text('Japanese (auto translate)'),
                    ),
                    DropdownMenuItem(
                      value: 'romaji',
                      child: Text('Romaji (experimental)'),
                    ),
                    DropdownMenuItem(
                      value: 'original',
                      child: Text('Original text'),
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
                const Text(
                  'Catatan: Mode TTS (Typecast/System/VoiceVox) tetap bisa dipilih di chat.',
                  style: TextStyle(color: Color(0xFF6B6460)),
                ),
              ],
            ),
    );
  }
}
