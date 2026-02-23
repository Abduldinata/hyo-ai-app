const Map<String, Map<String, String>> translations = {
  'id': {
    // Main Chat Screen
    'app_title': 'Hyo AI',
    'history': 'Riwayat',
    'no_chat': 'Belum ada chat',
    'rename_chat': 'Rename chat',
    'chat_title': 'Chat title',
    'cancel': 'Batal',
    'save': 'Simpan',
    'profile': 'Profil',
    'settings': 'Pengaturan',
    'about': 'Tentang',
    'support': 'Dukungan',
    'contact': 'Kontak',
    
    // Status Messages
    'listening': 'Mendengarkan...',
    'ready': 'Siap mendengarkan.',
    'press_mic': 'Tekan mic untuk mulai.',
    'mic_not_allowed': 'Mic belum diizinkan di perangkat.',
    'speech_not_ready': 'Speech belum siap di perangkat ini.',
    'processing': 'Memproses suara...',
    'no_sound': 'Tidak ada suara terdeteksi.',
    'hyo_thinking': 'Hyo sedang berpikir...',
    'new_chat_started': 'Chat baru dimulai.',
    'wait_hyo': 'Tunggu sebentar, Hyo masih menjawab.',
    'starting_mic': 'Memulai mic...',
    'initializing_speech': 'Menginisialisasi speech...',
    'mic_error': 'Error mic:',
    'starting_listen': 'Memulai mendengarkan...',
    'listen_failed': 'Mic gagal memulai:',
    
    // Input & UI
    'write_question': 'Tulis pertanyaanmu...',
    'input_level': 'Input level:',
    'today': 'Hari ini',
    'yesterday': 'Kemarin',
    
    // TTS & Settings
    'tts_label': 'TTS: System',
    'tts_off': 'TTS: Off',
    'tts_typecast': 'TTS: Typecast',
    'tts_voicevox': 'TTS: VoiceVox',
    'tts_typecast_not_ready': 'TTS: Typecast (tidak siap)',
    'tts_voicevox_offline': 'TTS: VoiceVox (offline)',
    'voicevox_not_connected': 'VoiceVox belum tersambung. Isi TTS_SERVER_URL.',
    'tts_mode': 'TTS Mode',
    'typecast': 'Typecast',
    'system_tts': 'System TTS',
    'voicevox': 'VoiceVox',
    
    // Errors & Responses
    'gemini_api_key_missing': 'API key Gemini belum diisi. Salin .env.example menjadi .env dan isi GEMINI_API_KEY.',
    'ai_timeout': 'AI belum merespon (timeout). Cek koneksi internet dan API key.',
    'error': 'Error:',
    'too_many_requests': 'Terlalu banyak request. Coba lagi sebentar ya.',
    'cannot_answer': 'Maaf, aku belum bisa menjawab itu.',
    'wait_gemini': 'Tunggu beberapa saat ya, biar tidak kena limit.',
    'no_sound_detected': 'Tidak ada suara terdeteksi.',
    
    // Language Settings
    'language': 'Bahasa',
    'auto': 'Auto (Otomatis)',
    'english': 'English',
    'indonesian': 'Bahasa Indonesia',
    'language_selected': 'Bahasa dipilih:',
    
    // Settings Page
    'voicevox_server_url': 'VoiceVox Server URL',
    'auto_translate': 'Terjemah Otomatis',
    'auto_translate_desc': 'Terjemahkan respons ke bahasa pilihan (id/en)',
    'tts_text_mode': 'Mode Text TTS',
    'jp': 'Japanese (日本語)',
    'romaji': 'Romaji',
    'original': 'Original',
  },
  'en': {
    // Main Chat Screen
    'app_title': 'Hyo AI',
    'history': 'History',
    'no_chat': 'No chat yet',
    'rename_chat': 'Rename chat',
    'chat_title': 'Chat title',
    'cancel': 'Cancel',
    'save': 'Save',
    'profile': 'Profile',
    'settings': 'Settings',
    'about': 'About',
    'support': 'Support',
    'contact': 'Contact',
    
    // Status Messages
    'listening': 'Listening...',
    'ready': 'Ready to listen.',
    'press_mic': 'Press mic to start.',
    'mic_not_allowed': 'Mic not allowed on this device.',
    'speech_not_ready': 'Speech not ready on this device.',
    'processing': 'Processing audio...',
    'no_sound': 'No sound detected.',
    'hyo_thinking': 'Hyo is thinking...',
    'new_chat_started': 'New chat started.',
    'wait_hyo': 'Wait a moment, Hyo is still answering.',
    'starting_mic': 'Starting mic...',
    'initializing_speech': 'Initializing speech...',
    'mic_error': 'Mic error:',
    'starting_listen': 'Starting to listen...',
    'listen_failed': 'Mic failed to start:',
    
    // Input & UI
    'write_question': 'Ask me something...',
    'input_level': 'Input level:',
    'today': 'Today',
    'yesterday': 'Yesterday',
    
    // TTS & Settings
    'tts_label': 'TTS: System',
    'tts_off': 'TTS: Off',
    'tts_typecast': 'TTS: Typecast',
    'tts_voicevox': 'TTS: VoiceVox',
    'tts_typecast_not_ready': 'TTS: Typecast (not ready)',
    'tts_voicevox_offline': 'TTS: VoiceVox (offline)',
    'voicevox_not_connected': 'VoiceVox not connected. Set TTS_SERVER_URL.',
    'tts_mode': 'TTS Mode',
    'typecast': 'Typecast',
    'system_tts': 'System TTS',
    'voicevox': 'VoiceVox',
    
    // Errors & Responses
    'gemini_api_key_missing': 'Gemini API key not set. Copy .env.example to .env and fill GEMINI_API_KEY.',
    'ai_timeout': 'AI did not respond (timeout). Check internet and API key.',
    'error': 'Error:',
    'too_many_requests': 'Too many requests. Try again in a moment.',
    'cannot_answer': 'Sorry, I cannot answer that yet.',
    'wait_gemini': 'Wait a moment, to avoid rate limit.',
    'no_sound_detected': 'No sound detected.',
    
    // Language Settings
    'language': 'Language',
    'auto': 'Auto (System)',
    'english': 'English',
    'indonesian': 'Bahasa Indonesia',
    'language_selected': 'Language selected:',
    
    // Settings Page
    'voicevox_server_url': 'VoiceVox Server URL',
    'auto_translate': 'Auto Translate',
    'auto_translate_desc': 'Translate response to selected language (id/en)',
    'tts_text_mode': 'TTS Text Mode',
    'jp': 'Japanese (日本語)',
    'romaji': 'Romaji',
    'original': 'Original',
  },
};
