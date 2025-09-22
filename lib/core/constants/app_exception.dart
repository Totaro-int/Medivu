/// 앱 전체 예외 처리 클래스들
/// 데이터베이스, 네트워크, 인증, 파일 등 앱 전반의 예외들을 정의
library;

import 'network_exception.dart';
import 'ocr_exception.dart';

abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    if (code != null) {
      return 'AppException [$code]: $message';
    }
    return 'AppException: $message';
  }
}

/// 데이터베이스 관련 예외
class DatabaseException extends AppException {
  const DatabaseException([String? message])
      : super(
          message ?? '데이터베이스 오류가 발생했습니다.',
          code: 'DATABASE_ERROR',
        );
}

/// 데이터베이스 초기화 예외
class DatabaseInitializationException extends DatabaseException {
  const DatabaseInitializationException([String? message])
      : super(message ?? '데이터베이스 초기화에 실패했습니다.');
}

/// 데이터 저장 예외
class DataSaveException extends DatabaseException {
  const DataSaveException([String? message])
      : super(message ?? '데이터 저장에 실패했습니다.');
}

/// 데이터 로드 예외
class DataLoadException extends DatabaseException {
  const DataLoadException([String? message])
      : super(message ?? '데이터 로드에 실패했습니다.');
}

/// 사용자 인증 예외
class AuthenticationException extends AppException {
  const AuthenticationException([String? message])
      : super(
          message ?? '인증에 실패했습니다.',
          code: 'AUTHENTICATION_FAILED',
        );
}

/// 권한 부족 예외
class PermissionException extends AppException {
  const PermissionException([String? message])
      : super(
          message ?? '권한이 부족합니다.',
          code: 'PERMISSION_DENIED',
        );
}

/// 설정 오류 예외
class ConfigurationException extends AppException {
  const ConfigurationException([String? message])
      : super(
          message ?? '앱 설정에 오류가 있습니다.',
          code: 'CONFIGURATION_ERROR',
        );
}

/// 파일 시스템 예외
class FileSystemException extends AppException {
  final String? filePath;

  const FileSystemException(this.filePath, [String? message])
      : super(
          message ?? '파일 시스템 오류가 발생했습니다.',
          code: 'FILE_SYSTEM_ERROR',
        );
}

/// 파일을 찾을 수 없음
class FileNotFoundException extends FileSystemException {
  const FileNotFoundException([String? filePath, String? message])
      : super(filePath, message ?? '파일을 찾을 수 없습니다.');
}

/// 파일 읽기 실패
class FileReadException extends FileSystemException {
  const FileReadException([String? filePath, String? message])
      : super(filePath, message ?? '파일 읽기에 실패했습니다.');
}

/// 파일 쓰기 실패
class FileWriteException extends FileSystemException {
  const FileWriteException([String? filePath, String? message])
      : super(filePath, message ?? '파일 쓰기에 실패했습니다.');
}

/// 미디어 처리 예외
class MediaException extends AppException {
  const MediaException([String? message])
      : super(
          message ?? '미디어 처리 중 오류가 발생했습니다.',
          code: 'MEDIA_ERROR',
        );
}

/// 카메라 예외
class CameraException extends MediaException {
  const CameraException([String? message])
      : super(message ?? '카메라 사용 중 오류가 발생했습니다.');
}

/// 오디오 녹음 예외
class AudioRecordingException extends MediaException {
  const AudioRecordingException([String? message])
      : super(message ?? '오디오 녹음 중 오류가 발생했습니다.');
}

/// 비디오 처리 예외
class VideoProcessingException extends MediaException {
  const VideoProcessingException([String? message])
      : super(message ?? '비디오 처리 중 오류가 발생했습니다.');
}

/// 리포트 생성 예외
class ReportGenerationException extends AppException {
  const ReportGenerationException([String? message])
      : super(
          message ?? '리포트 생성에 실패했습니다.',
          code: 'REPORT_GENERATION_FAILED',
        );
}

/// PDF 생성 예외
class PdfGenerationException extends ReportGenerationException {
  const PdfGenerationException([String? message])
      : super(message ?? 'PDF 생성에 실패했습니다.');
}

/// 공유 기능 예외
class ShareException extends AppException {
  const ShareException([String? message])
      : super(
          message ?? '공유 기능 사용 중 오류가 발생했습니다.',
          code: 'SHARE_ERROR',
        );
}

/// 서비스 사용 불가 예외
class ServiceUnavailableException extends AppException {
  const ServiceUnavailableException([String? message])
      : super(
          message ?? '서비스를 사용할 수 없습니다.',
          code: 'SERVICE_UNAVAILABLE',
        );
}

/// 타임아웃 예외
class TimeoutException extends AppException {
  final Duration timeout;

  const TimeoutException(this.timeout, [String? message])
      : super(
          message ?? '작업 시간이 초과되었습니다.',
          code: 'TIMEOUT',
        );
}

/// 입력값 검증 예외
class ValidationException extends AppException {
  const ValidationException([String? message])
      : super(
          message ?? '입력값이 올바르지 않습니다.',
          code: 'VALIDATION_FAILED',
        );
}

