import 'package:flutter/foundation.dart';
import '../services/enhanced_database_helper.dart';
import 'database_path_finder.dart';

class DatabaseDebug {
  static Future<void> printDatabaseInfo() async {
    if (!kDebugMode) return;
    
    try {
      final dbHelper = EnhancedDatabaseHelper.instance;
      final db = await dbHelper.database;
      
      debugPrint('=== 데이터베이스 정보 ===');
      debugPrint('경로: ${db.path}');
      debugPrint('상태: ${db.isOpen ? "열림" : "닫힘"}');
      
      // 테이블별 레코드 수 확인
      final tables = ['users', 'sessions', 'noise_logs', 'license_plates', 'reports'];
      
      for (final tableName in tables) {
        final count = await db.rawQuery("SELECT COUNT(*) as count FROM $tableName");
        final recordCount = count.first['count'];
        debugPrint('$tableName 테이블: $recordCount개 레코드');
      }
      
      debugPrint('====================');
      
      // 실제 데이터베이스 경로도 출력
      await DatabasePathFinder.printRealDatabasePath();
    } catch (e) {
      debugPrint('데이터베이스 정보 조회 실패: $e');
    }
  }
  
  static Future<void> printUserData() async {
    if (!kDebugMode) return;
    
    try {
      final dbHelper = EnhancedDatabaseHelper.instance;
      final db = await dbHelper.database;
      
      final users = await db.query('users', limit: 10);
      debugPrint('=== 사용자 데이터 ===');
      for (final user in users) {
        debugPrint('ID: ${user['id']}, 이메일: ${user['email']}');
      }
    } catch (e) {
      debugPrint('사용자 데이터 조회 실패: $e');
    }
  }
  
  static Future<void> printSessionData() async {
    if (!kDebugMode) return;
    
    try {
      final dbHelper = EnhancedDatabaseHelper.instance;
      final db = await dbHelper.database;
      
      final sessions = await db.query('sessions', limit: 5, orderBy: 'created_at DESC');
      debugPrint('=== 최근 세션 데이터 ===');
      for (final session in sessions) {
        debugPrint('ID: ${session['id']}, 상태: ${session['status']}, 데시벨: ${session['high_db']}');
      }
    } catch (e) {
      debugPrint('세션 데이터 조회 실패: $e');
    }
  }
}