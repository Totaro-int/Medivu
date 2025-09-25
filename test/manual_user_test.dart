import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:actfinder/services/local_database_service.dart';
import 'package:actfinder/providers/auth_provider.dart';

void main() {
  group('Manual User Test', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    test('수동으로 사용자 생성 테스트', () async {
      final authProvider = AuthProvider.instance;
      
      // 회원가입 테스트
      print('회원가입 시작...');
      final success = await authProvider.register(
        email: 'manual_test@example.com',
        password: 'password123',
        name: 'Manual Test User',
      );
      
      expect(success, true);
      expect(authProvider.isLoggedIn, true);
      expect(authProvider.userEmail, 'manual_test@example.com');
      
      print('회원가입 성공!');
      print('사용자 ID: ${authProvider.userId}');
      print('사용자 이메일: ${authProvider.userEmail}');
      
      // 데이터베이스에서 직접 확인
      final dbService = LocalDatabaseService.instance;
      final recordings = await dbService.getUserRecordings(authProvider.userId!);
      print('사용자 녹화 기록: ${recordings.length}개');
    });
  });
}