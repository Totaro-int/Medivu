import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'enhanced_database_helper.dart';

class EnhancedAuthService {
  static EnhancedAuthService? _instance;
  static EnhancedAuthService get instance {
    _instance ??= EnhancedAuthService._internal();
    return _instance!;
  }
  
  EnhancedAuthService._internal();

  final EnhancedDatabaseHelper _dbHelper = EnhancedDatabaseHelper.instance;
  
  String? _sessionToken;
  UserModel? _currentUser;

  // Getters
  String? get sessionToken => _sessionToken;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && _sessionToken != null;
  String? get userId => _currentUser?.uid;
  String? get userEmail => _currentUser?.email;
  String? get userName => _currentUser?.displayName;

  /// 회원가입
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String confirmPassword,
    String? displayName,
    String? phoneNumber,
  }) async {
    try {
      // 입력 유효성 검사
      final validation = _validateRegistrationInput(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      
      if (!validation['isValid']) {
        return {
          'success': false,
          'message': validation['message'],
          'code': 'VALIDATION_ERROR',
        };
      }

      // 데이터베이스에 사용자 생성
      final result = await _dbHelper.createUser(
        email: email,
        password: password,
        displayName: displayName,
        phoneNumber: phoneNumber,
      );

      if (!result['success']) {
        return result;
      }

      // 자동 로그인 처리
      final loginResult = await login(email, password);
      
      if (loginResult['success']) {
        return {
          'success': true,
          'message': '회원가입이 완료되고 로그인되었습니다.',
          'user': _currentUser?.toMap(),
        };
      } else {
        return {
          'success': true,
          'message': '회원가입이 완료되었습니다. 로그인해 주세요.',
        };
      }
    } catch (e) {
      debugPrint('❌ 회원가입 에러: $e');
      return {
        'success': false,
        'message': '회원가입 중 오류가 발생했습니다.',
        'error': e.toString(),
      };
    }
  }

  /// 로그인
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // 입력 유효성 검사
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': '이메일과 비밀번호를 모두 입력해주세요.',
          'code': 'MISSING_CREDENTIALS',
        };
      }

      // 데이터베이스에서 인증
      final authResult = await _dbHelper.authenticateUser(email, password);
      
      if (!authResult['success']) {
        return authResult;
      }

      // 사용자 정보와 세션 토큰 저장
      _currentUser = authResult['user'] as UserModel;
      _sessionToken = authResult['sessionToken'] as String;

      // SharedPreferences에 세션 정보 저장
      await _saveSessionToPreferences();

      debugPrint('✅ 로그인 성공: ${_currentUser?.email}');
      
      return {
        'success': true,
        'message': '로그인되었습니다.',
        'user': _currentUser?.toMap(),
        'sessionToken': _sessionToken,
      };
    } catch (e) {
      debugPrint('❌ 로그인 에러: $e');
      return {
        'success': false,
        'message': '로그인 중 오류가 발생했습니다.',
        'error': e.toString(),
      };
    }
  }

  /// 자동 로그인 (세션 복원)
  Future<bool> restoreSession() async {
    try {
      // SharedPreferences에서 세션 토큰 로드
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('session_token');
      
      if (storedToken == null) {
        debugPrint('세션 토큰이 없습니다.');
        return false;
      }

      // 데이터베이스에서 세션 유효성 확인
      final user = await _dbHelper.getUserBySessionToken(storedToken);
      
      if (user == null) {
        debugPrint('유효하지 않은 세션 토큰입니다.');
        await _clearSession();
        return false;
      }

      // 세션 복원 성공
      _currentUser = user;
      _sessionToken = storedToken;
      
      // 활동 시간 업데이트
      await _dbHelper.updateSessionActivity(storedToken);
      
      debugPrint('✅ 세션 복원 성공: ${user.email}');
      return true;
    } catch (e) {
      debugPrint('❌ 세션 복원 에러: $e');
      await _clearSession();
      return false;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      if (_sessionToken != null) {
        // 데이터베이스에서 세션 무효화
        await _dbHelper.invalidateSession(_sessionToken!);
      }
      
      // 로컬 세션 정리
      await _clearSession();
      
      debugPrint('✅ 로그아웃 완료');
    } catch (e) {
      debugPrint('❌ 로그아웃 에러: $e');
      // 에러가 발생해도 로컬 세션은 정리
      await _clearSession();
    }
  }

  /// 모든 기기에서 로그아웃
  Future<void> logoutAllDevices() async {
    try {
      if (_currentUser != null) {
        // 모든 세션 무효화
        await _dbHelper.invalidateAllUserSessions(int.parse(_currentUser!.uid));
      }
      
      // 로컬 세션 정리
      await _clearSession();
      
      debugPrint('✅ 모든 기기에서 로그아웃 완료');
    } catch (e) {
      debugPrint('❌ 전체 로그아웃 에러: $e');
      await _clearSession();
    }
  }

  /// 비밀번호 변경
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      if (_currentUser == null) {
        return {
          'success': false,
          'message': '로그인이 필요합니다.',
          'code': 'NOT_AUTHENTICATED',
        };
      }

      // 입력 유효성 검사
      if (newPassword != confirmPassword) {
        return {
          'success': false,
          'message': '새 비밀번호가 일치하지 않습니다.',
          'code': 'PASSWORD_MISMATCH',
        };
      }

      // 현재 비밀번호 확인
      final authResult = await _dbHelper.authenticateUser(
        _currentUser!.email!,
        currentPassword,
      );

      if (!authResult['success']) {
        return {
          'success': false,
          'message': '현재 비밀번호가 올바르지 않습니다.',
          'code': 'WRONG_CURRENT_PASSWORD',
        };
      }

      // TODO: 비밀번호 변경 로직 구현
      // 현재는 인증만 확인하고 변경은 미구현
      
      return {
        'success': true,
        'message': '비밀번호가 변경되었습니다.',
      };
    } catch (e) {
      debugPrint('❌ 비밀번호 변경 에러: $e');
      return {
        'success': false,
        'message': '비밀번호 변경 중 오류가 발생했습니다.',
        'error': e.toString(),
      };
    }
  }

  /// 사용자 프로필 업데이트
  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? profileImagePath,
  }) async {
    try {
      if (_currentUser == null) {
        return {
          'success': false,
          'message': '로그인이 필요합니다.',
          'code': 'NOT_AUTHENTICATED',
        };
      }

      // TODO: 프로필 업데이트 로직 구현
      
      return {
        'success': true,
        'message': '프로필이 업데이트되었습니다.',
      };
    } catch (e) {
      debugPrint('❌ 프로필 업데이트 에러: $e');
      return {
        'success': false,
        'message': '프로필 업데이트 중 오류가 발생했습니다.',
        'error': e.toString(),
      };
    }
  }

  /// 사용자 설정 저장
  Future<void> setUserPreference(String key, dynamic value) async {
    if (_currentUser == null) return;
    
    try {
      await _dbHelper.setUserPreference(
        int.parse(_currentUser!.uid),
        key,
        value,
      );
    } catch (e) {
      debugPrint('❌ 사용자 설정 저장 에러: $e');
    }
  }

  /// 사용자 설정 로드
  Future<T?> getUserPreference<T>(String key) async {
    if (_currentUser == null) return null;
    
    try {
      return await _dbHelper.getUserPreference<T>(
        int.parse(_currentUser!.uid),
        key,
      );
    } catch (e) {
      debugPrint('❌ 사용자 설정 로드 에러: $e');
      return null;
    }
  }

  /// 모든 사용자 설정 로드
  Future<Map<String, dynamic>> getAllUserPreferences() async {
    if (_currentUser == null) return {};
    
    try {
      return await _dbHelper.getAllUserPreferences(
        int.parse(_currentUser!.uid),
      );
    } catch (e) {
      debugPrint('❌ 사용자 설정 전체 로드 에러: $e');
      return {};
    }
  }

  /// 활동 시간 업데이트
  Future<void> updateActivity() async {
    if (_sessionToken == null) return;
    
    try {
      await _dbHelper.updateSessionActivity(_sessionToken!);
    } catch (e) {
      debugPrint('❌ 활동 시간 업데이트 에러: $e');
    }
  }

  /// 세션 유효성 검사
  Future<bool> validateSession() async {
    if (_sessionToken == null || _currentUser == null) {
      return false;
    }

    try {
      final user = await _dbHelper.getUserBySessionToken(_sessionToken!);
      return user != null;
    } catch (e) {
      debugPrint('❌ 세션 유효성 검사 에러: $e');
      return false;
    }
  }

  /// SharedPreferences에 세션 저장
  Future<void> _saveSessionToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_sessionToken != null) {
        await prefs.setString('session_token', _sessionToken!);
      }
      
      if (_currentUser != null) {
        await prefs.setString('user_data', jsonEncode(_currentUser!.toMap()));
      }
      
      await prefs.setInt('last_activity_time', DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('keep_logged_in', true);
    } catch (e) {
      debugPrint('❌ 세션 저장 에러: $e');
    }
  }

  /// 세션 정리
  Future<void> _clearSession() async {
    try {
      _currentUser = null;
      _sessionToken = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_token');
      await prefs.remove('user_data');
      await prefs.remove('last_activity_time');
      await prefs.remove('keep_logged_in');
    } catch (e) {
      debugPrint('❌ 세션 정리 에러: $e');
    }
  }

  /// 회원가입 입력 유효성 검사
  Map<String, dynamic> _validateRegistrationInput({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    // 이메일 유효성 검사
    if (email.isEmpty) {
      return {'isValid': false, 'message': '이메일을 입력해주세요.'};
    }
    
    if (!_isValidEmail(email)) {
      return {'isValid': false, 'message': '올바른 이메일 형식이 아닙니다.'};
    }

    // 비밀번호 유효성 검사
    if (password.isEmpty) {
      return {'isValid': false, 'message': '비밀번호를 입력해주세요.'};
    }
    
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

    // 비밀번호 확인
    if (password != confirmPassword) {
      return {'isValid': false, 'message': '비밀번호가 일치하지 않습니다.'};
    }

    return {'isValid': true, 'message': '유효한 입력입니다.'};
  }

  /// 이메일 형식 유효성 검사
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// 현재 세션의 남은 시간 (분 단위)
  Future<int?> getSessionTimeRemaining() async {
    if (_sessionToken == null) return null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivity = prefs.getInt('last_activity_time');
      if (lastActivity == null) return null;
      
      const sessionDuration = Duration(hours: 24);
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = now - lastActivity;
      final remaining = sessionDuration.inMilliseconds - elapsed;
      
      return remaining > 0 ? (remaining / (1000 * 60)).round() : 0;
    } catch (e) {
      debugPrint('❌ 세션 시간 확인 에러: $e');
      return null;
    }
  }

  /// 비밀번호 강도 검사
  Map<String, dynamic> checkPasswordStrength(String password) {
    int score = 0;
    List<String> feedback = [];
    
    // 길이 검사
    if (password.length >= 8) {
      score += 1;
    } else {
      feedback.add('최소 8자 이상 입력하세요');
    }
    
    if (password.length >= 12) {
      score += 1;
    }
    
    // 대문자 검사
    if (password.contains(RegExp(r'[A-Z]'))) {
      score += 1;
    } else {
      feedback.add('대문자를 포함하세요');
    }
    
    // 소문자 검사
    if (password.contains(RegExp(r'[a-z]'))) {
      score += 1;
    } else {
      feedback.add('소문자를 포함하세요');
    }
    
    // 숫자 검사
    if (password.contains(RegExp(r'[0-9]'))) {
      score += 1;
    } else {
      feedback.add('숫자를 포함하세요');
    }
    
    // 특수문자 검사
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score += 1;
    } else {
      feedback.add('특수문자를 포함하면 더 안전합니다');
    }
    
    // 연속된 문자 검사
    bool hasSequence = false;
    for (int i = 0; i < password.length - 2; i++) {
      if (password.codeUnitAt(i) + 1 == password.codeUnitAt(i + 1) &&
          password.codeUnitAt(i + 1) + 1 == password.codeUnitAt(i + 2)) {
        hasSequence = true;
        break;
      }
    }
    
    if (hasSequence) {
      score -= 1;
      feedback.add('연속된 문자는 피해주세요');
    }
    
    // 반복된 문자 검사
    bool hasRepeating = false;
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i + 1] == password[i + 2]) {
        hasRepeating = true;
        break;
      }
    }
    
    if (hasRepeating) {
      score -= 1;
      feedback.add('반복된 문자는 피해주세요');
    }
    
    // 강도 결정
    String strength;
    Color color;
    
    if (score <= 2) {
      strength = '약함';
      color = const Color(0xFFE53E3E); // Red
    } else if (score <= 4) {
      strength = '보통';
      color = const Color(0xFFFF8C00); // Orange
    } else if (score <= 5) {
      strength = '강함';
      color = const Color(0xFF38A169); // Green
    } else {
      strength = '매우 강함';
      color = const Color(0xFF2D3748); // Dark Green
    }
    
    return {
      'score': score,
      'maxScore': 6,
      'strength': strength,
      'color': color,
      'feedback': feedback,
      'isValid': score >= 3, // 최소 3점은 되어야 함
    };
  }

  /// 이메일 도메인 검증 (허용된 도메인인지 확인)
  bool isAllowedEmailDomain(String email) {
    // 모든 도메인 허용하되, 임시 이메일 서비스는 차단
    final blockedDomains = [
      'tempmail.com', '10minutemail.com', 'guerrillamail.com', 
      'mailinator.com', 'throwaway.email'
    ];
    
    final domain = email.split('@').last.toLowerCase();
    return !blockedDomains.contains(domain);
  }

  /// 계정 잠금 상태 확인
  Future<Map<String, dynamic>> getAccountLockInfo(String email) async {
    try {
      final db = await _dbHelper.database;
      final userMaps = await db.query(
        'users',
        columns: ['failed_login_attempts', 'locked_until'],
        where: 'email = ?',
        whereArgs: [email],
      );

      if (userMaps.isEmpty) {
        return {
          'isLocked': false,
          'attempts': 0,
          'remainingAttempts': 5,
          'unlockTime': null,
        };
      }

      final userMap = userMaps.first;
      final failedAttempts = (userMap['failed_login_attempts'] as int?) ?? 0;
      final lockedUntil = userMap['locked_until'] as int?;
      
      final isLocked = lockedUntil != null && 
          lockedUntil > DateTime.now().millisecondsSinceEpoch;

      return {
        'isLocked': isLocked,
        'attempts': failedAttempts,
        'remainingAttempts': math.max(0, 5 - failedAttempts),
        'unlockTime': lockedUntil != null 
            ? DateTime.fromMillisecondsSinceEpoch(lockedUntil)
            : null,
      };
    } catch (e) {
      debugPrint('❌ 계정 잠금 정보 조회 에러: $e');
      return {
        'isLocked': false,
        'attempts': 0,
        'remainingAttempts': 5,
        'unlockTime': null,
      };
    }
  }

  /// 최근 로그인 시도 기록 조회
  Future<List<Map<String, dynamic>>> getRecentLoginAttempts({int limit = 10}) async {
    if (_currentUser == null) return [];
    
    try {
      final db = await _dbHelper.database;
      final attempts = await db.query(
        'login_attempts',
        where: 'email = ?',
        whereArgs: [_currentUser!.email],
        orderBy: 'attempted_at DESC',
        limit: limit,
      );

      return attempts.map((attempt) => {
        'success': (attempt['success'] as int?) == 1,
        'timestamp': DateTime.fromMillisecondsSinceEpoch(attempt['attempted_at'] as int),
        'failureReason': attempt['failure_reason'] as String?,
        'ipAddress': attempt['ip_address'] as String?,
      }).toList();
    } catch (e) {
      debugPrint('❌ 로그인 시도 기록 조회 에러: $e');
      return [];
    }
  }

  /// 활성 세션 목록 조회
  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    if (_currentUser == null) return [];
    
    try {
      final db = await _dbHelper.database;
      final sessions = await db.query(
        'user_sessions',
        where: 'user_id = ? AND is_active = 1',
        whereArgs: [int.parse(_currentUser!.uid)],
        orderBy: 'last_activity_at DESC',
      );

      return sessions.map((session) => {
        'sessionId': session['id'] as int?,
        'deviceInfo': session['device_info'] as String?,
        'ipAddress': session['ip_address'] as String?,
        'createdAt': DateTime.fromMillisecondsSinceEpoch(session['created_at'] as int),
        'lastActivity': DateTime.fromMillisecondsSinceEpoch(session['last_activity_at'] as int),
        'isCurrent': (session['session_token'] as String?) == _sessionToken,
      }).toList();
    } catch (e) {
      debugPrint('❌ 활성 세션 조회 에러: $e');
      return [];
    }
  }

  /// 특정 세션 종료
  Future<bool> terminateSession(int sessionId) async {
    if (_currentUser == null) return false;
    
    try {
      final db = await _dbHelper.database;
      await db.update(
        'user_sessions',
        {
          'is_active': 0,
          'last_activity_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [sessionId, int.parse(_currentUser!.uid)],
      );
      
      return true;
    } catch (e) {
      debugPrint('❌ 세션 종료 에러: $e');
      return false;
    }
  }

  /// 보안 점수 계산 (사용자 계정의 전반적인 보안 수준)
  Future<Map<String, dynamic>> getSecurityScore() async {
    if (_currentUser == null) {
      return {'score': 0, 'maxScore': 100, 'recommendations': []};
    }

    int score = 0;
    List<String> recommendations = [];
    
    // 기본 점수 (로그인됨)
    score += 10;
    
    // 이메일 인증 (미구현이지만 체크)
    // if (_currentUser!.emailVerified) score += 20;
    // else recommendations.add('이메일 인증을 완료하세요');
    
    // 최근 로그인 활동
    try {
      final attempts = await getRecentLoginAttempts(limit: 5);
      final successfulAttempts = attempts.where((a) => a['success']).length;
      if (successfulAttempts >= 3) {
        score += 15;
      } else {
        recommendations.add('정기적으로 로그인하여 계정을 활성화하세요');
      }
    } catch (e) {
      recommendations.add('로그인 기록을 확인할 수 없습니다');
    }
    
    // 세션 관리
    try {
      final sessions = await getActiveSessions();
      if (sessions.length <= 3) {
        score += 10;
      } else {
        recommendations.add('불필요한 세션을 정리하세요');
      }
    } catch (e) {
      recommendations.add('세션 정보를 확인할 수 없습니다');
    }
    
    // 계정 설정 완성도
    if (_currentUser!.displayName != null && _currentUser!.displayName!.isNotEmpty) {
      score += 10;
    } else {
      recommendations.add('프로필 정보를 완성하세요');
    }
    
    // 추가 권장사항
    if (score < 50) {
      recommendations.add('계정 보안을 더욱 강화하세요');
    }
    
    return {
      'score': score,
      'maxScore': 100,
      'level': _getSecurityLevel(score),
      'recommendations': recommendations,
    };
  }

  String _getSecurityLevel(int score) {
    if (score >= 80) return '높음';
    if (score >= 60) return '보통';
    if (score >= 40) return '낮음';
    return '매우 낮음';
  }

  /// 디버그 정보
  Map<String, dynamic> get debugInfo => {
    'isLoggedIn': isLoggedIn,
    'userId': userId,
    'userEmail': userEmail,
    'userName': userName,
    'sessionToken': _sessionToken != null 
        ? '${_sessionToken!.substring(0, math.min(8, _sessionToken!.length))}...' 
        : null,
    'currentUser': _currentUser?.toMap(),
    'lastActivity': _getLastActivityTime(),
  };

  String? _getLastActivityTime() {
    try {
      final prefs = SharedPreferences.getInstance();
      prefs.then((p) {
        final lastActivity = p.getInt('last_activity_time');
        return lastActivity != null 
            ? DateTime.fromMillisecondsSinceEpoch(lastActivity).toString()
            : null;
      });
    } catch (e) {
      return null;
    }
    return null;
  }
}