/// 앱 예외 처리 유틸리티 클래스
class AppExceptionHandler {
  /// 일반적인 Exception을 AppException으로 변환
  static AppException fromException(dynamic error) {
    if (error is AppException) {
      return error;
    }

    // 네트워크 예외 처리
    if (error is NetworkException) {
      return _createAppExceptionFromNetworkException(error);
    }

    // OCR 예외 처리
    if (error is OCRException) {
      return _createAppExceptionFromOCRException(error);
    }

    // 파일 시스템 예외 처리 (dart:io의 FileSystemException과 구분)
    if (error.runtimeType.toString() == 'FileSystemException') {
      return FileNotFoundException(null, error.toString());
    }

    // 권한 예외 처리
    if (error is PermissionDeniedException) {
      return PermissionException(error.message);
    }

    // 설정 예외 처리
    if (error is FormatException) {
      return ConfigurationException('설정 형식 오류: ${error.message}');
    }

    // 일반적인 오류 처리
    return _createGenericAppException(error.toString());
  }

  /// 네트워크 예외를 앱 예외로 변환
  static AppException _createAppExceptionFromNetworkException(NetworkException error) {
    return ServiceUnavailableException(
      '네트워크 오류로 인해 서비스를 사용할 수 없습니다: ${error.message}',
    );
  }

  /// OCR 예외를 앱 예외로 변환
  static AppException _createAppExceptionFromOCRException(OCRException error) {
    return MediaException(
      'OCR 처리 중 오류가 발생했습니다: ${error.message}',
    );
  }

  /// 일반적인 앱 예외 생성
  static AppException _createGenericAppException(String errorMessage) {
    return ConfigurationException(
      '알 수 없는 오류가 발생했습니다: $errorMessage',
    );
  }

  /// 사용자 친화적인 오류 메시지 생성
  static String getUserFriendlyMessage(AppException exception) {
    switch (exception.code) {
      case 'DATABASE_ERROR':
        return '데이터 처리 중 문제가 발생했습니다. 앱을 다시 시작해 보세요.';
      case 'AUTHENTICATION_FAILED':
        return '로그인 정보를 확인해 주세요. 다시 로그인해 주세요.';
      case 'PERMISSION_DENIED':
        return '이 기능을 사용하려면 권한이 필요합니다.';
      case 'CONFIGURATION_ERROR':
        return '앱 설정에 문제가 있습니다. 앱을 재설치해 보세요.';
      case 'FILE_SYSTEM_ERROR':
        return '파일 처리 중 문제가 발생했습니다. 저장 공간을 확인해 주세요.';
      case 'MEDIA_ERROR':
        return '미디어 처리 중 문제가 발생했습니다. 카메라 권한을 확인해 주세요.';
      case 'REPORT_GENERATION_FAILED':
        return '리포트 생성에 실패했습니다. 다시 시도해 주세요.';
      case 'SHARE_ERROR':
        return '공유 기능을 사용할 수 없습니다. 다른 방법을 시도해 주세요.';
      case 'SERVICE_UNAVAILABLE':
        return '서비스를 일시적으로 사용할 수 없습니다. 잠시 후 다시 시도해 주세요.';
      case 'TIMEOUT':
        return '작업 시간이 초과되었습니다. 네트워크 상태를 확인해 주세요.';
      case 'VALIDATION_FAILED':
        return '입력한 정보를 다시 확인해 주세요.';
      default:
        return '문제가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    }
  }

  /// 로깅을 위한 상세 오류 정보 생성
  static Map<String, dynamic> getErrorDetails(AppException exception) {
    return {
      'type': exception.runtimeType.toString(),
      'code': exception.code,
      'message': exception.message,
      'timestamp': DateTime.now().toIso8601String(),
      'originalError': exception.originalError?.toString(),
      'stackTrace': exception.stackTrace?.toString(),
      'userMessage': getUserFriendlyMessage(exception),
    };
  }

  /// 복구 가능한 예외인지 확인
  static bool isRecoverable(AppException exception) {
    switch (exception.code) {
      case 'DATABASE_ERROR':
      case 'AUTHENTICATION_FAILED':
      case 'SERVICE_UNAVAILABLE':
      case 'TIMEOUT':
        return true;
      case 'PERMISSION_DENIED':
      case 'CONFIGURATION_ERROR':
      case 'FILE_SYSTEM_ERROR':
      case 'VALIDATION_FAILED':
        return false;
      default:
        return true;
    }
  }

  /// 자동 재시도 가능한 예외인지 확인
  static bool canAutoRetry(AppException exception) {
    switch (exception.code) {
      case 'SERVICE_UNAVAILABLE':
      case 'TIMEOUT':
        return true;
      default:
        return false;
    }
  }
}

/// 플랫폼별 권한 거부 예외 (앱에서는 사용하지 않지만 참조용)
class PermissionDeniedException implements Exception {
  final String message;
  const PermissionDeniedException(this.message);
}