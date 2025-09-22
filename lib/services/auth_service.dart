import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../core/constants/app_exception.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _token;
  Map<String, dynamic>? _user;

  /// 현재 토큰 반환
  String? get token => _token;
  
  /// 현재 사용자 정보 반환
  Map<String, dynamic>? get user => _user;
  
  /// 로그인 상태 확인
  bool get isLoggedIn => _token != null;

  /// 로그인
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.loginEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _user = data['user'];
        
        // 로그인 성공 시 자동으로 저장
        await saveAuthData();
        
        return {
          'success': true,
          'message': '로그인 성공',
          'data': data,
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? '로그인 실패',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다.',
        'error': e.toString(),
      };
    }
  }

  /// 회원가입
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required bool agreeToTerms,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.registerEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
          'name': name,
          'agreeToTerms': agreeToTerms,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': '회원가입 성공',
          'data': data,
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? '회원가입 실패',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다.',
        'error': e.toString(),
      };
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      if (_token != null) {
        await http.post(
          Uri.parse('${AppConstants.baseUrl}/auth/logout'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (e) {
      // 로그아웃 실패해도 로컬에서 토큰 제거
    } finally {
      _token = null;
      _user = null;
      
      // 로컬 저장소에서 인증 정보 삭제
      await clearStoredAuth();
    }
  }


  /// 사용자 정보 업데이트
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/auth/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = data['user'];
        return {
          'success': true,
          'message': '프로필 업데이트 성공',
          'data': data,
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? '프로필 업데이트 실패',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다.',
        'error': e.toString(),
      };
    }
  }

  /// 비밀번호 변경
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/auth/password'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': '비밀번호 변경 성공',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? '비밀번호 변경 실패',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다.',
        'error': e.toString(),
      };
    }
  }

  /// 사용자 정보 수동 설정 (AuthProvider에서 사용)
  Future<void> setUser(Map<String, dynamic> userData) async {
    _user = userData;
    await saveAuthData();
  }

  /// 토큰 수동 설정
  Future<void> setToken(String token) async {
    _token = token;
    await saveAuthData();
  }

  /// 저장된 인증 정보 로드
  Future<void> loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      final userJson = prefs.getString('user_data');
      final lastLoginTime = prefs.getInt('last_login_time');
      
      if (userJson != null) {
        _user = json.decode(userJson);
      }
      
      // 7일 이상 지난 토큰은 자동 삭제
      if (lastLoginTime != null && _token != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final daysPassed = (now - lastLoginTime) / (1000 * 60 * 60 * 24);
        
        if (daysPassed > 7) {
          await clearStoredAuth();
          _token = null;
          _user = null;
        }
      }
    } catch (e) {
      throw AppExceptionHandler.fromException(e);
    }
  }

  /// 인증 정보 저장
  Future<void> saveAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString('auth_token', _token!);
        await prefs.setInt('last_login_time', DateTime.now().millisecondsSinceEpoch);
      }
      if (_user != null) {
        await prefs.setString('user_data', json.encode(_user!));
      }
      
      // 세션 유지 설정 저장
      await prefs.setBool('keep_logged_in', true);
      await prefs.setInt('last_activity_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      throw AppExceptionHandler.fromException(e);
    }
  }

  /// 저장된 인증 정보 삭제
  Future<void> clearStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      await prefs.remove('last_login_time');
      await prefs.remove('last_activity_time');
      await prefs.remove('keep_logged_in');
    } catch (e) {
      throw AppExceptionHandler.fromException(e);
    }
  }

  /// 자동 로그인 가능 여부 확인
  Future<bool> hasStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userData = prefs.getString('user_data');
      return token != null && userData != null;
    } catch (e) {
      return false;
    }
  }

  /// 토큰 유효성 검사 (서버 확인)
  Future<bool> validateToken() async {
    if (_token == null) return false;
    
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/auth/validate'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 활동 시간 업데이트
  Future<void> updateActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_activity_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // 활동 시간 업데이트 실패는 무시
    }
  }

  /// 세션 만료 확인 (24시간 비활성 시)
  Future<bool> isSessionExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivity = prefs.getInt('last_activity_time');
      
      if (lastActivity == null) return true;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursPassed = (now - lastActivity) / (1000 * 60 * 60);
      
      return hoursPassed > 24; // 24시간 후 세션 만료
    } catch (e) {
      return true;
    }
  }

  /// 자동 로그인 설정 확인
  Future<bool> shouldKeepLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('keep_logged_in') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 앱 시작 시 세션 복원
  Future<bool> restoreSession() async {
    try {
      if (!await shouldKeepLoggedIn()) {
        return false;
      }

      if (await isSessionExpired()) {
        await clearStoredAuth();
        return false;
      }

      await loadStoredAuth();
      await updateActivity();
      
      return _token != null && _user != null;
    } catch (e) {
      await clearStoredAuth();
      return false;
    }
  }
}
