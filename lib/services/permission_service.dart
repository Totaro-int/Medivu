import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// 권한 상태 enum
enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
}

/// 권한 그룹별 결과
class PermissionCheckResult {
  final Map<Permission, PermissionResult> results;
  final bool allGranted;
  final List<Permission> deniedPermissions;
  final List<Permission> permanentlyDeniedPermissions;

  PermissionCheckResult({
    required this.results,
    required this.allGranted,
    required this.deniedPermissions,
    required this.permanentlyDeniedPermissions,
  });
}

/// 앱에서 사용하는 모든 권한을 통합 관리하는 서비스
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  static PermissionService get instance => _instance;
  PermissionService._internal();

  /// 앱에서 필요한 모든 권한 목록 (Android 버전별 처리)
  static List<Permission> get requiredPermissions {
    List<Permission> permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.locationWhenInUse,
    ];
    
    // Android 13 (API 33) 이상에서는 세분화된 미디어 권한 사용
    if (Platform.isAndroid) {
      permissions.addAll([
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ]);
    } else {
      // 이전 버전 또는 iOS에서는 기존 storage 권한 사용
      permissions.add(Permission.storage);
    }
    
    return permissions;
  }

  /// 모든 필수 권한 확인
  Future<PermissionCheckResult> checkAllPermissions() async {
    final Map<Permission, PermissionResult> results = {};
    final List<Permission> denied = [];
    final List<Permission> permanentlyDenied = [];

    for (final permission in requiredPermissions) {
      final status = await permission.status;
      final result = _mapPermissionStatus(status);
      results[permission] = result;

      switch (result) {
        case PermissionResult.denied:
          denied.add(permission);
          break;
        case PermissionResult.permanentlyDenied:
          permanentlyDenied.add(permission);
          break;
        case PermissionResult.restricted:
          denied.add(permission);
          break;
        default:
          break;
      }
    }

    final allGranted = denied.isEmpty && permanentlyDenied.isEmpty;

    debugPrint('🔐 권한 확인 결과:');
    debugPrint('  ✅ 허용된 권한: ${results.length - denied.length - permanentlyDenied.length}개');
    debugPrint('  ❌ 거부된 권한: ${denied.length}개');
    debugPrint('  🚫 영구 거부된 권한: ${permanentlyDenied.length}개');

    return PermissionCheckResult(
      results: results,
      allGranted: allGranted,
      deniedPermissions: denied,
      permanentlyDeniedPermissions: permanentlyDenied,
    );
  }

  /// 모든 필수 권한 요청 (개별 요청으로 더 안정적)
  Future<PermissionCheckResult> requestAllPermissions() async {
    debugPrint('🔐 모든 권한 요청 시작...');
    debugPrint('📱 플랫폼: ${Platform.isAndroid ? "Android" : "iOS"}');
    debugPrint('🎯 요청할 권한 목록: ${requiredPermissions.map((p) => _getPermissionName(p)).join(", ")}');

    try {
      final Map<Permission, PermissionResult> results = {};
      final List<Permission> denied = [];
      final List<Permission> permanentlyDenied = [];

      // 개별적으로 권한 요청 (더 안정적)
      for (final permission in requiredPermissions) {
        try {
          debugPrint('🔍 ${_getPermissionName(permission)} 권한 요청 중...');
          
          // 현재 상태 확인
          final currentStatus = await permission.status;
          debugPrint('  현재 상태: ${currentStatus.name}');
          
          PermissionStatus finalStatus;
          
          if (currentStatus == PermissionStatus.granted) {
            finalStatus = currentStatus;
            debugPrint('  이미 허용됨, 요청 건너뜀');
          } else if (currentStatus == PermissionStatus.permanentlyDenied) {
            finalStatus = currentStatus;
            debugPrint('  영구 거부됨, 요청 건너뜀');
          } else {
            // 권한 요청
            debugPrint('  권한 요청 다이얼로그 표시...');
            finalStatus = await permission.request();
            debugPrint('  요청 결과: ${finalStatus.name}');
          }
          
          final result = _mapPermissionStatus(finalStatus);
          results[permission] = result;

          switch (result) {
            case PermissionResult.denied:
              denied.add(permission);
              debugPrint('  ❌ ${_getPermissionName(permission)} 거부됨');
              break;
            case PermissionResult.permanentlyDenied:
              permanentlyDenied.add(permission);
              debugPrint('  🚫 ${_getPermissionName(permission)} 영구 거부됨');
              break;
            case PermissionResult.granted:
              debugPrint('  ✅ ${_getPermissionName(permission)} 허용됨');
              break;
            case PermissionResult.limited:
              debugPrint('  ⚠️ ${_getPermissionName(permission)} 제한적 허용');
              break;
            case PermissionResult.restricted:
              debugPrint('  🔒 ${_getPermissionName(permission)} 제한됨');
              denied.add(permission);
              break;
          }
          
          // 각 권한 요청 사이에 짧은 지연
          await Future.delayed(const Duration(milliseconds: 300));
          
        } catch (e) {
          debugPrint('❌ ${_getPermissionName(permission)} 권한 요청 실패: $e');
          // 오류 발생 시 거부된 것으로 처리
          results[permission] = PermissionResult.denied;
          denied.add(permission);
        }
      }

      final allGranted = denied.isEmpty && permanentlyDenied.isEmpty;
      
      debugPrint('🎯 권한 요청 완료:');
      debugPrint('  ✅ 허용: ${results.length - denied.length - permanentlyDenied.length}개');
      debugPrint('  ❌ 거부: ${denied.length}개');
      debugPrint('  🚫 영구 거부: ${permanentlyDenied.length}개');

      return PermissionCheckResult(
        results: results,
        allGranted: allGranted,
        deniedPermissions: denied,
        permanentlyDeniedPermissions: permanentlyDenied,
      );
    } catch (e) {
      debugPrint('❌ 권한 요청 중 치명적 오류 발생: $e');
      rethrow;
    }
  }

  /// 특정 권한 확인
  Future<PermissionResult> checkPermission(Permission permission) async {
    final status = await permission.status;
    return _mapPermissionStatus(status);
  }

  /// 특정 권한 요청
  Future<PermissionResult> requestPermission(Permission permission) async {
    debugPrint('🔐 ${_getPermissionName(permission)} 권한 요청...');
    
    try {
      final status = await permission.request();
      final result = _mapPermissionStatus(status);
      
      debugPrint('  결과: ${result.name}');
      return result;
    } catch (e) {
      debugPrint('❌ ${_getPermissionName(permission)} 권한 요청 실패: $e');
      rethrow;
    }
  }

  /// 카메라 권한 확인 및 요청
  Future<bool> ensureCameraPermission() async {
    final result = await checkPermission(Permission.camera);
    
    if (result == PermissionResult.granted) {
      return true;
    }
    
    if (result == PermissionResult.permanentlyDenied) {
      return false;
    }
    
    final requestResult = await requestPermission(Permission.camera);
    return requestResult == PermissionResult.granted;
  }

  /// 마이크 권한 확인 및 요청
  Future<bool> ensureMicrophonePermission() async {
    final result = await checkPermission(Permission.microphone);
    
    if (result == PermissionResult.granted) {
      return true;
    }
    
    if (result == PermissionResult.permanentlyDenied) {
      return false;
    }
    
    final requestResult = await requestPermission(Permission.microphone);
    return requestResult == PermissionResult.granted;
  }

  /// 위치 권한 확인 및 요청
  Future<bool> ensureLocationPermission() async {
    final result = await checkPermission(Permission.locationWhenInUse);
    
    if (result == PermissionResult.granted) {
      return true;
    }
    
    if (result == PermissionResult.permanentlyDenied) {
      return false;
    }
    
    final requestResult = await requestPermission(Permission.locationWhenInUse);
    return requestResult == PermissionResult.granted;
  }

  /// 저장소 권한 확인 및 요청 (Android 13+ 호환)
  Future<bool> ensureStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+에서는 세분화된 미디어 권한 확인
      final photoResult = await checkPermission(Permission.photos);
      final videoResult = await checkPermission(Permission.videos);
      final audioResult = await checkPermission(Permission.audio);
      
      bool allGranted = photoResult == PermissionResult.granted &&
                       videoResult == PermissionResult.granted &&
                       audioResult == PermissionResult.granted;
      
      if (allGranted) return true;
      
      // 하나라도 영구 거부되었으면 false
      if (photoResult == PermissionResult.permanentlyDenied ||
          videoResult == PermissionResult.permanentlyDenied ||
          audioResult == PermissionResult.permanentlyDenied) {
        return false;
      }
      
      // 권한 요청
      final photoRequest = await requestPermission(Permission.photos);
      final videoRequest = await requestPermission(Permission.videos);
      final audioRequest = await requestPermission(Permission.audio);
      
      return photoRequest == PermissionResult.granted &&
             videoRequest == PermissionResult.granted &&
             audioRequest == PermissionResult.granted;
    } else {
      // iOS 또는 이전 Android 버전
      final result = await checkPermission(Permission.storage);
      
      if (result == PermissionResult.granted) {
        return true;
      }
      
      if (result == PermissionResult.permanentlyDenied) {
        return false;
      }
      
      final requestResult = await requestPermission(Permission.storage);
      return requestResult == PermissionResult.granted;
    }
  }

  /// 앱 설정으로 이동
  Future<bool> openSettings() async {
    debugPrint('🔧 앱 설정 화면 열기...');
    return await openAppSettings();
  }

  /// 권한 상태를 내부 enum으로 변환
  PermissionResult _mapPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return PermissionResult.granted;
      case PermissionStatus.denied:
        return PermissionResult.denied;
      case PermissionStatus.permanentlyDenied:
        return PermissionResult.permanentlyDenied;
      case PermissionStatus.restricted:
        return PermissionResult.restricted;
      case PermissionStatus.limited:
        return PermissionResult.limited;
      case PermissionStatus.provisional:
        return PermissionResult.limited;
    }
  }

  /// 권한 이름을 한국어로 반환
  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return '카메라';
      case Permission.microphone:
        return '마이크';
      case Permission.location:
      case Permission.locationWhenInUse:
        return '위치';
      case Permission.storage:
        return '저장소';
      case Permission.photos:
        return '사진';
      case Permission.videos:
        return '동영상';
      case Permission.audio:
        return '오디오';
      default:
        return permission.toString().split('.').last;
    }
  }

  /// 권한별 사용자 친화적 설명 반환
  String getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return '동영상 촬영을 위해 카메라 접근이 필요합니다.';
      case Permission.microphone:
        return '소음 측정을 위해 마이크 접근이 필요합니다.';
      case Permission.location:
      case Permission.locationWhenInUse:
        return '정확한 위치 기록을 위해 위치 정보가 필요합니다.';
      case Permission.storage:
        return '측정 결과 저장을 위해 저장소 접근이 필요합니다.';
      case Permission.photos:
        return '사진 저장을 위해 사진 접근 권한이 필요합니다.';
      case Permission.videos:
        return '동영상 저장을 위해 동영상 접근 권한이 필요합니다.';
      case Permission.audio:
        return '오디오 파일 저장을 위해 오디오 접근 권한이 필요합니다.';
      default:
        return '앱 기능을 위해 해당 권한이 필요합니다.';
    }
  }

  /// 권한별 권장 액션 반환
  String getPermissionAction(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return '동영상 촬영 기능을 사용하려면 카메라 권한을 허용해주세요.';
      case Permission.microphone:
        return '소음 측정 기능을 사용하려면 마이크 권한을 허용해주세요.';
      case Permission.location:
      case Permission.locationWhenInUse:
        return '위치 기반 기록을 위해 위치 권한을 허용해주세요.';
      case Permission.storage:
        return '데이터 저장을 위해 저장소 권한을 허용해주세요.';
      case Permission.photos:
        return '사진 저장을 위해 사진 접근 권한을 허용해주세요.';
      case Permission.videos:
        return '동영상 저장을 위해 동영상 접근 권한을 허용해주세요.';
      case Permission.audio:
        return '오디오 저장을 위해 오디오 접근 권한을 허용해주세요.';
      default:
        return '해당 기능을 사용하려면 권한을 허용해주세요.';
    }
  }
}