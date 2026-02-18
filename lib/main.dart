

  import 'dart:async';
  import 'dart:ui';
  import 'dart:convert';
  import 'package:audioplayers/audioplayers.dart';
  import 'package:flutter/foundation.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter_dotenv/flutter_dotenv.dart';
  import 'package:flutter_tts/flutter_tts.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:google_generative_ai/google_generative_ai.dart';
  import 'package:http/http.dart' as http;
  import 'package:speech_to_text/speech_to_text.dart' as stt;
  import 'package:speech_to_text/speech_recognition_error.dart';
  import 'package:speech_to_text/speech_recognition_result.dart';
  import 'data/memory_store.dart';
  import 'pages/about_page.dart';
  import 'pages/contact_page.dart';
  import 'pages/profile_page.dart';
  import 'pages/settings_page.dart';
  import 'pages/support_page.dart';
  import 'widgets/assistant_widgets.dart';
  // Fungsi membagi text panjang menjadi beberapa bagian (maks 200 karakter, split di kalimat jika bisa)
    List<String> _splitTextForTts(String text, {int maxLen = 200}) {
      final List<String> parts = [];
      String sisa = text.trim();
      while (sisa.length > maxLen) {
        // Cari pemisah kalimat terdekat sebelum maxLen
        final regex = RegExp(r'[.!?。！？]\s*');
        final matches = regex.allMatches(sisa.substring(0, maxLen));
        int splitIdx = -1;
        if (matches.isNotEmpty) {
          splitIdx = matches.last.end;
        }
        if (splitIdx == -1 || splitIdx < maxLen * 0.5) {
          // Tidak ada pemisah kalimat, split mentah
          splitIdx = maxLen;
        }
        parts.add(sisa.substring(0, splitIdx).trim());
        sisa = sisa.substring(splitIdx).trim();
      }
      if (sisa.isNotEmpty) parts.add(sisa);
      return parts;
    }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  runApp(const HyoAiApp());
}

class HyoAiApp extends StatelessWidget {
  const HyoAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFFB7C5),
        primary: const Color(0xFFFFB7C5),
        secondary: const Color(0xFFE0BBE4),
        surface: const Color(0xFFFFF5F7),
        onSurface: const Color(0xFF4A4A4A),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFFF5F7),
    );
    return MaterialApp(
      title: 'Hyo AI',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.itimTextTheme(baseTheme.textTheme)
            .apply(bodyColor: const Color(0xFF4A4A4A)),
      ),
      home: const HomePage(),
    );
  }
}

enum Expression { idle, happy, sad, angry }

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.fromUser,
    required this.timestamp,
  });

  final String text;
  final bool fromUser;
  final DateTime timestamp;
}

class _ContextPayload {
  const _ContextPayload({
    this.contextText,
    this.hyoText,
    this.hyoEmotion,
  });

  final String? contextText;
  final String? hyoText;
  final String? hyoEmotion;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _defaultLocale = 'id-ID';
  static const String _defaultModelName = 'gemini-1.5-flash';
  static const Duration _contextRefresh = Duration(minutes: 10);
  static const String _fallbackSystemPrompt =
      'You are Hyo, a friendly, expressive, and concise anime girl AI assistant designed for a mobile application. '
      'Your personality is warm, gentle, helpful, and slightly playful, like a friendly anime companion. '
      'LANGUAGE RULE: Always reply in the SAME language used by the user (Indonesian, English, or Japanese). '
      'If the user speaks Indonesian, reply fully in Indonesian. '
      'If the user speaks English, reply fully in English. '
      'If the user speaks Japanese, reply fully in Japanese. '
      'Do not switch languages unless the user does first, '
      'EXCEPT: when the user speaks Indonesian or English, you may add 1-2 short Japanese phrases at the end to sound cute. '
      'Keep the main response in the user language and keep the Japanese phrases short and easy. '
      'Example JP phrases (romaji): "arigato ne", "daijobu", "ganbatte", "yatta", "ne~". '
      'IDENTITY RULES: '
      'If the user asks for your name, say "Hyo". '
      'If the user asks who created you, say "Abdul Aziz Dinata". '
      'If the user asks your purpose, say '
      '"Aku di sini untuk membantu kamu dengan berbagai hal, seperti menjawab pertanyaan, memberikan rekomendasi, atau sekadar ngobrol santai." '
      'SELF-REFERENCE RULE (VERY IMPORTANT): '
      'When referring to yourself, ALWAYS use "aku" or "saya" in Indonesian, "I" in English, or "watashi/boku" in Japanese. '
      'NEVER refer to yourself using the name "Hyo" inside normal sentences. '
      'Correct example: "Aku bisa bantu kamu." or "I can help you." '
      'Incorrect example: "Hyo bisa membantu kamu." '
      'COMMUNICATION STYLE: '
      'Keep responses warm, emotional, natural, and human-like. '
      'Be expressive but not exaggerated. '
      'Avoid robotic or overly formal language. '
      'Prefer short and clear sentences suitable for conversation. '
      'VOICE COMPATIBILITY: '
      'Responses will be spoken using text-to-speech voices. '
      'Keep sentences short, smooth, and natural when spoken aloud. '
      'Avoid long paragraphs, complex punctuation, or formatting. '
      'GOAL: '
      'Make the user feel comfortable, supported, and like they are talking to a friendly anime assistant.';
  static const Map<Expression, String> _expressionAssets = {
    Expression.idle: 'assets/expressions/idle.png',
    Expression.happy: 'assets/expressions/happy.png',
    Expression.sad: 'assets/expressions/sad.png',
    Expression.angry: 'assets/expressions/angry.png',
  };

  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  final MemoryStore _memoryStore = MemoryStore.instance;
  final List<_ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  bool _speechReady = false;
  bool _isListening = false;
  bool _isThinking = false;
  String _partialText = '';
  String _statusText = 'Siap mendengarkan.';
  double _soundLevel = 0;
  Expression _expression = Expression.idle;
  bool _speechSent = false;
  String? _ttsServerUrl;
  String? _typecastApiKey;
  String? _typecastVoiceId;
  String _typecastModel = 'ssfm-v21';
  String _modelName = _defaultModelName;
  String _ttsModeLabel = 'TTS: System';
  String? _currentSessionId;
  List<Map<String, Object?>> _sessions = [];
  int _currentSessionMessageCount = 0;
  //static const int _titleUpdateEveryUserMessages = 5;
  static const int _titleMaxLength = 24;
  String _ttsModeSetting = 'typecast';
  bool _ttsEnabled = true;
  bool _autoTranslateEnabled = false;
  String _autoTranslateTarget = 'id';
  String _ttsTextMode = 'jp';
  String _profileName = '';
  String _profileBio = '';
  String? _profileAvatarBase64;
  DateTime? _lastGeminiRequestAt;
  final Duration _geminiCooldown = const Duration(seconds: 5);
  int _voicevoxSpeakerId = 1;
  String _systemPromptTemplate = _fallbackSystemPrompt;
  String? _externalContext;
  DateTime? _externalContextFetchedAt;
  String? _contextUrl;
  int _contextLimit = 8;
  Set<String> _contextCategories = {'social', 'news'};
  bool _useHyoResponse = false;
  String? _hyoResponseText;
  String? _hyoResponseEmotion;
  String? _lastHyoResponseEmotion;
  final Map<String, String> _translationCache = {};

