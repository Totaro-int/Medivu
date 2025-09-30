import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabasePathFinder {
  static Future<void> printRealDatabasePath() async {
    try {
      // 실제 앱에서 사용하는 데이터베이스 경로
      final databasesPath = await getDatabasesPath();
      final enhancedPath = join(databasesPath, 'medivu_app_enhanced_v3.db');
      final oldPath = join(databasesPath, 'medivu_app.db');

      debugPrint('=== 실제 데이터베이스 경로 ===');
      debugPrint('데이터베이스 디렉토리: $databasesPath');
      debugPrint('Enhanced DB 파일: $enhancedPath');
      debugPrint('Old DB 파일: $oldPath');
      debugPrint('===========================');

      // Enhanced 데이터베이스 확인
      try {
        final enhancedDb = await openDatabase(enhancedPath);
        final users = await enhancedDb.query('users');
        debugPrint('Enhanced DB users 테이블 레코드 수: ${users.length}');

        if (users.isNotEmpty) {
          debugPrint('Enhanced DB 사용자 목록:');
          for (final user in users) {
            debugPrint('- ID: ${user['id']}, 이메일: ${user['email']}');
          }
        }

        await enhancedDb.close();
      } catch (e) {
        debugPrint('Enhanced 데이터베이스 확인 실패: $e');
      }

    } catch (e) {
      debugPrint('데이터베이스 경로 확인 실패: $e');
    }
  }
}