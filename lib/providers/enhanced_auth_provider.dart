import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/enhanced_auth_service.dart';

class EnhancedAuthProvider extends ChangeNotifier {
  static EnhancedAuthProvider? _instance;
  
  EnhancedAuthProvider._internal();
  
  static EnhancedAuthProvider get instance {
    _instance ??= EnhancedAuthProvider._internal();
    return _instance!;
  }

  final EnhancedAuthService _authService = EnhancedAuthService.instance;

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _userPreferences = {};

  // Getters
  UserModel? get currentUser => _authService.currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _authService.isLoggedIn;
  String? get userId => _authService.userId;
  String? get userEmail => _authService.userEmail;
  String? get userName => _authService.userName;
  String? get sessionToken => _authService.sessionToken;
  Map<String, dynamic> get userPreferences => _userPreferences;

  /// 초기화 - 세션 복원
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      final restored = await _authService.restoreSession();
      
      if (restored) {
        await _loadUserPreferences();
        debugPrint('✅ 세션 복원 성공: ${userEmail}');
      } else {
        debugPrint('ℹ️ 복원할 세션이 없습니다');
      }
    } catch (e) {
      debugPrint('❌ 초기화 에러: $e');
      _setError('초기화 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  /// 회원가입
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String confirmPassword,
    String? displayName,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.register(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        displayName: displayName,
        phoneNumber: phoneNumber,
      );

      if (result['success']) {
        await _loadUserPreferences();
        debugPrint('✅ 회원가입 성공: $email');
      } else {
        _setError(result['message']);
      }

      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('❌ 회원가입 에러: $e');
      _setError('회원가입 중 오류가 발생했습니다');
      return {
        'success': false,
        'message': '회원가입 중 오류가 발생했습니다',
        'error': e.toString(),
      };
    } finally {
      _setLoading(false);
    }
  }

  /// 로그인
  Future<Map<String, dynamic>> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.login(email, password);

      if (result['success']) {
        await _loadUserPreferences();
        debugPrint('✅ 로그인 성공: $email');
      } else {
        _setError(result['message']);
      }

      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('❌ 로그인 에러: $e');
      _setError('로그인 중 오류가 발생했습니다');
      return {
        'success': false,
        'message': '로그인 중 오류가 발생했습니다',
        'error': e.toString(),
      };
    } finally {
      _setLoading(false);
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.logout();
      _userPreferences.clear();
      debugPrint('✅ 로그아웃 성공');
    } catch (e) {
      debugPrint('❌ 로그아웃 에러: $e');
      _setError('로그아웃 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 모든 기기에서 로그아웃
  Future<void> logoutAllDevices() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.logoutAllDevices();
      _userPreferences.clear();
      debugPrint('✅ 모든 기기에서 로그아웃 성공');
    } catch (e) {
      debugPrint('❌ 전체 로그아웃 에러: $e');
      _setError('로그아웃 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 비밀번호 변경
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (!result['success']) {
        _setError(result['message']);
      }

      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('❌ 비밀번호 변경 에러: $e');
      _setError('비밀번호 변경 중 오류가 발생했습니다');
      return {
        'success': false,
        'message': '비밀번호 변경 중 오류가 발생했습니다',
        'error': e.toString(),
      };
    } finally {
      _setLoading(false);
    }
  }

  /// 프로필 업데이트
  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? profileImagePath,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.updateProfile(
        displayName: displayName,
        phoneNumber: phoneNumber,
        profileImagePath: profileImagePath,
      );

      if (!result['success']) {
        _setError(result['message']);
      }

      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('❌ 프로필 업데이트 에러: $e');
      _setError('프로필 업데이트 중 오류가 발생했습니다');
      return {
        'success': false,
        'message': '프로필 업데이트 중 오류가 발생했습니다',
        'error': e.toString(),
      };
    } finally {
      _setLoading(false);
    }
  }

  /// 사용자 설정 저장
  Future<void> setUserPreference(String key, dynamic value) async {
    try {
      await _authService.setUserPreference(key, value);
      _userPreferences[key] = value;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 사용자 설정 저장 에러: $e');
    }
  }

  /// 사용자 설정 로드
  Future<T?> getUserPreference<T>(String key) async {
    try {
      if (_userPreferences.containsKey(key)) {
        return _userPreferences[key] as T?;
      }
      
      final value = await _authService.getUserPreference<T>(key);
      if (value != null) {
        _userPreferences[key] = value;
      }
      return value;
    } catch (e) {
      debugPrint('❌ 사용자 설정 로드 에러: $e');
      return null;
    }
  }

  /// 모든 사용자 설정 로드
  Future<void> _loadUserPreferences() async {
    try {
      _userPreferences = await _authService.getAllUserPreferences();
    } catch (e) {
      debugPrint('❌ 사용자 설정 전체 로드 에러: $e');
    }
  }

  /// 활동 시간 업데이트
  Future<void> updateActivity() async {
    try {
      await _authService.updateActivity();
    } catch (e) {
      debugPrint('❌ 활동 시간 업데이트 에러: $e');
    }
  }

  /// 세션 유효성 검사
  Future<bool> validateSession() async {
    try {
      return await _authService.validateSession();
    } catch (e) {
      debugPrint('❌ 세션 유효성 검사 에러: $e');
      return false;
    }
  }

  /// 앱 테마 설정
  Future<void> setDarkMode(bool isDarkMode) async {
    await setUserPreference('dark_mode', isDarkMode);
  }

  /// 다크 모드 상태 가져오기
  Future<bool> getDarkMode() async {
    return await getUserPreference<bool>('dark_mode') ?? false;
  }

  /// 알림 설정
  Future<void> setNotificationEnabled(bool enabled) async {
    await setUserPreference('notification_enabled', enabled);
  }

  /// 알림 설정 상태 가져오기
  Future<bool> getNotificationEnabled() async {
    return await getUserPreference<bool>('notification_enabled') ?? true;
  }

  /// 소음 임계값 설정
  Future<void> setNoiseThreshold(double threshold) async {
    await setUserPreference('noise_threshold', threshold);
  }

  /// 소음 임계값 가져오기
  Future<double> getNoiseThreshold() async {
    return await getUserPreference<double>('noise_threshold') ?? 70.0;
  }

  /// 위치 추적 설정
  Future<void> setLocationTracking(bool enabled) async {
    await setUserPreference('location_tracking', enabled);
  }

  /// 위치 추적 설정 상태 가져오기
  Future<bool> getLocationTracking() async {
    return await getUserPreference<bool>('location_tracking') ?? true;
  }

  /// 자동 비디오 저장 설정
  Future<void> setAutoSaveVideos(bool enabled) async {
    await setUserPreference('auto_save_videos', enabled);
  }

  /// 자동 비디오 저장 설정 상태 가져오기
  Future<bool> getAutoSaveVideos() async {
    return await getUserPreference<bool>('auto_save_videos') ?? true;
  }

  /// 언어 설정
  Future<void> setLanguage(String languageCode) async {
    await setUserPreference('language', languageCode);
  }

  /// 언어 설정 가져오기
  Future<String> getLanguage() async {
    return await getUserPreference<String>('language') ?? 'ko';
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 에러 설정
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  /// 에러 클리어
  void _clearError() {
    _setError(null);
  }

  /// 수동 에러 클리어 (UI에서 호출)
  void clearError() {
    _clearError();
  }

  /// 디버그 정보
  Map<String, dynamic> get debugInfo => {
    ..._authService.debugInfo,
    'isLoading': isLoading,
    'error': error,
    'userPreferences': _userPreferences,
  };

  /// Provider 정리
  @override
  void dispose() {
    // 리소스 정리 (필요한 경우)
    super.dispose();
  }
}