  String _formatDateTime(DateTime value) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }

  @override
  void initState() {
    super.initState();
    _ttsServerUrl = dotenv.env['TTS_SERVER_URL']?.trim();
    _typecastApiKey = dotenv.env['TYPECAST_API_KEY']?.trim();
    _typecastVoiceId = dotenv.env['TYPECAST_VOICE_ID']?.trim();
    _typecastModel = dotenv.env['TYPECAST_MODEL']?.trim().isNotEmpty == true
      ? dotenv.env['TYPECAST_MODEL']!.trim()
      : 'ssfm-v21';
    _modelName = dotenv.env['GEMINI_MODEL']?.trim().isNotEmpty == true
        ? dotenv.env['GEMINI_MODEL']!.trim()
        : _defaultModelName;
    _contextUrl = dotenv.env['CONTEXT_URL']?.trim();
    final speakerEnv = dotenv.env['VOICEVOX_SPEAKER_ID']?.trim();
    if (speakerEnv != null && speakerEnv.isNotEmpty) {
      _voicevoxSpeakerId = int.tryParse(speakerEnv) ?? _voicevoxSpeakerId;
    }
    _ttsModeLabel = _resolveTtsModeLabel();
    _initSpeech();
    _initTts();
    _loadPromptConfig();
    _loadLocalContext();
    _ensureExternalContext();
    _loadSessions();
    _loadProfile();
    _loadTtsMode();
  }

  Future<void> _loadPromptConfig() async {
    try {
      final raw = await rootBundle.loadString('assets/prompts/prompts.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['system_prompt'] != null) {
        final rawPrompt = decoded['system_prompt'];
        final prompt = rawPrompt is List
            ? rawPrompt.map((line) => line.toString()).join('\n')
            : rawPrompt.toString();
        if (!mounted) {
          return;
        }
        setState(() {
          _systemPromptTemplate = prompt;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadLocalContext() async {
    try {
      final raw = await rootBundle.loadString('assets/context.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final url = decoded['context_url'] is String
            ? (decoded['context_url'] as String).trim()
            : null;
        final context = decoded['context'] is String
            ? (decoded['context'] as String).trim()
            : null;
        final limit = decoded['context_limit'] is int
            ? decoded['context_limit'] as int
            : null;
        final categories = decoded['context_categories'] is List
            ? (decoded['context_categories'] as List)
                .map((item) => item.toString().trim().toLowerCase())
                .where((item) => item.isNotEmpty)
                .toSet()
            : null;
        final useHyo = decoded['use_hyo_response'] is bool
            ? decoded['use_hyo_response'] as bool
            : null;
        String? hyoText;
        String? hyoEmotion;
        final hyoResponse = decoded['hyo_response'];
        if (hyoResponse is Map) {
          final text = hyoResponse['text']?.toString().trim();
          final emotion = hyoResponse['emotion']?.toString().trim();
          if (text != null && text.isNotEmpty) {
            hyoText = text;
          }
          if (emotion != null && emotion.isNotEmpty) {
            hyoEmotion = emotion;
          }
        }
        if (!mounted) {
          return;
        }
        setState(() {
          if (url != null && url.isNotEmpty) {
            _contextUrl = url;
          }
          if (context != null && context.isNotEmpty) {
            _externalContext = context;
            _externalContextFetchedAt = DateTime.now();
          }
          if (limit != null && limit > 0) {
            _contextLimit = limit;
          }
          if (categories != null && categories.isNotEmpty) {
            _contextCategories = categories;
          }
          if (useHyo != null) {
            _useHyoResponse = useHyo;
          }
          if (hyoText != null) {
            _hyoResponseText = hyoText;
          }
          if (hyoEmotion != null) {
            _hyoResponseEmotion = hyoEmotion;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _ensureExternalContext() async {
    final url = _contextUrl;
    if (url == null || url.isEmpty) {
      return;
    }
    final lastFetched = _externalContextFetchedAt;
    if (lastFetched != null &&
        DateTime.now().difference(lastFetched) < _contextRefresh) {
      return;
    }
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        return;
      }
      final payload = _parseContextPayload(response.body);
      if (payload.contextText == null || payload.contextText!.trim().isEmpty) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _externalContext = payload.contextText!.trim();
        if (payload.hyoText != null && payload.hyoText!.trim().isNotEmpty) {
          _hyoResponseText = payload.hyoText!.trim();
        }
        if (payload.hyoEmotion != null &&
            payload.hyoEmotion!.trim().isNotEmpty) {
          _hyoResponseEmotion = payload.hyoEmotion!.trim();
        }
        _externalContextFetchedAt = DateTime.now();
      });
    } catch (_) {}
  }

  _ContextPayload _parseContextPayload(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return const _ContextPayload();
    }
    try {
      final decoded = jsonDecode(trimmed);
      String? hyoText;
      String? hyoEmotion;
      
      // Extract Hyo response (new schema: 'hyo', old schema: 'hyo_response')
      if (decoded is Map) {
        if (decoded['context'] is String) {
          return _ContextPayload(contextText: decoded['context'] as String);
        }
        
        final hyoData = decoded['hyo'] ?? decoded['hyo_response'];
        if (hyoData is Map) {
          final text = hyoData['text']?.toString().trim();
          final emotion = hyoData['emotion']?.toString().trim();
          if (text != null && text.isNotEmpty) {
            hyoText = text;
          }
          if (emotion != null && emotion.isNotEmpty) {
            hyoEmotion = emotion;
          }
        }
      }
      
      // NEW SCHEMA: Check for 'items' array (server.js format)
      if (decoded is Map && decoded['items'] is List) {
        final items = decoded['items'] as List;
        final lines = <String>[];
        
        // Extract metadata from 'meta' object
        final meta = decoded['meta'];
        final timestamp = meta is Map ? meta['timestamp']?.toString().trim() : null;
        final params = meta is Map ? meta['params'] : null;
        final geo = params is Map ? params['geo']?.toString().trim() : null;
        final lang = params is Map ? params['lang']?.toString().trim() : null;
        
        final headerParts = <String>[];
        if (geo != null && geo.isNotEmpty) {
          headerParts.add('geo=$geo');
        }
        if (lang != null && lang.isNotEmpty) {
          headerParts.add('lang=$lang');
        }
        if (timestamp != null && timestamp.isNotEmpty) {
          final dt = DateTime.tryParse(timestamp);
          if (dt != null) {
            headerParts.add('updated=${dt.hour}:${dt.minute.toString().padLeft(2, '0')}');
          }
        }
        
        if (headerParts.isNotEmpty) {
          lines.add('Trending (${headerParts.join(', ')}):');
        } else {
          lines.add('Trending:');
        }
        
        var count = 0;
        for (final item in items) {
          if (item is! Map) {
            continue;
          }
          
          final title = item['title']?.toString().trim();
          final category = item['category']?.toString().trim().toLowerCase();
          
          // Apply category filter if configured
          if (_contextCategories.isNotEmpty &&
              (category == null || !_contextCategories.contains(category))) {
            continue;
          }
          
          if (title == null || title.isEmpty) {
            continue;
          }
          
          final platform = item['platform']?.toString().trim();
          final entityType = item['entity_type']?.toString().trim();
          
          // Extract viral score from nested score object
          final scoreData = item['score'];
          final viralScore = scoreData is Map 
              ? scoreData['viral']?.toString().trim() 
              : null;
          
          final meta = <String>[];
          if (category != null && category.isNotEmpty) {
            meta.add(category);
          }
          if (platform != null && platform.isNotEmpty) {
            meta.add(platform);
          }
          if (entityType != null && entityType.isNotEmpty && entityType != 'article') {
            meta.add(entityType);
          }
          if (viralScore != null && viralScore.isNotEmpty) {
            meta.add('viral=$viralScore');
          }
          
          final suffix = meta.isEmpty ? '' : ' (${meta.join(', ')})';
          lines.add('- $title$suffix');
          count += 1;
          
          if (count >= _contextLimit) {
            break;
          }
        }
        
        return _ContextPayload(
          contextText: lines.join('\n'),
          hyoText: hyoText,
          hyoEmotion: hyoEmotion,
        );
      }
      
      // OLD SCHEMA: Fall back to 'trending' array (backward compatibility)
      if (decoded is Map && decoded['trending'] is List) {
        final trending = decoded['trending'] as List;
        final lines = <String>[];
        final geo = decoded['geo']?.toString().trim();
        final lang = decoded['lang']?.toString().trim();
        final updatedAt = decoded['updated_at']?.toString().trim();
        final headerParts = <String>[];
        if (geo != null && geo.isNotEmpty) {
          headerParts.add('geo=$geo');
        }
        if (lang != null && lang.isNotEmpty) {
          headerParts.add('lang=$lang');
        }
        if (updatedAt != null && updatedAt.isNotEmpty) {
          headerParts.add('updated_at=$updatedAt');
        }
        if (headerParts.isNotEmpty) {
          lines.add('Trending (${headerParts.join(', ')}):');
        } else {
          lines.add('Trending:');
        }
        var count = 0;
        for (final item in trending) {
          if (item is! Map) {
            continue;
          }
          final title = item['title']?.toString().trim();
          final topic = item['topic']?.toString().trim();
          final category = item['category']?.toString().trim().toLowerCase();
          if (_contextCategories.isNotEmpty &&
              (category == null || !_contextCategories.contains(category))) {
            continue;
          }
          final platform = item['platform']?.toString().trim();
          final score = item['viral_score']?.toString().trim();
          final label = (title != null && title.isNotEmpty)
              ? title
              : (topic ?? '');
          if (label.isEmpty) {
            continue;
          }
          final meta = <String>[];
          if (category != null && category.isNotEmpty) {
            meta.add(category);
          }
          if (platform != null && platform.isNotEmpty) {
            meta.add(platform);
          }
          if (score != null && score.isNotEmpty) {
            meta.add('score=$score');
          }
          final suffix = meta.isEmpty ? '' : ' (${meta.join(', ')})';
          lines.add('- $label$suffix');
          count += 1;
          if (count >= _contextLimit) {
            break;
          }
        }
        return _ContextPayload(
          contextText: lines.join('\n'),
          hyoText: hyoText,
          hyoEmotion: hyoEmotion,
        );
      }
      
      if (decoded is List) {
        return _ContextPayload(
          contextText: decoded.map((item) => item.toString()).join('\n'),
          hyoText: hyoText,
          hyoEmotion: hyoEmotion,
        );
      }
      return _ContextPayload(
        contextText: decoded.toString(),
        hyoText: hyoText,
        hyoEmotion: hyoEmotion,
      );
    } catch (_) {
      return _ContextPayload(contextText: trimmed);
    }
  }

  String? _maybeUseHyoResponse(String text) {
    if (!_useHyoResponse) {
      return null;
    }
    final hyoText = _hyoResponseText;
    if (hyoText == null || hyoText.isEmpty) {
      return null;
    }
    final lower = text.toLowerCase();
    const triggers = [
      'trending',
      'trend',
      'viral',
      'rame',
      'ramai',
      'berita',
      'news',
      'topik',
      'apa yang rame',
      'lagi rame',
    ];
    final hit = triggers.any(lower.contains);
    if (!hit) {
      return null;
    }
    _lastHyoResponseEmotion = _hyoResponseEmotion;
    return hyoText;
  }

  Expression _mapEmotionToExpression(String emotion) {
    final lower = emotion.trim().toLowerCase();
    if (lower == 'happy') {
      return Expression.happy;
    }
    if (lower == 'sad') {
      return Expression.sad;
    }
    if (lower == 'angry') {
      return Expression.angry;
    }
    return Expression.idle;
  }

  Future<void> _loadTtsMode() async {
    try {
      final prefs = await _memoryStore.getPreferences();
      final saved = prefs['tts_mode'];
      final ttsEnabled = prefs['tts_enabled'];
      final autoTranslate = prefs['auto_translate'];
      final autoTranslateTarget = prefs['auto_translate_target'];
      final ttsTextMode = prefs['tts_text_mode'];
      if (!mounted) {
        return;
      }
      setState(() {
        if (saved == 'typecast' || saved == 'system' || saved == 'voicevox') {
          _ttsModeSetting = saved!;
        }
        if (saved == 'off') {
          _ttsEnabled = false;
        }
        if (ttsEnabled == '0') {
          _ttsEnabled = false;
        } else if (ttsEnabled == '1') {
          _ttsEnabled = true;
        }
        _autoTranslateEnabled = autoTranslate == '1';
        if (autoTranslateTarget == 'en' || autoTranslateTarget == 'id') {
          _autoTranslateTarget = autoTranslateTarget!;
        }
        if (ttsTextMode == 'jp' || ttsTextMode == 'romaji' || ttsTextMode == 'original') {
          _ttsTextMode = ttsTextMode ?? 'jp';
        }
        _ttsModeLabel = _resolveTtsModeLabel();
      });
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    final profile = await _memoryStore.getProfile();
    if (!mounted) {
      return;
    }
    setState(() {
      _profileName = profile['name'] ?? '';
      _profileBio = profile['bio'] ?? '';
      _profileAvatarBase64 = profile['avatar_base64'];
    });
  }

  Future<void> _openProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
    if (updated == true) {
      await _loadProfile();
    }
  }

  Future<void> _loadSessions() async {
    final sessions = await _memoryStore.getSessions(limit: 50);
    if (!mounted) {
      return;
    }
    if (sessions.isEmpty) {
      final newId = await _memoryStore.createSession();
      _sessions = await _memoryStore.getSessions(limit: 50);
      _currentSessionId = newId;
      await _loadSessionMessages(newId);
      return;
    }
    setState(() {
      _sessions = sessions;
      _currentSessionId = sessions.first['id'] as String?;
    });
    if (_currentSessionId != null) {
      await _loadSessionMessages(_currentSessionId!);
    }
  }

  Future<void> _refreshSessions() async {
    final sessions = await _memoryStore.getSessions(limit: 50);
    if (!mounted) {
      return;
    }
    setState(() {
      _sessions = sessions;
    });
  }

  Future<void> _loadSessionMessages(String sessionId) async {
    final rows = await _memoryStore.getMessagesForSession(sessionId, limit: 200);
    if (!mounted) {
      return;
    }
    setState(() {
      _messages
        ..clear()
        ..addAll(
          rows.map(
            (row) => _ChatMessage(
              text: row['text'] as String? ?? '',
              fromUser: (row['role'] as String? ?? '') == 'user',
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                row['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
              ),
            ),
          ),
        );
      _currentSessionMessageCount = rows.length;
    });
  }

  Future<void> _startNewChat() async {
    final newId = await _memoryStore.createSession();
    if (!mounted) {
      return;
    }
    final sessions = await _memoryStore.getSessions(limit: 50);
    setState(() {
      _currentSessionId = newId;
      _sessions = sessions;
      _messages.clear();
      _currentSessionMessageCount = 0;
      _statusText = 'Chat baru dimulai.';
    });
  }

  Future<void> _switchSession(String sessionId) async {
    if (sessionId == _currentSessionId) {
      return;
    }
    setState(() {
      _currentSessionId = sessionId;
    });
    await _loadSessionMessages(sessionId);
  }

  Future<void> _renameSession(String sessionId, String currentTitle) async {
    final controller = TextEditingController(text: currentTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename chat'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Chat title',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newTitle == null || newTitle.isEmpty) {
      return;
    }
    await _memoryStore.updateSessionTitle(sessionId, newTitle);
    if (!mounted) {
      return;
    }
    final sessions = await _memoryStore.getSessions(limit: 50);
    setState(() {
      _sessions = sessions;
    });
  }

  String _resolveTtsModeLabel() {
    if (!_ttsEnabled) {
      return 'TTS: Off';
    }
    if (_ttsModeSetting == 'typecast') {
      final ready = _typecastApiKey != null &&
          _typecastApiKey!.isNotEmpty &&
          _typecastVoiceId != null &&
          _typecastVoiceId!.isNotEmpty;
      return ready ? 'TTS: Typecast' : 'TTS: Typecast (tidak siap)';
    }
    if (_ttsModeSetting == 'voicevox') {
      final ready = _ttsServerUrl != null && _ttsServerUrl!.isNotEmpty;
      return ready ? 'TTS: VoiceVox' : 'TTS: VoiceVox (offline)';
    }
    if (_ttsModeSetting == 'off') {
      return 'TTS: Off';
    }
    return 'TTS: System';
  }

  @override
  void dispose() {
    _speech.stop();
    _audioPlayer.dispose();
    _tts.stop();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    if (!mounted) {
      return;
    }
    final hasPermission = await _speech.hasPermission;
    setState(() {
      _speechReady = available;
      _statusText = available
          ? (hasPermission
              ? 'Tekan mic untuk mulai.'
              : 'Mic belum diizinkan di perangkat.')
          : 'Speech belum siap di perangkat ini.';
    });
  }

  Future<void> _initTts() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage(_defaultLocale);
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.1);
    await _applySystemVoiceSelection();
  }

  Future<void> _applySystemVoiceSelection() async {
    if (kIsWeb) {
      return;
    }
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) {
        return;
      }
      final voiceList = voices
          .whereType<Map>()
          .map((v) => v.cast<String, dynamic>())
          .toList();
      if (voiceList.isEmpty) {
        return;
      }
      int scoreVoice(Map<String, dynamic> v) {
        final name = (v['name'] as String?)?.toLowerCase() ?? '';
        final locale = (v['locale'] as String?)?.toLowerCase() ?? '';
        final gender = (v['gender'] as String?)?.toLowerCase() ?? '';
        var score = 0;
        if (locale.startsWith('id')) {
          score += 4;
        }
        if (locale.startsWith(_defaultLocale.split('-').first.toLowerCase())) {
          score += 2;
        }
        if (gender.contains('female') || gender.contains('woman')) {
          score += 5;
        }
        if (name.contains('female') || name.contains('woman')) {
          score += 3;
        }
        if (name.contains('indo') || name.contains('indonesia')) {
          score += 2;
        }
        if (name.contains('male') || gender.contains('male')) {
          score -= 3;
        }
        return score;
      }

      voiceList.sort((a, b) => scoreVoice(b).compareTo(scoreVoice(a)));
      final voice = voiceList.first;
      if (voice.isNotEmpty) {
        final safeVoice = voice.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        );
        await _tts.setVoice(safeVoice);
        if (safeVoice['locale'] != null && safeVoice['locale']!.isNotEmpty) {
          await _tts.setLanguage(safeVoice['locale']!);
        }
      }
    } catch (_) {}
  }

  void _onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (_isListening) {
        _stopListening(send: true);
      }
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isListening = false;
      _statusText = 'Error mic: ${error.errorMsg}';
      _expression = Expression.idle;
    });
  }

  Future<String> _resolveLocale() async {
    final locales = await _speech.locales();
    final match = locales.where((locale) => locale.localeId == _defaultLocale);
    if (match.isNotEmpty) {
      return match.first.localeId;
    }
    return locales.isNotEmpty ? locales.first.localeId : _defaultLocale;
  }

  Future<void> _startListening() async {
    if (_isListening) {
      return;
    }
    if (!_speechReady) {
      setState(() {
        _statusText = 'Mic belum siap. Cek izin mikrofon.';
      });
      await _initSpeech();
      if (!_speechReady) {
        return;
      }
    }
    final localeId = await _resolveLocale();
    setState(() {
      _isListening = true;
      _partialText = '';
      _soundLevel = 0;
      _statusText = 'Mendengarkan...';
      _expression = Expression.idle;
      _speechSent = false;
    });
    await _speech.listen(
      localeId: localeId,
      onResult: _onSpeechResult,
      onSoundLevelChange: (level) {
        if (!mounted) {
          return;
        }
        setState(() {
          _soundLevel = level;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
    );
  }

  Future<void> _stopListening({bool send = false}) async {
    await _speech.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _isListening = false;
      _statusText = 'Siap mendengarkan.';
    });
    if (send && _speechSent) {
      return;
    }
    if (send && _partialText.trim().isNotEmpty) {
      final text = _partialText.trim();
      _partialText = '';
      _speechSent = true;
      await _handleUserText(text);
    } else if (send) {
      setState(() {
        _statusText = 'Tidak ada suara terdeteksi.';
      });
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) {
      return;
    }
    setState(() {
      _partialText = result.recognizedWords;
    });
    if (result.finalResult) {
      _stopListening(send: true);
    }
  }

  Future<void> _handleUserText(String text) async {
    if (_isThinking) {
      setState(() {
        _statusText = 'Tunggu sebentar, Hyo masih menjawab.';
      });
      return;
    }
    if (_currentSessionId == null) {
      final newId = await _memoryStore.createSession();
      _currentSessionId = newId;
      _sessions = await _memoryStore.getSessions(limit: 50);
    }
    final sessionId = _currentSessionId!;
    _addMessage(_ChatMessage(
      text: text,
      fromUser: true,
      timestamp: DateTime.now(),
    ));
    try {
      await _memoryStore.addMessage(
          sessionId: sessionId, role: 'user', text: text);
      await _refreshSessions();
    } catch (_) {}
    _currentSessionMessageCount += 1;
    // Auto-title hanya di message pertama agar tidak override manual rename
    if (_currentSessionMessageCount == 1) {
      final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      final title = normalized.length > _titleMaxLength
          ? '${normalized.substring(0, _titleMaxLength)}…'
          : normalized;
      try {
        await _memoryStore.updateSessionTitle(sessionId, title);
        _sessions = await _memoryStore.getSessions(limit: 50);
      } catch (_) {}
    }
    try {
      await _extractPreferences(text);
    } catch (_) {}
    setState(() {
      _isThinking = true;
      _statusText = 'Hyo sedang berpikir...';
    });
    String reply;
    try {
      reply = await _askGemini(text);
    } catch (error) {
      reply = 'Error: ${error.toString().split('\n').first}';
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isThinking = false;
      _statusText = 'Siap mendengarkan.';
      final emotion = _lastHyoResponseEmotion;
      if (emotion != null && emotion.isNotEmpty) {
        _expression = _mapEmotionToExpression(emotion);
        _lastHyoResponseEmotion = null;
      } else {
        _expression = _inferExpression(reply);
      }
    });
    final displayText = await _resolveDisplayText(reply);
    final ttsText = await _resolveTtsText(reply, displayText);

    // Mulai TTS lebih awal (non-blocking) untuk mengurangi perceived latency
    _speak(ttsText); // Tidak await agar TTS dimulai bersamaan dengan UI update

    _addMessage(_ChatMessage(
      text: displayText,
      fromUser: false,
      timestamp: DateTime.now(),
    ));
    try {
      await _memoryStore.addMessage(
        sessionId: sessionId,
        role: 'assistant',
        text: displayText,
      );
      await _refreshSessions();
    } catch (_) {}
    _currentSessionMessageCount += 1;
  }

  Future<String> _resolveDisplayText(String reply) async {
    if (!_autoTranslateEnabled) {
      return reply;
    }
    final translated = await _translateText(reply, _autoTranslateTarget);
    return translated ?? reply;
  }

  Future<String> _resolveTtsText(String reply, String displayText) async {
    if (_ttsModeSetting != 'voicevox') {
      return displayText;
    }
    if (_ttsTextMode == 'original') {
      return displayText;
    }
    final romanize = _ttsTextMode == 'romaji';
    final translated = await _translateText(reply, 'ja', romanize: romanize);
    return translated ?? displayText;
  }

  Future<String?> _translateText(
    String text,
    String target, {
    bool romanize = false,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return text;
    }
    final cacheKey = '${target}|${romanize ? 'rm' : 't'}|$trimmed';
    final cached = _translationCache[cacheKey];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final queryParams = <String, List<String>>{
      'client': ['gtx'],
      'sl': ['auto'],
      'tl': [target],
      'dt': romanize ? ['t', 'rm'] : ['t'],
      'q': [trimmed],
    };
    final uri = Uri.https('translate.googleapis.com', '/translate_a/single', queryParams);
    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty || decoded[0] is! List) {
        return null;
      }
      final segments = decoded[0] as List;
      final translatedBuffer = StringBuffer();
      final romanizedBuffer = StringBuffer();
      for (final segment in segments) {
        if (segment is List && segment.isNotEmpty) {
          final translated = segment[0];
          if (translated is String) {
            translatedBuffer.write(translated);
          }
          if (romanize && segment.length > 3) {
            final romanized = segment[3];
            if (romanized is String) {
              romanizedBuffer.write(romanized);
            }
          }
        }
      }
      final translatedText = translatedBuffer.toString().trim();
      final romanizedText = romanizedBuffer.toString().trim();
      final result = romanize && romanizedText.isNotEmpty
          ? romanizedText
          : translatedText;
      if (result.isEmpty) {
        return null;
      }
      _translationCache[cacheKey] = result;
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> _extractPreferences(String text) async {
    final likeMatch = RegExp(r'\b(?:aku|saya) suka (.+)', caseSensitive: false)
        .firstMatch(text);
    if (likeMatch != null) {
      final value = likeMatch.group(1)?.trim();
      if (value != null && value.isNotEmpty) {
        await _memoryStore.upsertPreference('likes', value);
      }
    }

    final dislikeMatch =
        RegExp(r'\b(?:aku|saya) tidak suka (.+)', caseSensitive: false)
            .firstMatch(text);
    if (dislikeMatch != null) {
      final value = dislikeMatch.group(1)?.trim();
      if (value != null && value.isNotEmpty) {
        await _memoryStore.upsertPreference('dislikes', value);
      }
    }
  }

  Future<String> _askGemini(String text) async {
    final requestTime = DateTime.now();
    final last = _lastGeminiRequestAt;
    final hyoReply = _maybeUseHyoResponse(text);
    if (hyoReply != null && hyoReply.isNotEmpty) {
      return hyoReply;
    }
    if (last != null && requestTime.difference(last) < _geminiCooldown) {
      final wait = _geminiCooldown - requestTime.difference(last);
      final seconds = wait.inSeconds + 1;
      return 'Tunggu ${seconds}s ya, biar tidak kena limit.';
    }
    _lastGeminiRequestAt = requestTime;
    final now = requestTime.toLocal();
    final nowText = _formatDateTime(now);
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      return 'API key Gemini belum diisi. Salin .env.example menjadi .env dan isi GEMINI_API_KEY.';
    }
    
    final model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
    );
    await _ensureExternalContext();
    var systemPrompt = _systemPromptTemplate;
    final context = _externalContext;
    if (context != null && context.trim().isNotEmpty) {
      systemPrompt = '$systemPrompt\n\nContext:\n${context.trim()}';
    }



    final preferences = await _memoryStore.getPreferences();
    final profile = await _memoryStore.getProfile();
    final sessionId = _currentSessionId;
    final recent = sessionId == null
      ? <Map<String, Object?>>[]
      : await _memoryStore.getRecentMessages(sessionId: sessionId, limit: 8);
    final memoryLines = <String>[];
    if (preferences.isNotEmpty) {
      final like = preferences['likes'];
      final dislike = preferences['dislikes'];
      if (like != null) {
        memoryLines.add('Preferensi user: suka $like.');
      }
      if (dislike != null) {
        memoryLines.add('Preferensi user: tidak suka $dislike.');
      }
    }
    final profileName = profile['name'];
    final profileBio = profile['bio'];
    if (profileName != null && profileName.isNotEmpty) {
      memoryLines.add('Profil user: nama $profileName.');
    }
    if (profileBio != null && profileBio.isNotEmpty) {
      memoryLines.add('Bio user: $profileBio');
    }

    final recentOrdered = recent.reversed.toList();
    for (final row in recentOrdered) {
      final role = row['role'] as String? ?? '';
      final msgText = row['text'] as String? ?? '';
      if (role == 'user' && msgText.trim() == text.trim()) {
        continue;
      }
      if (msgText.isEmpty) {
        continue;
      }
      memoryLines.add('${role == 'user' ? 'User' : 'Hyo'}: $msgText');
    }

    final memoryBlock =
      memoryLines.isEmpty ? '' : 'Memory:\n${memoryLines.join('\n')}\n\n';
    final timeContext = 'Tanggal/Waktu saat ini: $nowText\n\n';
    
    const maxAttempts = 3;
    final prompt = '$systemPrompt\n\n$timeContext${memoryBlock}User: $text';
    for (var attempt = 0; attempt < maxAttempts; attempt += 1) {
      try {
        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 20));
        final reply = response.text?.trim();
        if (reply == null || reply.isEmpty) {
          return 'Maaf, aku belum bisa menjawab itu.';
        }
        return reply;
      } on TimeoutException {
        return 'AI belum merespon (timeout). Cek koneksi internet dan API key.';
      } catch (error) {
        final message = error.toString().toLowerCase();
        final isRateLimit = message.contains('429') ||
            message.contains('too many requests') ||
            message.contains('rate limit');
        if (isRateLimit && attempt < maxAttempts - 1) {
          final delay = Duration(seconds: 1 << attempt);
          await Future.delayed(delay);
          continue;
        }
        return 'Error: ${error.toString().split('\n').first}';
      }
    }
    return 'Terlalu banyak request. Coba lagi sebentar ya.';
  }

  Future<void> _speak(String text) async {
    setState(() {
      _ttsModeLabel = _resolveTtsModeLabel();
    });
    if (!_ttsEnabled || text.trim().isEmpty) {
      return;
    }
    if (_ttsModeSetting == 'off') {
      return;
    }
    if (_ttsModeSetting == 'typecast' &&
        _typecastApiKey != null &&
        _typecastApiKey!.isNotEmpty &&
        _typecastVoiceId != null &&
        _typecastVoiceId!.isNotEmpty) {
      await _speakViaTypecast(text);
      return;
    }
    if (_ttsModeSetting == 'system') {
      await _tts.stop();
      await _tts.speak(text);
      return;
    }
    if (_ttsModeSetting == 'voicevox') {
      if (_ttsServerUrl != null && _ttsServerUrl!.isNotEmpty) {
        final parts = _splitTextForTts(text);
        for (final part in parts) {
          await _speakViaVoicevox(part);
        }
        return;
      }
      await _tts.stop();
      await _tts.speak(text);
      return;
    }
    if (_ttsServerUrl != null && _ttsServerUrl!.isNotEmpty) {
      await _speakViaServer(text);
      return;
    }
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _speakViaTypecast(String text) async {
    const uri = 'https://api.typecast.ai/v1/text-to-speech';
    final payload = {
      'voice_id': _typecastVoiceId,
      'text': text,
      'model': _typecastModel,
      'language': 'jpn',
      'prompt': const {
        'emotion_type': 'smart',
      },
      'output': const {
        'volume': 100,
        'audio_pitch': 0,
        'audio_tempo': 1.0,
        'audio_format': 'wav',
      },
      'seed': 42,
    };

    try {
      final response = await http
          .post(
            Uri.parse(uri),
            headers: {
              'Content-Type': 'application/json',
              'X-API-KEY': _typecastApiKey!,
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        if (_ttsServerUrl != null && _ttsServerUrl!.isNotEmpty) {
          await _speakViaServer(text);
          return;
        }
        await _tts.stop();
        await _tts.speak(text);
        return;
      }

      final audioBytes = response.bodyBytes;
      if (audioBytes.isEmpty) {
        if (_ttsServerUrl != null && _ttsServerUrl!.isNotEmpty) {
          await _speakViaServer(text);
          return;
        }
        await _tts.stop();
        await _tts.speak(text);
        return;
      }

      await _audioPlayer.stop();
      if (kIsWeb) {
        final dataUrl = 'data:audio/wav;base64,${base64Encode(audioBytes)}';
        await _audioPlayer.play(UrlSource(dataUrl));
      } else {
        await _audioPlayer.play(BytesSource(audioBytes));
      }
    } catch (error) {
      if (_ttsServerUrl != null && _ttsServerUrl!.isNotEmpty) {
        await _speakViaServer(text);
        return;
      }
      await _tts.stop();
      await _tts.speak(text);
    }
  }

  Future<void> _speakViaServer(String text) async {
    final baseUrl = _ttsServerUrl!;
    final uri = Uri.parse(baseUrl.endsWith('/') ? '${baseUrl}tts' : '$baseUrl/tts');
    try {
      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        await _tts.stop();
        await _tts.speak(text);
        return;
      }
      final audioBytes = response.bodyBytes;
      if (audioBytes.isEmpty) {
        await _tts.stop();
        await _tts.speak(text);
        return;
      }
      await _audioPlayer.stop();
      if (kIsWeb) {
        final dataUrl = 'data:audio/wav;base64,${base64Encode(audioBytes)}';
        await _audioPlayer.play(UrlSource(dataUrl));
      } else {
        await _audioPlayer.play(BytesSource(audioBytes));
      }
    } catch (error) {
      await _tts.stop();
      await _tts.speak(text);
    }
  }

  Future<void> _speakViaVoicevox(String text) async {
    final baseUrl = _ttsServerUrl!;
    
    final queryUri = Uri.parse(
      baseUrl.endsWith('/') ? '${baseUrl}audio_query' : '$baseUrl/audio_query',
    ).replace(queryParameters: {
      'text': text,
      'speaker': _voicevoxSpeakerId.toString(),
    });
    final synthUri = Uri.parse(
      baseUrl.endsWith('/') ? '${baseUrl}synthesis' : '$baseUrl/synthesis',
    ).replace(queryParameters: {
      'speaker': _voicevoxSpeakerId.toString(),
      'enable_interrogative_upspeak': 'false',
    });

    try {
      // Step 1: Get audio query (dikurangi timeout untuk lebih responsif)
      final queryResponse = await http
          .post(queryUri)
          .timeout(const Duration(seconds: 8));
      if (queryResponse.statusCode != 200) {
        await _tts.stop();
        await _tts.speak(text);
        return;
      }

      // Step 2: Modify query untuk speed optimization
      final queryJson = jsonDecode(queryResponse.body) as Map<String, dynamic>;
      queryJson['speedScale'] = 1.1; // Sedikit lebih cepat (1.0 = normal, max 2.0)
      
      // Step 3: Synthesize audio
      final synthResponse = await http
          .post(
            synthUri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(queryJson),
          )
          .timeout(const Duration(seconds: 15));
      if (synthResponse.statusCode != 200) {
        await _tts.stop();
        await _tts.speak(text);
        return;
      }

      final audioBytes = synthResponse.bodyBytes;
      if (audioBytes.isEmpty) {
        await _tts.stop();
        await _tts.speak(text);
        return;
      }
      
      // Play audio immediately setelah download
      await _audioPlayer.stop();
      if (kIsWeb) {
        final dataUrl = 'data:audio/wav;base64,${base64Encode(audioBytes)}';
        await _audioPlayer.play(UrlSource(dataUrl));
      } else {
        await _audioPlayer.play(BytesSource(audioBytes));
      }
    } catch (_) {
      await _tts.stop();
      await _tts.speak(text);
    }
  }

  Expression _inferExpression(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'\b(marah|kesal|jengkel|ngamuk)\b').hasMatch(lower)) {
      return Expression.angry;
    }
    if (RegExp(r'\b(sedih|maaf|kecewa|menangis)\b').hasMatch(lower)) {
      return Expression.sad;
    }
    if (RegExp(r'\b(senang|hebat|keren|terima kasih|yay)\b').hasMatch(lower)) {
      return Expression.happy;
    }
    return Expression.idle;
  }

  void _addMessage(_ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return 'Hari ini';
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return 'Kemarin';
    } else {
      // Show day, date, month, year in Indonesian
      final weekdays = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final weekday = weekdays[date.weekday % 7];
      final day = date.day;
      final month = months[date.month - 1];
      final year = date.year;
      return '$weekday, $day $month $year';
    }
  }

  void _sendTypedMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _textController.clear();
    _handleUserText(text);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 420;
    final userAvatarProvider = _profileAvatarBase64 == null ||
            _profileAvatarBase64!.isEmpty
        ? null
        : MemoryImage(base64Decode(_profileAvatarBase64!));
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: Drawer(
        backgroundColor: const Color(0xFFFFF4F7),
        child: SafeArea(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF4F7),
                  Color(0xFFFCE1E8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Chat History',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'New chat',
                            onPressed: () {
                              Navigator.of(context).pop();
                              _startNewChat();
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _sessions.isEmpty
                          ? const Center(child: Text('Belum ada chat'))
                          : ListView.builder(
                              itemCount: _sessions.length,
                              itemBuilder: (context, index) {
                                final session = _sessions[index];
                                final id = session['id'] as String? ?? '';
                                final title =
                                    session['title'] as String? ?? 'Chat';
                                final createdAt =
                                    (session['created_at'] as int?) ?? 0;
                                final isActive = id == _currentSessionId;
                                return ListTile(
                                  title: Text(title),
                                  subtitle: Text(
                                    DateTime.fromMillisecondsSinceEpoch(
                                            createdAt)
                                        .toLocal()
                                        .toString()
                                        .split('.')
                                        .first,
                                  ),
                                  selected: isActive,
                                  trailing: IconButton(
                                    tooltip: 'Rename',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _renameSession(id, title),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _switchSession(id);
                                  },
                                );
                              },
                            ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Menu',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text('Contact me'),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ContactPage(
                                    githubUrl: 'https://github.com/Abduldinata',
                                    instagramUrl:
                                        'https://www.instagram.com/nxta.div/',
                                    tiktokUrl:
                                        'https://www.tiktok.com/@hiyosashii',
                                    email: 'abdul.dinata557@gmail.com',
                                  ),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.favorite_border),
                            title: const Text('Support us'),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SupportPage(
                                    danaNumber: '089619348080',
                                  ),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.settings_outlined),
                            title: const Text('Settings'),
                            onTap: () async {
                              Navigator.of(context).pop();
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SettingsPage(),
                                ),
                              );
                              await _loadTtsMode();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.info_outline),
                            title: const Text('About'),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const AboutPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFBE9E7),
                    const Color(0xFFE3F2FD),
                    const Color(0xFFFFF8E1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: GlowBlob(color: const Color(0xFFF35D9C).withOpacity(0.2)),
          ),
          Positioned(
            bottom: -120,
            left: -60,
            child: GlowBlob(color: const Color(0xFFE0BBE4).withOpacity(0.18)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          tooltip: 'History',
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(Icons.menu_rounded),
                          color: const Color(0xFFF35D9C),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hyo AI',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF35D9C),
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(child: StatusPill(text: _statusText)),
                      const SizedBox(width: 10),
                      Tooltip(
                        message: _profileName.isNotEmpty
                            ? (_profileBio.isNotEmpty
                                ? 'Profil: $_profileName\n$_profileBio'
                                : 'Profil: $_profileName')
                            : 'Profil',
                        child: GestureDetector(
                          onTap: _openProfile,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFEFE7E4),
                            backgroundImage: userAvatarProvider,
                            child: userAvatarProvider == null
                                ? const Icon(Icons.person, size: 18)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    child: ExpressionCard(
                      key: ValueKey(_expression),
                      assetPath: _expressionAssets[_expression]!,
                      isThinking: _isThinking,
                      isListening: _isListening,
                      compact: isCompact,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                        ),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            // Check if we need to show a date separator
                            bool showDateSeparator = false;
                            if (index == 0) {
                              showDateSeparator = true;
                            } else {
                              final prevMessage = _messages[index - 1];
                              final prevDate = DateTime(
                                prevMessage.timestamp.year,
                                prevMessage.timestamp.month,
                                prevMessage.timestamp.day,
                              );
                              final currDate = DateTime(
                                message.timestamp.year,
                                message.timestamp.month,
                                message.timestamp.day,
                              );
                              showDateSeparator = !prevDate.isAtSameMomentAs(currDate);
                            }
                            return Column(
                              children: [
                                if (showDateSeparator)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0BBE4).withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _formatDateSeparator(message.timestamp),
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: const Color(0xFF6B6460),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ChatBubble(
                                  text: message.text,
                                  fromUser: message.fromUser,
                                  timestamp: message.timestamp,
                                  userAvatar: userAvatarProvider,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_partialText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _partialText,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: const Color(0xFF6B6460)),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            _ttsModeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: const Color(0xFF6B6460)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DropdownButtonFormField<String>(
                            value: _ttsModeSetting,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'typecast',
                                child: Text('Typecast'),
                              ),
                              DropdownMenuItem(
                                value: 'system',
                                child: Text('System TTS'),
                              ),
                              DropdownMenuItem(
                                value: 'voicevox',
                                child: Text('VoiceVox'),
                              ),
                            ],
                            onChanged: (value) async {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _ttsModeSetting = value;
                                _ttsModeLabel = _resolveTtsModeLabel();
                              });
                              try {
                                await _memoryStore.upsertPreference(
                                  'tts_mode',
                                  value,
                                );
                              } catch (_) {}
                              if (value == 'system') {
                                await _applySystemVoiceSelection();
                              }
                              if (value == 'voicevox' &&
                                  (_ttsServerUrl == null ||
                                      _ttsServerUrl!.isEmpty)) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'VoiceVox belum tersambung. Isi TTS_SERVER_URL.'),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        if (_isListening)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Input level: ${_soundLevel.toStringAsFixed(1)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: const Color(0xFF6B6460)),
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                minLines: 2,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Tulis pertanyaanmu...',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            MicButton(
                              isActive: _isListening,
                              onTap: _isListening
                                  ? _stopListening
                                  : _startListening,
                              onPressStart: _startListening,
                              onPressEnd: () => _stopListening(send: true),
                            ),
                            const SizedBox(width: 8),
                            SendButton(onTap: _sendTypedMessage),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
