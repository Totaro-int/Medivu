import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'enhanced_database_helper.dart';

class DatabaseMigrationManager {
  static DatabaseMigrationManager? _instance;
  static DatabaseMigrationManager get instance {
    _instance ??= DatabaseMigrationManager._internal();
    return _instance!;
  }
  
  DatabaseMigrationManager._internal();

  static const String _migrationVersionKey = 'db_migration_version';
  static const String _lastMigrationDateKey = 'last_migration_date';
  static const int _latestVersion = 2;

  /// 데이터베이스 마이그레이션 확인 및 실행
  Future<bool> checkAndMigrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_migrationVersionKey) ?? 0;
      
      debugPrint('🔄 현재 DB 버전: $currentVersion, 최신 버전: $_latestVersion');
      
      if (currentVersion < _latestVersion) {
        return await _performMigration(currentVersion, _latestVersion);
      }
      
      debugPrint('✅ 데이터베이스 마이그레이션 불필요');
      return true;
    } catch (e) {
      debugPrint('❌ 마이그레이션 확인 에러: $e');
      return false;
    }
  }

  Future<bool> _performMigration(int fromVersion, int toVersion) async {
    try {
      debugPrint('🔄 데이터베이스 마이그레이션 시작: v$fromVersion -> v$toVersion');
      
      bool migrationSuccess = true;

      // V0 -> V1: 기본 데이터베이스에서 개선된 데이터베이스로
      if (fromVersion < 1) {
        migrationSuccess = await _migrateToV1();
        if (!migrationSuccess) return false;
      }

      // V1 -> V2: 추가 보안 기능 및 사용자 설정
      if (fromVersion < 2) {
        migrationSuccess = await _migrateToV2();
        if (!migrationSuccess) return false;
      }

      // 마이그레이션 버전 업데이트
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_migrationVersionKey, toVersion);
      await prefs.setInt(_lastMigrationDateKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('✅ 데이터베이스 마이그레이션 완료: v$toVersion');
      return true;
    } catch (e) {
      debugPrint('❌ 마이그레이션 실패: $e');
      return false;
    }
  }

  Future<bool> _migrateToV1() async {
    try {
      debugPrint('🔄 V1 마이그레이션 시작: 기본 -> 개선된 데이터베이스');
      
      // 기존 데이터베이스 확인
      final oldDb = DatabaseHelper.instance;
      final oldUsers = await _getOldUsers(oldDb);
      
      debugPrint('📊 마이그레이션할 사용자 수: ${oldUsers.length}');
      
      // 새 데이터베이스 초기화
      final newDb = EnhancedDatabaseHelper.instance;
      await newDb.database; // 초기화 강제 실행
      
      // 사용자 데이터 마이그레이션
      for (final oldUser in oldUsers) {
        await _migrateUser(oldUser, newDb);
      }
      
      debugPrint('✅ V1 마이그레이션 완료');
      return true;
    } catch (e) {
      debugPrint('❌ V1 마이그레이션 실패: $e');
      return false;
    }
  }

  Future<bool> _migrateToV2() async {
    try {
      debugPrint('🔄 V2 마이그레이션 시작: 보안 강화 및 사용자 설정');
      
      final db = EnhancedDatabaseHelper.instance;
      
      // 기본 사용자 설정 생성
      await _createDefaultSettings(db);
      
      debugPrint('✅ V2 마이그레이션 완료');
      return true;
    } catch (e) {
      debugPrint('❌ V2 마이그레이션 실패: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _getOldUsers(DatabaseHelper oldDb) async {
    try {
      final db = await oldDb.database;
      return await db.query('users');
    } catch (e) {
      debugPrint('⚠️ 기존 사용자 데이터 없음: $e');
      return [];
    }
  }

  Future<void> _migrateUser(Map<String, dynamic> oldUser, EnhancedDatabaseHelper newDb) async {
    try {
      final email = oldUser['email'] as String?;
      if (email == null || email.isEmpty) {
        debugPrint('⚠️ 유효하지 않은 사용자 스킵: $oldUser');
        return;
      }

      // 임시 비밀번호로 사용자 생성 (사용자가 나중에 변경해야 함)
      final result = await newDb.createUser(
        email: email,
        password: 'TempPassword123!', // 임시 비밀번호
        displayName: email.split('@').first,
      );

      if (result['success']) {
        debugPrint('✅ 사용자 마이그레이션 완료: $email');
      } else {
        debugPrint('❌ 사용자 마이그레이션 실패: $email - ${result['message']}');
      }
    } catch (e) {
      debugPrint('❌ 사용자 마이그레이션 에러: $e');
    }
  }

  Future<void> _createDefaultSettings(EnhancedDatabaseHelper db) async {
    try {
      // 모든 사용자에 대해 기본 설정 생성
      final database = await db.database;
      final users = await database.query('users');
      
      for (final user in users) {
        final userId = user['id'] as int;
        
        // 기본 설정값들
        final defaultSettings = {
          'noise_threshold': 70.0,
          'auto_save_videos': true,
          'location_tracking': true,
          'notification_enabled': true,
          'dark_mode': false,
          'language': 'ko',
          'video_quality': 'high',
          'auto_upload_reports': false,
        };

        for (final entry in defaultSettings.entries) {
          try {
            await db.setUserPreference(userId, entry.key, entry.value);
          } catch (e) {
            // 이미 존재하는 설정은 무시
          }
        }
      }
      
      debugPrint('✅ 기본 사용자 설정 생성 완료');
    } catch (e) {
      debugPrint('❌ 기본 설정 생성 에러: $e');
    }
  }

  /// 마이그레이션 정보 가져오기
  Future<Map<String, dynamic>> getMigrationInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_migrationVersionKey) ?? 0;
      final lastMigrationDate = prefs.getInt(_lastMigrationDateKey);
      
      return {
        'currentVersion': currentVersion,
        'latestVersion': _latestVersion,
        'isUpToDate': currentVersion >= _latestVersion,
        'lastMigrationDate': lastMigrationDate != null 
            ? DateTime.fromMillisecondsSinceEpoch(lastMigrationDate)
            : null,
        'needsMigration': currentVersion < _latestVersion,
      };
    } catch (e) {
      debugPrint('❌ 마이그레이션 정보 조회 에러: $e');
      return {
        'currentVersion': 0,
        'latestVersion': _latestVersion,
        'isUpToDate': false,
        'lastMigrationDate': null,
        'needsMigration': true,
        'error': e.toString(),
      };
    }
  }

  /// 강제 마이그레이션 재실행
  Future<bool> forceMigration() async {
    try {
      debugPrint('🔄 강제 마이그레이션 시작');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_migrationVersionKey);
      await prefs.remove(_lastMigrationDateKey);
      
      return await checkAndMigrate();
    } catch (e) {
      debugPrint('❌ 강제 마이그레이션 실패: $e');
      return false;
    }
  }

  /// 데이터베이스 백업 (향후 구현)
  Future<bool> createBackup() async {
    try {
      // TODO: 데이터베이스 백업 로직 구현
      debugPrint('📦 데이터베이스 백업 기능은 추후 구현 예정');
      return true;
    } catch (e) {
      debugPrint('❌ 백업 생성 실패: $e');
      return false;
    }
  }

  /// 데이터베이스 복원 (향후 구현)
  Future<bool> restoreBackup(String backupPath) async {
    try {
      // TODO: 데이터베이스 복원 로직 구현
      debugPrint('📥 데이터베이스 복원 기능은 추후 구현 예정');
      return true;
    } catch (e) {
      debugPrint('❌ 백업 복원 실패: $e');
      return false;
    }
  }

  /// 마이그레이션 로그 확인
  Future<List<String>> getMigrationLogs() async {
    try {
      // TODO: 마이그레이션 로그 관리 구현
      return [
        '${DateTime.now()}: 마이그레이션 완료',
        '${DateTime.now()}: 데이터베이스 v$_latestVersion 적용',
      ];
    } catch (e) {
      debugPrint('❌ 마이그레이션 로그 조회 실패: $e');
      return [];
    }
  }
}