import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabasePathFinder {
  static Future<void> printRealDatabasePath() async {
    try {
      // 실제 앱에서 사용하는 데이터베이스 경로
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'medivu_app.db');
      
      debugPrint('=== 실제 데이터베이스 경로 ===');
      debugPrint('데이터베이스 디렉토리: $databasesPath');
      debugPrint('데이터베이스 파일: $path');
      debugPrint('===========================');
      
      // 데이터베이스 열어서 확인
      final db = await openDatabase(path);
      final users = await db.query('users');
      debugPrint('users 테이블 레코드 수: ${users.length}');
      
      if (users.isNotEmpty) {
        debugPrint('사용자 목록:');
        for (final user in users) {
          debugPrint('- ID: ${user['id']}, 이메일: ${user['email']}');
        }
      }
      
      await db.close();
    } catch (e) {
      debugPrint('데이터베이스 경로 확인 실패: $e');
    }
  }
}