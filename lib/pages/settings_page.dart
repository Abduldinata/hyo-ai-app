import 'package:flutter/material.dart';

import '../data/memory_store.dart';
import '../localization/localization_service.dart';
import '../localization/localization_service.dart' show t;
import '../services/theme_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final MemoryStore _memoryStore = MemoryStore.instance;
  late ThemeService _themeService;
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
    _themeService = ThemeService();
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

  Future<void> _showInfoDialog({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t('ok')),
          ),
        ],
      ),
    );
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
                // Theme & Language Settings (2-Column Layout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme Section
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t('theme'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ),
                              Tooltip(
                                message: t('info'),
                                triggerMode: TooltipTriggerMode.longPress,
                                child: IconButton(
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.help_outline),
                                  onPressed: () {
                                    _showInfoDialog(
                                      title: t('theme_info_title'),
                                      message: t('theme_info_body'),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<AppThemeMode>(
                            value: _themeService.currentTheme,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: AppThemeMode.values
                                .map((mode) {
                                  final themeName = ThemeService.getTheme(mode).name;
                                  return DropdownMenuItem<AppThemeMode>(
                                    value: mode,
                                    child: Text(themeName),
                                  );
                                })
                                .toList(),
                            onChanged: (AppThemeMode? newValue) async {
                              if (newValue != null) {
                                await _themeService.setTheme(newValue);
                                // Rebuild app theme
                                if (mounted) {
                                  setState(() {});
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Language Section
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t('language'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ),
                              Tooltip(
                                message: t('info'),
                                triggerMode: TooltipTriggerMode.longPress,
                                child: IconButton(
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.help_outline),
                                  onPressed: () {
                                    _showInfoDialog(
                                      title: t('language_info_title'),
                                      message: t('language_info_body'),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _appLanguage,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'auto',
                                child: Text(t('auto')),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text(t('english')),
                              ),
                              DropdownMenuItem(
                                value: 'id',
                                child: Text(t('indonesian')),
                              ),
                            ],
                            onChanged: (String? value) async {
                              if (value == null) return;
                              setState(() => _appLanguage = value);
                              await LocalizationService.instance.setLanguage(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 24),
                // Auto Translate
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t('auto_translate'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Tooltip(
                      message: t('info'),
                      triggerMode: TooltipTriggerMode.longPress,
                      child: IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: () {
                          _showInfoDialog(
                            title: t('auto_translate_info_title'),
                            message: t('auto_translate_info_body'),
                          );
                        },
                      ),
                    ),
                  ],
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
                if (_autoTranslateEnabled) const SizedBox(height: 8),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t('tts_section_title'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Tooltip(
                      message: t('info'),
                      triggerMode: TooltipTriggerMode.longPress,
                      child: IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: () {
                          _showInfoDialog(
                            title: t('tts_section_info_title'),
                            message: t('tts_section_info_body'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t('tts_enabled')),
                  subtitle: Text(t('tts_disable_hint')),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t('tts_text_mode'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B6460),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: t('info'),
                      triggerMode: TooltipTriggerMode.longPress,
                      child: IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: () {
                          _showInfoDialog(
                            title: t('tts_mode_info_title'),
                            message: t('tts_mode_info_body'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _ttsTextMode,
                  decoration: InputDecoration(
                    labelText: t('select_mode'),
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
                      child: Text('🇯🇵 ${t('jp')} (${t('tts_mode_jp_hint')})'),
                    ),
                    DropdownMenuItem(
                      value: 'romaji',
                      child: Text('🔤 ${t('romaji')} (${t('tts_mode_romaji_hint')})'),
                    ),
                    DropdownMenuItem(
                      value: 'original',
                      child: Text('📝 ${t('original')} (${t('tts_mode_original_hint')})'),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t('voicevox_server_title'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Tooltip(
                      message: t('info'),
                      triggerMode: TooltipTriggerMode.longPress,
                      child: IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: () {
                          _showInfoDialog(
                            title: t('voicevox_info_title'),
                            message: t('voicevox_info_body'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _voicevoxUrlController,
                  decoration: InputDecoration(
                    labelText: t('voicevox_server_url'),
                    hintText: 'http://192.168.1.2:50021',
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
              ],
            ),
    );
  }
}
