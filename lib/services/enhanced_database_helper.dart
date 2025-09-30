import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../models/recording_model.dart';
import '../models/report_model.dart';
import '../models/noise_data_model.dart';
import '../models/license_plate_model.dart';
import '../models/location_model.dart';
import '../models/user_model.dart';

class EnhancedDatabaseHelper {
  static EnhancedDatabaseHelper? _instance;
  static Database? _database;

  static const int _currentVersion = 3;
  static const String _dbName = 'medivu_app_enhanced_v3.db';

  static EnhancedDatabaseHelper get instance {
    _instance ??= EnhancedDatabaseHelper._internal();
    return _instance!;
  }

  EnhancedDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _dbName);
      
      print('💾 개선된 데이터베이스 경로: $path');
      
      final db = await openDatabase(
        path,
        version: _currentVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) {
          print('✅ 개선된 데이터베이스 연결 성공 (버전: $_currentVersion)');
        },
      );
      
      // 외래 키 제약조건 활성화
      await db.execute('PRAGMA foreign_keys = ON');
      
      print('✅ 개선된 데이터베이스 초기화 완료');
      return db;
    } catch (e) {
      print('❌ 개선된 데이터베이스 초기화 실패: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _createIndexes(db);
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 데이터베이스 업그레이드: $oldVersion -> $newVersion');

    if (oldVersion < 2) {
      await _migrateToV2(db);
    }

    if (oldVersion < 3) {
      await _migrateToV3(db);
    }
  }

  Future<void> _createTables(Database db) async {
    // Users 테이블 - 강화된 인증 시스템
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        display_name TEXT,
        phone_number TEXT,
        profile_image_path TEXT,
        email_verified INTEGER DEFAULT 0,
        phone_verified INTEGER DEFAULT 0,
        two_factor_enabled INTEGER DEFAULT 0,
        account_status TEXT DEFAULT 'active' CHECK (account_status IN ('active', 'suspended', 'deactivated')),
        last_login_at INTEGER,
        failed_login_attempts INTEGER DEFAULT 0,
        locked_until INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // User Sessions 테이블 - 세션 관리
    await db.execute('''
      CREATE TABLE user_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        session_token TEXT UNIQUE NOT NULL,
        device_id TEXT,
        device_info TEXT,
        ip_address TEXT,
        user_agent TEXT,
        is_active INTEGER DEFAULT 1,
        expires_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        last_activity_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // User Preferences 테이블 - 사용자 설정
    await db.execute('''
      CREATE TABLE user_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        preference_key TEXT NOT NULL,
        preference_value TEXT,
        preference_type TEXT DEFAULT 'string' CHECK (preference_type IN ('string', 'number', 'boolean', 'json')),
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(user_id, preference_key)
      )
    ''');

    // Password Reset Tokens 테이블
    await db.execute('''
      CREATE TABLE password_reset_tokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        token TEXT UNIQUE NOT NULL,
        expires_at INTEGER NOT NULL,
        used INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Login Attempts 테이블 - 보안 로그
    await db.execute('''
      CREATE TABLE login_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        ip_address TEXT,
        user_agent TEXT,
        success INTEGER NOT NULL,
        failure_reason TEXT,
        attempted_at INTEGER NOT NULL
      )
    ''');

    // 기존 테이블들 유지하되 개선
    await _createRecordingTables(db);
  }

  Future<void> _createRecordingTables(Database db) async {
    // Sessions 테이블 - 개선된 버전
    await db.execute('''
      CREATE TABLE recording_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        session_uuid TEXT UNIQUE NOT NULL,
        video_path TEXT,
        video_url TEXT,
        thumbnail_path TEXT,
        gps_lat REAL,
        gps_lng REAL,
        location_address TEXT,
        started_at INTEGER NOT NULL,
        ended_at INTEGER,
        duration_seconds INTEGER,
        low_db REAL,
        average_db REAL,
        high_db REAL,
        peak_db REAL,
        status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'recording', 'completed', 'failed', 'archived')),
        metadata TEXT,
        privacy_level TEXT DEFAULT 'private' CHECK (privacy_level IN ('private', 'shared', 'public')),
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Noise Logs 테이블 - 개선된 버전
    await db.execute('''
      CREATE TABLE noise_measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        timestamp_offset REAL NOT NULL,
        decibel_value REAL NOT NULL,
        frequency_data TEXT,
        quality_score REAL,
        recorded_at INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES recording_sessions (id) ON DELETE CASCADE
      )
    ''');

    // License Plates 테이블 - 개선된 버전
    await db.execute('''
      CREATE TABLE license_plate_detections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        recognized_text TEXT NOT NULL,
        raw_text TEXT,
        confidence REAL,
        frame_time REAL NOT NULL,
        bbox_x REAL NOT NULL,
        bbox_y REAL NOT NULL,
        bbox_w REAL NOT NULL,
        bbox_h REAL NOT NULL,
        detection_model TEXT,
        is_validated INTEGER DEFAULT 0,
        validation_source TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES recording_sessions (id) ON DELETE CASCADE
      )
    ''');

    // Reports 테이블 - 개선된 버전
    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        generated_pdf_path TEXT,
        report_type TEXT DEFAULT 'noise_complaint' CHECK (report_type IN ('noise_complaint', 'traffic_violation', 'evidence_report')),
        status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'processing', 'ready', 'generated', 'submitted', 'completed', 'rejected', 'approved')),
        submission_reference TEXT,
        submitted_to TEXT,
        submitted_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES recording_sessions (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    // Users 관련 인덱스
    await db.execute('CREATE UNIQUE INDEX idx_users_email ON users (email)');
    await db.execute('CREATE INDEX idx_users_status ON users (account_status)');
    await db.execute('CREATE INDEX idx_users_last_login ON users (last_login_at)');

    // Sessions 관련 인덱스
    await db.execute('CREATE INDEX idx_user_sessions_token ON user_sessions (session_token)');
    await db.execute('CREATE INDEX idx_user_sessions_user_id ON user_sessions (user_id)');
    await db.execute('CREATE INDEX idx_user_sessions_active ON user_sessions (is_active, expires_at)');

    // Login Attempts 인덱스
    await db.execute('CREATE INDEX idx_login_attempts_email ON login_attempts (email)');
    await db.execute('CREATE INDEX idx_login_attempts_time ON login_attempts (attempted_at)');

    // Recording 관련 인덱스
    await db.execute('CREATE INDEX idx_recording_sessions_user_id ON recording_sessions (user_id)');
    await db.execute('CREATE INDEX idx_recording_sessions_uuid ON recording_sessions (session_uuid)');
    await db.execute('CREATE INDEX idx_recording_sessions_status ON recording_sessions (status)');
    await db.execute('CREATE INDEX idx_recording_sessions_created_at ON recording_sessions (created_at)');
    
    await db.execute('CREATE INDEX idx_noise_measurements_session_id ON noise_measurements (session_id)');
    await db.execute('CREATE INDEX idx_license_plate_detections_session_id ON license_plate_detections (session_id)');
    await db.execute('CREATE INDEX idx_reports_session_id ON reports (session_id)');
  }

  Future<void> _insertDefaultData(Database db) async {
    // 기본 사용자 설정값들
    final defaultPrefs = {
      'noise_threshold': '70.0',
      'auto_save_videos': 'true',
      'location_tracking': 'true',
      'notification_enabled': 'true',
      'dark_mode': 'false',
      'language': 'ko',
    };

    print('✅ 기본 데이터 준비 완료');
  }

  Future<void> _migrateToV2(Database db) async {
    // V1에서 V2로 마이그레이션 로직
    print('🔄 V2 마이그레이션 시작');
    
    // 기존 users 테이블 백업
    await db.execute('ALTER TABLE users RENAME TO users_backup');
    
    // 새로운 테이블 생성
    await _createTables(db);
    
    // 기존 데이터 마이그레이션
    final oldUsers = await db.query('users_backup');
    for (final user in oldUsers) {
      await db.insert('users', {
        'email': user['email'],
        'password_hash': _hashPassword('temp123', _generateSalt()), // 임시 비밀번호
        'salt': _generateSalt(),
        'display_name': user['email']?.toString().split('@').first,
        'created_at': user['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
    
    // 백업 테이블 삭제
    await db.execute('DROP TABLE users_backup');
    
    print('✅ V2 마이그레이션 완료');
  }

  Future<void> _migrateToV3(Database db) async {
    // V2에서 V3로 마이그레이션 로직
    print('🔄 V3 마이그레이션 시작 - reports 테이블 status 제약조건 확장');

    try {
      // 새로운 reports 테이블 생성 (임시)
      await db.execute('''
        CREATE TABLE reports_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          generated_pdf_path TEXT,
          report_type TEXT DEFAULT 'noise_complaint' CHECK (report_type IN ('noise_complaint', 'traffic_violation', 'evidence_report')),
          status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'processing', 'ready', 'generated', 'submitted', 'completed', 'rejected', 'approved')),
          submission_reference TEXT,
          submitted_to TEXT,
          submitted_at INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (session_id) REFERENCES recording_sessions (id) ON DELETE CASCADE
        )
      ''');

      // 기존 데이터 복사
      await db.execute('''
        INSERT INTO reports_new (id, session_id, title, description, generated_pdf_path, report_type, status, submission_reference, submitted_to, submitted_at, created_at, updated_at)
        SELECT id, session_id, title, description, generated_pdf_path, report_type, status, submission_reference, submitted_to, submitted_at, created_at, updated_at
        FROM reports
      ''');

      // 기존 테이블 삭제
      await db.execute('DROP TABLE reports');

      // 새 테이블 이름 변경
      await db.execute('ALTER TABLE reports_new RENAME TO reports');

      // 인덱스 재생성
      await db.execute('CREATE INDEX idx_reports_session_id ON reports (session_id)');

      print('✅ V3 마이그레이션 완료 - reports 테이블 status 제약조건 확장');
    } catch (e) {
      print('❌ V3 마이그레이션 실패: $e');
      rethrow;
    }
  }

  // 보안 관련 유틸리티 메서드
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _verifyPassword(String password, String hash, String salt) {
    return _hashPassword(password, salt) == hash;
  }

  // 사용자 인증 관련 메서드
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    String? displayName,
    String? phoneNumber,
  }) async {
    try {
      final db = await database;
      
      // 이메일 중복 확인
      final existingUser = await getUserByEmail(email);
      if (existingUser != null) {
        return {
          'success': false,
          'message': '이미 존재하는 이메일입니다.',
          'code': 'EMAIL_ALREADY_EXISTS',
        };
      }

      // 비밀번호 유효성 검사
      final passwordValidation = _validatePassword(password);
      if (!passwordValidation['isValid']) {
        return {
          'success': false,
          'message': passwordValidation['message'],
          'code': 'INVALID_PASSWORD',
        };
      }

      // 솔트 생성 및 비밀번호 해싱
      final salt = _generateSalt();
      final passwordHash = _hashPassword(password, salt);

      final now = DateTime.now().millisecondsSinceEpoch;
      
      final userId = await db.insert('users', {
        'email': email,
        'password_hash': passwordHash,
        'salt': salt,
        'display_name': displayName ?? email.split('@').first,
        'phone_number': phoneNumber,
        'created_at': now,
        'updated_at': now,
      });

      // 기본 설정 생성
      await _createDefaultUserPreferences(userId);

      print('✅ 사용자 생성 완료: ID=$userId, Email=$email');
      
      return {
        'success': true,
        'message': '회원가입이 완료되었습니다.',
        'userId': userId,
      };
    } catch (e) {
      print('❌ createUser 에러: $e');
      return {
        'success': false,
        'message': '회원가입 중 오류가 발생했습니다.',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> authenticateUser(String email, String password) async {
    try {
      final db = await database;
      
      // 로그인 시도 기록
      await _recordLoginAttempt(email, success: false, failureReason: 'ATTEMPT_STARTED');

      // 사용자 조회
      final userMaps = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (userMaps.isEmpty) {
        await _recordLoginAttempt(email, success: false, failureReason: 'USER_NOT_FOUND');
        return {
          'success': false,
          'message': '존재하지 않는 사용자입니다.',
          'code': 'USER_NOT_FOUND',
        };
      }

      final userMap = userMaps.first;
      final userId = userMap['id'] as int;

      // 계정 잠금 확인
      final lockedUntil = userMap['locked_until'] as int?;
      if (lockedUntil != null && lockedUntil > DateTime.now().millisecondsSinceEpoch) {
        await _recordLoginAttempt(email, success: false, failureReason: 'ACCOUNT_LOCKED');
        return {
          'success': false,
          'message': '계정이 일시적으로 잠겼습니다. 나중에 다시 시도해주세요.',
          'code': 'ACCOUNT_LOCKED',
        };
      }

      // 비밀번호 검증
      final passwordHash = userMap['password_hash'] as String;
      final salt = userMap['salt'] as String;
      
      if (!_verifyPassword(password, passwordHash, salt)) {
        // 실패 횟수 증가
        final failedAttempts = (userMap['failed_login_attempts'] as int) + 1;
        
        Map<String, dynamic> updateData = {
          'failed_login_attempts': failedAttempts,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        };

        // 5회 실패 시 30분 잠금
        if (failedAttempts >= 5) {
          updateData['locked_until'] = DateTime.now().add(Duration(minutes: 30)).millisecondsSinceEpoch;
        }

        await db.update('users', updateData, where: 'id = ?', whereArgs: [userId]);
        await _recordLoginAttempt(email, success: false, failureReason: 'WRONG_PASSWORD');

        return {
          'success': false,
          'message': '비밀번호가 올바르지 않습니다.',
          'code': 'WRONG_PASSWORD',
          'attemptsLeft': 5 - failedAttempts,
        };
      }

      // 로그인 성공 처리
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.update('users', {
        'last_login_at': now,
        'failed_login_attempts': 0,
        'locked_until': null,
        'updated_at': now,
      }, where: 'id = ?', whereArgs: [userId]);

      await _recordLoginAttempt(email, success: true);

      // 세션 토큰 생성
      final sessionToken = await createUserSession(userId);

      final user = UserModel.fromDatabaseMap(userMap);

      print('✅ 로그인 성공: $email');
      
      return {
        'success': true,
        'message': '로그인되었습니다.',
        'user': user,
        'sessionToken': sessionToken,
      };
    } catch (e) {
      print('❌ authenticateUser 에러: $e');
      await _recordLoginAttempt(email, success: false, failureReason: 'SYSTEM_ERROR');
      return {
        'success': false,
        'message': '로그인 중 오류가 발생했습니다.',
        'error': e.toString(),
      };
    }
  }

  Future<String> createUserSession(int userId) async {
    final db = await database;
    
    // 기존 활성 세션들을 비활성화
    await db.update('user_sessions', 
      {'is_active': 0, 'last_activity_at': DateTime.now().millisecondsSinceEpoch},
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
    );

    // 새 세션 토큰 생성
    final sessionToken = _generateSessionToken();
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = DateTime.now().add(Duration(days: 7)).millisecondsSinceEpoch;

    await db.insert('user_sessions', {
      'user_id': userId,
      'session_token': sessionToken,
      'expires_at': expiresAt,
      'created_at': now,
      'last_activity_at': now,
    });

    return sessionToken;
  }

  Future<UserModel?> getUserBySessionToken(String sessionToken) async {
    final db = await database;
    
    final sessionMaps = await db.rawQuery('''
      SELECT u.*, s.last_activity_at, s.expires_at
      FROM users u
      INNER JOIN user_sessions s ON u.id = s.user_id
      WHERE s.session_token = ? AND s.is_active = 1 AND s.expires_at > ?
    ''', [sessionToken, DateTime.now().millisecondsSinceEpoch]);

    if (sessionMaps.isEmpty) return null;

    // 활동 시간 업데이트
    await updateSessionActivity(sessionToken);

    return UserModel.fromDatabaseMap(sessionMaps.first);
  }

  Future<void> updateSessionActivity(String sessionToken) async {
    final db = await database;
    
    await db.update('user_sessions', {
      'last_activity_at': DateTime.now().millisecondsSinceEpoch,
    }, where: 'session_token = ? AND is_active = 1', whereArgs: [sessionToken]);
  }

  Future<void> invalidateSession(String sessionToken) async {
    final db = await database;
    
    await db.update('user_sessions', {
      'is_active': 0,
      'last_activity_at': DateTime.now().millisecondsSinceEpoch,
    }, where: 'session_token = ?', whereArgs: [sessionToken]);
  }

  Future<void> invalidateAllUserSessions(int userId) async {
    final db = await database;
    
    await db.update('user_sessions', {
      'is_active': 0,
      'last_activity_at': DateTime.now().millisecondsSinceEpoch,
    }, where: 'user_id = ?', whereArgs: [userId]);
  }

  String _generateSessionToken() {
    final random = Random.secure();
    final tokenBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(tokenBytes);
  }

  Map<String, dynamic> _validatePassword(String password) {
    if (password.length < 8) {
      return {'isValid': false, 'message': '비밀번호는 최소 8자 이상이어야 합니다.'};
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return {'isValid': false, 'message': '비밀번호에 대문자가 포함되어야 합니다.'};
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      return {'isValid': false, 'message': '비밀번호에 소문자가 포함되어야 합니다.'};
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      return {'isValid': false, 'message': '비밀번호에 숫자가 포함되어야 합니다.'};
    }
    
    return {'isValid': true, 'message': '유효한 비밀번호입니다.'};
  }

  Future<void> _recordLoginAttempt(String email, {required bool success, String? failureReason}) async {
    final db = await database;
    
    await db.insert('login_attempts', {
      'email': email,
      'success': success ? 1 : 0,
      'failure_reason': failureReason,
      'attempted_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _createDefaultUserPreferences(int userId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final defaultPrefs = {
      'noise_threshold': '70.0',
      'auto_save_videos': 'true',
      'location_tracking': 'true',
      'notification_enabled': 'true',
      'dark_mode': 'false',
      'language': 'ko',
    };

    for (final entry in defaultPrefs.entries) {
      await db.insert('user_preferences', {
        'user_id': userId,
        'preference_key': entry.key,
        'preference_value': entry.value,
        'preference_type': entry.value == 'true' || entry.value == 'false' ? 'boolean' : 'string',
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  // 기존 호환성을 위한 메서드들
  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    
    final userMaps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (userMaps.isNotEmpty) {
      return UserModel.fromDatabaseMap(userMaps.first);
    }
    return null;
  }

  Future<UserModel?> getUser(int id) async {
    final db = await database;
    
    final userMaps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (userMaps.isNotEmpty) {
      return UserModel.fromDatabaseMap(userMaps.first);
    }
    return null;
  }

  // 사용자 설정 관리
  Future<void> setUserPreference(int userId, String key, dynamic value) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    String type = 'string';
    String stringValue = value.toString();
    
    if (value is bool) {
      type = 'boolean';
      stringValue = value.toString();
    } else if (value is num) {
      type = 'number';
      stringValue = value.toString();
    } else if (value is Map || value is List) {
      type = 'json';
      stringValue = jsonEncode(value);
    }

    await db.insert('user_preferences', {
      'user_id': userId,
      'preference_key': key,
      'preference_value': stringValue,
      'preference_type': type,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<T?> getUserPreference<T>(int userId, String key) async {
    final db = await database;
    
    final prefMaps = await db.query(
      'user_preferences',
      where: 'user_id = ? AND preference_key = ?',
      whereArgs: [userId, key],
    );

    if (prefMaps.isEmpty) return null;

    final prefMap = prefMaps.first;
    final value = prefMap['preference_value'] as String;
    final type = prefMap['preference_type'] as String;

    switch (type) {
      case 'boolean':
        return (value == 'true') as T;
      case 'number':
        return (double.tryParse(value) ?? int.tryParse(value)) as T?;
      case 'json':
        return jsonDecode(value) as T;
      default:
        return value as T;
    }
  }

  Future<Map<String, dynamic>> getAllUserPreferences(int userId) async {
    final db = await database;
    
    final prefMaps = await db.query(
      'user_preferences',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    final preferences = <String, dynamic>{};
    
    for (final prefMap in prefMaps) {
      final key = prefMap['preference_key'] as String;
      final value = prefMap['preference_value'] as String;
      final type = prefMap['preference_type'] as String;

      switch (type) {
        case 'boolean':
          preferences[key] = value == 'true';
          break;
        case 'number':
          preferences[key] = double.tryParse(value) ?? int.tryParse(value);
          break;
        case 'json':
          preferences[key] = jsonDecode(value);
          break;
        default:
          preferences[key] = value;
      }
    }

    return preferences;
  }

  // 데이터베이스 정리
  Future<void> clearDatabase() async {
    final db = await database;
    
    final tables = [
      'password_reset_tokens',
      'login_attempts',
      'user_sessions',
      'user_preferences',
      'reports',
      'license_plate_detections',
      'noise_measurements',
      'recording_sessions',
      'users',
    ];

    for (final table in tables) {
      await db.delete(table);
    }
    
    print('✅ 데이터베이스 초기화 완료');
  }

  // ===== RECORDING SESSION METHODS =====
  
  Future<int> insertSession(RecordingModel recording) async {
    final db = await database;
    
    final sessionId = await db.insert('recording_sessions', {
      'user_id': int.tryParse(recording.userId) ?? 1,
      'session_uuid': recording.id,
      'video_path': recording.videoPath,
      'gps_lat': recording.location?.latitude,
      'gps_lng': recording.location?.longitude,
      'location_address': recording.location?.address,
      'started_at': recording.startTime.millisecondsSinceEpoch,
      'ended_at': recording.endTime?.millisecondsSinceEpoch,
      'duration_seconds': recording.duration?.inSeconds,
      'low_db': recording.noiseData.minDecibel,
      'average_db': recording.noiseData.avgDecibel,
      'high_db': recording.noiseData.maxDecibel,
      'peak_db': recording.noiseData.maxDecibel,
      'status': recording.status.name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });

    // Insert noise measurements
    if (recording.noiseData.readings.isNotEmpty) {
      for (int i = 0; i < recording.noiseData.readings.length; i++) {
        await db.insert('noise_measurements', {
          'session_id': sessionId,
          'timestamp_offset': i.toDouble(),
          'decibel_value': recording.noiseData.readings[i],
          'recorded_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    }

    // Insert license plate detection if exists
    if (recording.licensePlate != null) {
      await db.insert('license_plate_detections', {
        'session_id': sessionId,
        'recognized_text': recording.licensePlate!.plateNumber,
        'raw_text': recording.licensePlate!.rawText,
        'confidence': recording.licensePlate!.confidence,
        'frame_time': 0.0,
        'bbox_x': 0.0,
        'bbox_y': 0.0,
        'bbox_w': 0.0,
        'bbox_h': 0.0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }

    return sessionId;
  }

  Future<RecordingModel?> getSession(int sessionId) async {
    final db = await database;
    
    final sessionMaps = await db.query(
      'recording_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    if (sessionMaps.isEmpty) return null;

    final sessionMap = sessionMaps.first;
    return _buildRecordingFromMap(sessionMap);
  }

  Future<List<RecordingModel>> getUserSessions(int userId) async {
    final db = await database;
    
    final sessionMaps = await db.query(
      'recording_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    final List<RecordingModel> sessions = [];
    for (final sessionMap in sessionMaps) {
      final recording = await _buildRecordingFromMap(sessionMap);
      if (recording != null) {
        sessions.add(recording);
      }
    }

    return sessions;
  }

  Future<List<RecordingModel>> getAllSessions() async {
    final db = await database;
    
    final sessionMaps = await db.query(
      'recording_sessions',
      orderBy: 'created_at DESC',
    );

    final List<RecordingModel> sessions = [];
    for (final sessionMap in sessionMaps) {
      final recording = await _buildRecordingFromMap(sessionMap);
      if (recording != null) {
        sessions.add(recording);
      }
    }

    return sessions;
  }

  Future<RecordingModel?> _buildRecordingFromMap(Map<String, dynamic> sessionMap) async {
    final db = await database;
    final sessionId = sessionMap['id'] as int;

    // Get noise measurements
    final noiseMaps = await db.query(
      'noise_measurements',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp_offset',
    );

    final List<double> readings = [];
    for (final noiseMap in noiseMaps) {
      readings.add((noiseMap['decibel_value'] as num).toDouble());
    }

    // Get license plate detection
    final plateMaps = await db.query(
      'license_plate_detections',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );

    LicensePlateModel? licensePlate;
    if (plateMaps.isNotEmpty) {
      final plateMap = plateMaps.first;
      licensePlate = LicensePlateModel(
        id: plateMap['id'].toString(),
        plateNumber: plateMap['recognized_text'] as String?,
        rawText: plateMap['raw_text'] as String?,
        confidence: (plateMap['confidence'] as num?)?.toDouble(),
        detectedAt: DateTime.fromMillisecondsSinceEpoch(plateMap['created_at'] as int),
        isValidFormat: true, // DB에서 저장된 데이터는 검증된 것으로 간주
      );
    }

    // Build location model
    LocationModel? location;
    if (sessionMap['gps_lat'] != null && sessionMap['gps_lng'] != null) {
      location = LocationModel(
        latitude: (sessionMap['gps_lat'] as num).toDouble(),
        longitude: (sessionMap['gps_lng'] as num).toDouble(),
        address: sessionMap['location_address'] as String?,
        accuracy: 10.0, // Default accuracy
        timestamp: DateTime.fromMillisecondsSinceEpoch(sessionMap['created_at'] as int),
      );
    }

    // Build noise data model
    final startTime = DateTime.fromMillisecondsSinceEpoch(sessionMap['started_at'] as int);
    final endTime = sessionMap['ended_at'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(sessionMap['ended_at'] as int)
        : null;

    final noiseData = NoiseDataModel(
      currentDecibel: (sessionMap['average_db'] as num?)?.toDouble() ?? 0.0,
      maxDecibel: (sessionMap['high_db'] as num?)?.toDouble() ?? 0.0,
      minDecibel: (sessionMap['low_db'] as num?)?.toDouble() ?? 0.0,
      avgDecibel: (sessionMap['average_db'] as num?)?.toDouble() ?? 0.0,
      measurementCount: readings.length,
      readings: readings,
      startTime: startTime,
      endTime: endTime,
    );

    return RecordingModel(
      id: sessionMap['session_uuid'] as String,
      startTime: startTime,
      endTime: endTime,
      noiseData: noiseData,
      userId: sessionMap['user_id'].toString(),
      status: RecordingStatus.values.firstWhere(
        (s) => s.name == sessionMap['status'],
        orElse: () => RecordingStatus.completed,
      ),
      videoPath: sessionMap['video_path'] as String?,
      location: location,
      licensePlate: licensePlate,
    );
  }

  Future<void> updateSession(RecordingModel recording) async {
    final db = await database;
    
    await db.update('recording_sessions', {
      'video_path': recording.videoPath,
      'gps_lat': recording.location?.latitude,
      'gps_lng': recording.location?.longitude,
      'location_address': recording.location?.address,
      'ended_at': recording.endTime?.millisecondsSinceEpoch,
      'duration_seconds': recording.duration?.inSeconds,
      'low_db': recording.noiseData.minDecibel,
      'average_db': recording.noiseData.avgDecibel,
      'high_db': recording.noiseData.maxDecibel,
      'peak_db': recording.noiseData.maxDecibel,
      'status': recording.status.name,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, where: 'session_uuid = ?', whereArgs: [recording.id]);
  }

  Future<void> deleteSession(int sessionId) async {
    final db = await database;
    
    // Delete related noise measurements and license plate detections (CASCADE)
    await db.delete('recording_sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  // ===== REPORT METHODS =====
  
  Future<int> insertReport(ReportModel report) async {
    final db = await database;
    
    // First, insert the recording session if not exists
    int sessionId;
    final existingSessions = await db.query(
      'recording_sessions',
      where: 'session_uuid = ?',
      whereArgs: [report.recording.id],
    );
    
    if (existingSessions.isNotEmpty) {
      sessionId = existingSessions.first['id'] as int;
    } else {
      sessionId = await insertSession(report.recording);
    }

    final reportId = await db.insert('reports', {
      'session_id': sessionId,
      'title': report.title,
      'description': report.description,
      'generated_pdf_path': report.pdfPath,
      'report_type': 'noise_complaint',
      'status': report.status.name,
      'created_at': report.createdAt.millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });

    return reportId;
  }

  Future<ReportModel?> getReport(int reportId) async {
    final db = await database;
    
    final reportMaps = await db.rawQuery('''
      SELECT r.*, s.*
      FROM reports r
      INNER JOIN recording_sessions s ON r.session_id = s.id
      WHERE r.id = ?
    ''', [reportId]);

    if (reportMaps.isEmpty) return null;

    return await _buildReportFromMap(reportMaps.first);
  }

  Future<List<ReportModel>> getUserReports(int userId) async {
    final db = await database;
    
    final reportMaps = await db.rawQuery('''
      SELECT r.*, s.*
      FROM reports r
      INNER JOIN recording_sessions s ON r.session_id = s.id
      WHERE s.user_id = ?
      ORDER BY r.created_at DESC
    ''', [userId]);

    final List<ReportModel> reports = [];
    for (final reportMap in reportMaps) {
      final report = await _buildReportFromMap(reportMap);
      if (report != null) {
        reports.add(report);
      }
    }

    return reports;
  }

  Future<List<ReportModel>> getAllReports() async {
    final db = await database;
    
    final reportMaps = await db.rawQuery('''
      SELECT r.*, s.*
      FROM reports r
      INNER JOIN recording_sessions s ON r.session_id = s.id
      ORDER BY r.created_at DESC
    ''');

    final List<ReportModel> reports = [];
    for (final reportMap in reportMaps) {
      final report = await _buildReportFromMap(reportMap);
      if (report != null) {
        reports.add(report);
      }
    }

    return reports;
  }

  Future<ReportModel?> _buildReportFromMap(Map<String, dynamic> reportMap) async {
    // Build recording first
    final recording = await _buildRecordingFromMap({
      'id': reportMap['session_id'],
      'session_uuid': reportMap['session_uuid'],
      'user_id': reportMap['user_id'],
      'video_path': reportMap['video_path'],
      'gps_lat': reportMap['gps_lat'],
      'gps_lng': reportMap['gps_lng'],
      'location_address': reportMap['location_address'],
      'started_at': reportMap['started_at'],
      'ended_at': reportMap['ended_at'],
      'duration_seconds': reportMap['duration_seconds'],
      'low_db': reportMap['low_db'],
      'average_db': reportMap['average_db'],
      'high_db': reportMap['high_db'],
      'peak_db': reportMap['peak_db'],
      'status': reportMap['status'],
      'created_at': reportMap['created_at'],
      'updated_at': reportMap['updated_at'],
    });

    if (recording == null) return null;

    return ReportModel(
      id: reportMap['id'].toString(),
      title: reportMap['title'] as String,
      description: reportMap['description'] as String? ?? '',
      recording: recording,
      status: ReportStatus.values.firstWhere(
        (s) => s.name == reportMap['status'],
        orElse: () => ReportStatus.draft,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reportMap['created_at'] as int),
      userId: reportMap['user_id'].toString(),
      pdfPath: reportMap['generated_pdf_path'] as String?,
    );
  }

  Future<void> updateReport(ReportModel report) async {
    final db = await database;
    
    await db.update('reports', {
      'title': report.title,
      'description': report.description,
      'generated_pdf_path': report.pdfPath,
      'status': report.status.name,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, where: 'id = ?', whereArgs: [int.parse(report.id)]);
  }

  Future<void> deleteReport(int reportId) async {
    final db = await database;
    
    await db.delete('reports', where: 'id = ?', whereArgs: [reportId]);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}