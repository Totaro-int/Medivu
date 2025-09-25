import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/enhanced_database_helper.dart';

class AuthProvider extends ChangeNotifier {
  static AuthProvider? _instance;
  
  AuthProvider._internal();
  
  static AuthProvider get instance {
    _instance ??= AuthProvider._internal();
    return _instance!;
  }

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  String? get userId => _currentUser?.uid;
  String? get userEmail => _currentUser?.email;
  String? get userName => _currentUser?.displayName;

  /// 초기화 - 저장된 로그인 정보 확인 및 자동 로그인
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final authService = AuthService();
      
      // 세션 복원 시도
      final sessionRestored = await authService.restoreSession();
      
      if (sessionRestored) {
        final userData = authService.user;
        
        if (userData != null) {
          // UserModel로 변환하여 저장
          _currentUser = UserModel.fromMap(userData);
          
          // 활동 시간 업데이트
          await authService.updateActivity();
          
          print('세션 복원 성공: ${_currentUser?.email}');
          print('마지막 로그인: ${DateTime.fromMillisecondsSinceEpoch(_currentUser?.updatedAt?.millisecondsSinceEpoch ?? 0)}');
        } else {
          print('세션 복원 실패: 사용자 데이터 없음');
        }
      } else {
        print('세션 복원 실패 - 새로운 로그인 필요');
        // 만료된 세션 정리는 이미 restoreSession에서 처리됨
      }
      
      _clearError();
    } catch (e) {
      print('초기화 실패: $e');
      
      // 오류 발생 시 저장된 인증 정보 삭제
      try {
        final authService = AuthService();
        await authService.clearStoredAuth();
      } catch (_) {
        // 삭제 실패 무시
      }
      
      _setError('초기화 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 로그인
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final authService = AuthService();
      
      // 입력값 검증
      if (email.isEmpty || password.isEmpty) {
        _setError('이메일과 비밀번호를 입력해주세요');
        return false;
      }
      
      // 데이터베이스에서 기존 사용자 조회 (없으면 null)
      final existingUser = await EnhancedDatabaseHelper.instance.getUserByEmail(email);
      
      if (existingUser == null) {
        _setError('존재하지 않는 사용자입니다. 회원가입을 먼저 진행해주세요.');
        return false;
      }
      
      // TODO: 실제 비밀번호 검증 로직 추가
      // 현재는 임시로 모든 비밀번호 허용
      
      _currentUser = existingUser;
      
      // AuthService에 사용자 정보 저장 (자동으로 SharedPreferences에도 저장됨)
      await authService.setUser(_currentUser!.toMap());
      
      // 임시 토큰 생성 및 저장 (향후 실제 JWT 토큰으로 대체)
      await authService.setToken('local_token_${_currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}');
      
      print('로그인 성공 및 인증 정보 저장: ${_currentUser?.email}');
      
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('로그인 실패: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    _setLoading(true);
    try {
      final authService = AuthService();
      await authService.logout();
      
      _currentUser = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('로그아웃 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 회원가입
  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    try {
      // TODO: 실제 회원가입 API 연동
      
      // 데이터베이스에서 사용자 생성
      final result = await EnhancedDatabaseHelper.instance.createUser(
        email: email,
        password: password,
        displayName: name,
      );
      
      if (result['success']) {
        final userId = result['userId'] as int;
        _currentUser = await EnhancedDatabaseHelper.instance.getUser(userId);
      } else {
        throw Exception(result['message']);
      }
      
      // AuthService에 사용자 정보 저장 (자동으로 SharedPreferences에도 저장됨)
      final authService = AuthService();
      await authService.setUser(_currentUser!.toMap());
      
      // 임시 토큰 생성 및 저장 (향후 실제 JWT 토큰으로 대체)
      await authService.setToken('local_token_${_currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}');
      
      print('회원가입 성공 및 인증 정보 저장: ${_currentUser?.email}');
      
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('회원가입 실패: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 사용자 정보 업데이트
  Future<bool> updateUser({
    String? name,
    String? email,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentUser == null) {
      _setError('로그인된 사용자가 없습니다');
      return false;
    }

    _setLoading(true);
    try {
      _currentUser = _currentUser!.copyWith(
        displayName: name,
        email: email,
        updatedAt: DateTime.now(),
      );
      
      // AuthService에도 저장
      final authService = AuthService();
      await authService.setUser(_currentUser!.toMap());
      
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('사용자 정보 업데이트 실패: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 비밀번호 변경
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      _setError('로그인된 사용자가 없습니다');
      return false;
    }

    _setLoading(true);
    try {
      // TODO: 실제 비밀번호 변경 API 연동
      
      // 임시로 성공 처리
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('비밀번호 변경 실패: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 비밀번호 재설정 요청
  Future<bool> requestPasswordReset(String email) async {
    _setLoading(true);
    try {
      // TODO: 실제 비밀번호 재설정 API 연동
      
      // 임시로 성공 처리
      _clearError();
      return true;
    } catch (e) {
      _setError('비밀번호 재설정 요청 실패: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 사용자 삭제 (탈퇴)
  Future<bool> deleteUser() async {
    if (_currentUser == null) {
      _setError('로그인된 사용자가 없습니다');
      return false;
    }

    _setLoading(true);
    try {
      // TODO: 실제 사용자 삭제 API 연동
      
      // 로그아웃 처리
      await logout();
      
      _clearError();
      return true;
    } catch (e) {
      _setError('사용자 삭제 실패: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 에러 설정
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// 에러 클리어
  void _clearError() {
    _error = null;
    notifyListeners();
  }


  /// 사용자 활동 기록 업데이트
  Future<void> updateLastActivity() async {
    if (_currentUser == null) return;

    try {
      _currentUser = _currentUser!.copyWith(
        updatedAt: DateTime.now(),
      );
      
      // AuthService에서 활동 시간과 사용자 정보 모두 업데이트
      final authService = AuthService();
      await authService.updateActivity();
      await authService.setUser(_currentUser!.toMap());
      
      // UI 업데이트는 불필요하므로 notifyListeners() 호출하지 않음
    } catch (e) {
      // 활동 기록 업데이트 실패는 무시
      debugPrint('활동 기록 업데이트 실패: $e');
    }
  }

  /// 토큰 갱신 (추후 JWT 토큰 사용시)
  Future<bool> refreshToken() async {
    if (_currentUser == null) return false;

    try {
      // TODO: 실제 토큰 갱신 API 연동
      
      await updateLastActivity();
      return true;
    } catch (e) {
      _setError('토큰 갱신 실패: $e');
      return false;
    }
  }

  /// 디버그 정보
  Map<String, dynamic> get debugInfo => {
    'isLoggedIn': isLoggedIn,
    'userId': userId,
    'userEmail': userEmail,
    'userName': userName,
    'isLoading': isLoading,
    'error': error,
    'currentUser': _currentUser?.toMap(),
  };
}