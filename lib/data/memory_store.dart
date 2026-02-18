import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class MemoryStore {
  MemoryStore._();

  static final MemoryStore instance = MemoryStore._();

  Database? _db;
  final List<Map<String, Object?>> _memoryMessages = [];
  final List<Map<String, Object?>> _memorySessions = [];
  final Map<String, String> _memoryPreferences = {};
  final Map<String, String> _memoryProfile = {};

  Future<Database> _getDb() async {
    if (_db != null) {
      return _db!;
    }
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on Web.');
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'hyo_ai.db');
    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute(
          '''CREATE TABLE messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT,
            role TEXT NOT NULL,
            text TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )''',
        );
        await db.execute(
          '''CREATE TABLE sessions(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''',
        );
        await db.execute(
          '''CREATE TABLE preferences(
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )''',
        );
        await db.execute(
          '''CREATE TABLE profile(
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )''',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            '''CREATE TABLE IF NOT EXISTS sessions(
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )''',
          );
          await db.execute(
            '''CREATE TABLE IF NOT EXISTS profile(
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )''',
          );
          await db.execute(
            'ALTER TABLE messages ADD COLUMN session_id TEXT',
          );
          const legacyId = 'legacy';
          await db.insert(
            'sessions',
            {
              'id': legacyId,
              'title': 'Chat Lama',
              'created_at': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          await db.update(
            'messages',
            {'session_id': legacyId},
            where: 'session_id IS NULL',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE sessions ADD COLUMN updated_at INTEGER',
          );
          await db.update(
            'sessions',
            {'updated_at': DateTime.now().millisecondsSinceEpoch},
          );
        }
      },
    );
    if (_db == null) {
      throw StateError('Database initialization failed.');
    }
    await _ensureSchema(_db!);
    return _db!;
  }

  Future<void> _ensureSchema(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(messages)');
    final hasSessionId = columns.any(
      (row) => (row['name'] as String?)?.toLowerCase() == 'session_id',
    );
    if (!hasSessionId) {
      await db.execute('ALTER TABLE messages ADD COLUMN session_id TEXT');
      const legacyId = 'legacy';
      await db.insert(
        'sessions',
        {
          'id': legacyId,
          'title': 'Chat Lama',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await db.update(
        'messages',
        {'session_id': legacyId},
        where: 'session_id IS NULL',
      );
    }
    final sessionColumns = await db.rawQuery('PRAGMA table_info(sessions)');
    final hasUpdatedAt = sessionColumns.any(
      (row) => (row['name'] as String?)?.toLowerCase() == 'updated_at',
    );
    if (!hasUpdatedAt) {
      await db.execute('ALTER TABLE sessions ADD COLUMN updated_at INTEGER');
      await db.update(
        'sessions',
        {'updated_at': DateTime.now().millisecondsSinceEpoch},
      );
    }
  }

  void _touchMemorySession(String sessionId, int timestamp) {
    for (final session in _memorySessions) {
      if (session['id'] == sessionId) {
        session['updated_at'] = timestamp;
        return;
      }
    }
  }

  Future<void> addMessage({
    required String sessionId,
    required String role,
    required String text,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (kIsWeb) {
      _memoryMessages.add({
        'session_id': sessionId,
        'role': role,
        'text': text,
        'created_at': now,
      });
      _touchMemorySession(sessionId, now);
      return;
    }
    final db = await _getDb();
    await db.insert('messages', {
      'session_id': sessionId,
      'role': role,
      'text': text,
      'created_at': now,
    });
    await db.update(
      'sessions',
      {'updated_at': now},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<Map<String, Object?>>> getRecentMessages({
    required String sessionId,
    int limit = 8,
  }) async {
    if (kIsWeb) {
      final sessionMessages = _memoryMessages
          .where((row) => row['session_id'] == sessionId)
          .toList();
      final slice = sessionMessages.length <= limit
          ? sessionMessages
          : sessionMessages.sublist(sessionMessages.length - limit);
      return List<Map<String, Object?>>.from(slice);
    }
    final db = await _getDb();
    return db.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, Object?>>> getMessagesForSession(
    String sessionId, {
    int? limit,
  }) async {
    if (kIsWeb) {
      final sessionMessages = _memoryMessages
          .where((row) => row['session_id'] == sessionId)
          .toList();
      if (limit != null && sessionMessages.length > limit) {
        return List<Map<String, Object?>>.from(
          sessionMessages.sublist(sessionMessages.length - limit),
        );
      }
      return List<Map<String, Object?>>.from(sessionMessages);
    }
    final db = await _getDb();
    return db.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
      limit: limit,
    );
  }

  Future<String> createSession({String? title}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final sessionTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : 'Chat Baru';
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final updatedAt = createdAt;

    if (kIsWeb) {
      _memorySessions.add({
        'id': id,
        'title': sessionTitle,
        'created_at': createdAt,
        'updated_at': updatedAt,
      });
      return id;
    }

    final db = await _getDb();
    await db.insert('sessions', {
      'id': id,
      'title': sessionTitle,
      'created_at': createdAt,
      'updated_at': updatedAt,
    });
    return id;
  }

  Future<List<Map<String, Object?>>> getSessions({int limit = 50}) async {
    if (kIsWeb) {
      final list = List<Map<String, Object?>>.from(_memorySessions);
      list.sort((a, b) =>
          (b['updated_at'] as int? ?? b['created_at'] as int)
              .compareTo(a['updated_at'] as int? ?? a['created_at'] as int));
      return list.length > limit ? list.sublist(0, limit) : list;
    }
    final db = await _getDb();
    return db.query(
      'sessions',
      orderBy: 'updated_at DESC, created_at DESC',
      limit: limit,
    );
  }

  Future<void> updateSessionTitle(String sessionId, String title) async {
    final newTitle = title.trim();
    if (newTitle.isEmpty) {
      return;
    }
    if (kIsWeb) {
      for (final session in _memorySessions) {
        if (session['id'] == sessionId) {
          session['title'] = newTitle;
          session['updated_at'] = DateTime.now().millisecondsSinceEpoch;
          break;
        }
      }
      return;
    }
    final db = await _getDb();
    await db.update(
      'sessions',
      {
        'title': newTitle,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> upsertPreference(String key, String value) async {
    if (kIsWeb) {
      _memoryPreferences[key] = value;
      return;
    }
    final db = await _getDb();
    await db.insert(
      'preferences',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String>> getPreferences() async {
    if (kIsWeb) {
      return Map<String, String>.from(_memoryPreferences);
    }
    final db = await _getDb();
    final rows = await db.query('preferences');
    final map = <String, String>{};
    for (final row in rows) {
      map[row['key'] as String] = row['value'] as String;
    }
    return map;
  }

  Future<void> upsertProfileField(String key, String value) async {
    final trimmed = value.trim();
    if (kIsWeb) {
      if (trimmed.isEmpty) {
        _memoryProfile.remove(key);
      } else {
        _memoryProfile[key] = trimmed;
      }
      return;
    }
    final db = await _getDb();
    if (trimmed.isEmpty) {
      await db.delete('profile', where: 'key = ?', whereArgs: [key]);
      return;
    }
    await db.insert(
      'profile',
      {'key': key, 'value': trimmed},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String>> getProfile() async {
    if (kIsWeb) {
      return Map<String, String>.from(_memoryProfile);
    }
    final db = await _getDb();
    final rows = await db.query('profile');
    final map = <String, String>{};
    for (final row in rows) {
      map[row['key'] as String] = row['value'] as String;
    }
    return map;
  }

  Future<void> clearMessages() async {
    if (kIsWeb) {
      _memoryMessages.clear();
      return;
    }
    final db = await _getDb();
    await db.delete('messages');
  }

  Future<void> clearSessionMessages(String sessionId) async {
    if (kIsWeb) {
      _memoryMessages.removeWhere((row) => row['session_id'] == sessionId);
      return;
    }
    final db = await _getDb();
    await db.delete('messages', where: 'session_id = ?', whereArgs: [sessionId]);
  }
}
