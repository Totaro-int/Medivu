import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:medivu_app/providers/auth_provider.dart';
import 'package:medivu_app/services/local_database_service.dart';

void main() {
  group('Authentication Validation Tests', () {
    late AuthProvider authProvider;
    late LocalDatabaseService dbService;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      authProvider = AuthProvider.instance;
      dbService = LocalDatabaseService.instance;
    });

    test('존재하지 않는 사용자 로그인 차단 테스트', () async {
      // 로그아웃 상태에서 시작
      await authProvider.logout();
      expect(authProvider.isLoggedIn, false);
      
      // 존재하지 않는 사용자로 로그인 시도
      final loginResult = await authProvider.login('nonexistent@test.com', 'password123');
      
      expect(loginResult, false);
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.error?.contains('존재하지 않는 사용자'), true);
      
      print('✅ 존재하지 않는 사용자 로그인 차단됨');
      print('에러 메시지: ${authProvider.error}');
    });

    test('회원가입 후 로그인 성공 테스트', () async {
      const testEmail = 'registered@test.com';
      const testPassword = 'password123';
      const testName = 'Test User';
      
      // 1. 회원가입
      await authProvider.logout();
      final registerResult = await authProvider.register(
        email: testEmail,
        password: testPassword,
        name: testName,
      );
      
      expect(registerResult, true);
      expect(authProvider.isLoggedIn, true);
      expect(authProvider.userEmail, testEmail);
      
      print('✅ 회원가입 성공: $testEmail');
      
      // 2. 로그아웃
      await authProvider.logout();
      expect(authProvider.isLoggedIn, false);
      
      // 3. 방금 가입한 계정으로 로그인
      final loginResult = await authProvider.login(testEmail, testPassword);
      
      expect(loginResult, true);
      expect(authProvider.isLoggedIn, true);
      expect(authProvider.userEmail, testEmail);
      expect(authProvider.error, null);
      
      print('✅ 기존 사용자 로그인 성공: $testEmail');
    });

    test('빈 입력값 검증 테스트', () async {
      await authProvider.logout();
      
      // 빈 이메일
      final emptyEmailResult = await authProvider.login('', 'password123');
      expect(emptyEmailResult, false);
      expect(authProvider.error?.contains('이메일과 비밀번호를 입력'), true);
      
      // 빈 비밀번호
      final emptyPasswordResult = await authProvider.login('test@test.com', '');
      expect(emptyPasswordResult, false);
      expect(authProvider.error?.contains('이메일과 비밀번호를 입력'), true);
      
      print('✅ 빈 입력값 검증 완료');
    });

    tearDown(() async {
      await authProvider.logout();
      await dbService.clearAllData();
    });
  });
}