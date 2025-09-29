import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:noise0/services/database_helper.dart';

void main() {
  group('Database Location Tests', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    test('데이터베이스 파일 위치 확인', () async {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      
      // 데이터베이스 경로 출력
      print('=== 데이터베이스 정보 ===');
      print('데이터베이스 경로: ${db.path}');
      print('데이터베이스 버전: ${await db.getVersion()}');
      print('데이터베이스 열림 상태: ${db.isOpen}');
      
      // 데이터베이스 경로를 파일명으로 분리
      final dbPath = db.path;
      final directory = dirname(dbPath);
      final fileName = basename(dbPath);
      
      print('디렉토리: $directory');
      print('파일명: $fileName');
      
      // 테이블 목록 확인
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
      );
      
      print('\n=== 테이블 목록 ===');
      for (final table in tables) {
        final tableName = table['name'] as String;
        print('테이블: $tableName');
        
        // 각 테이블의 스키마 확인
        final schema = await db.rawQuery("PRAGMA table_info($tableName)");
        print('  컬럼:');
        for (final column in schema) {
          print('    - ${column['name']} (${column['type']})');
        }
        
        // 각 테이블의 레코드 수 확인
        final count = await db.rawQuery("SELECT COUNT(*) as count FROM $tableName");
        final recordCount = count.first['count'];
        print('  레코드 수: $recordCount');
        print('');
      }
      
      expect(db.isOpen, true);
      expect(tables.length, greaterThan(0));
    });

    test('데이터베이스 내용 샘플 조회', () async {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      
      // 사용자 테이블 샘플 데이터 조회
      final users = await db.query('users', limit: 5);
      print('=== 사용자 테이블 샘플 ===');
      for (final user in users) {
        print('ID: ${user['id']}, 이메일: ${user['email']}, 생성일: ${DateTime.fromMillisecondsSinceEpoch(user['created_at'] as int)}');
      }
      
      // 세션 테이블 샘플 데이터 조회
      final sessions = await db.query('sessions', limit: 5, orderBy: 'created_at DESC');
      print('\n=== 세션 테이블 샘플 ===');
      for (final session in sessions) {
        print('ID: ${session['id']}, 사용자ID: ${session['user_id']}, 상태: ${session['status']}, 생성일: ${DateTime.fromMillisecondsSinceEpoch(session['created_at'] as int)}');
      }
      
      // 소음 로그 테이블 샘플 데이터 조회
      final noiseLogs = await db.query('noise_logs', limit: 10, orderBy: 'recorded_at DESC');
      print('\n=== 소음 로그 테이블 샘플 ===');
      for (final log in noiseLogs) {
        print('세션ID: ${log['session_id']}, 데시벨: ${log['decibel_value']}, 시간오프셋: ${log['timestamp_offset']}');
      }
    });
  });
}