/// 네트워크 관련 예외 처리 클래스들
/// HTTP 통신, API 호출, 파일 업로드 등 네트워크 작업 중 발생할 수 있는 예외들을 정의
library;

import 'dart:io';
import 'dart:async';

abstract class NetworkException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final dynamic originalError;

  const NetworkException(
    this.message, {
    this.code,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    if (code != null && statusCode != null) {
      return 'NetworkException [$code - $statusCode]: $message';
    } else if (code != null) {
      return 'NetworkException [$code]: $message';
    }
    return 'NetworkException: $message';
  }
}

/// 인터넷 연결 없음
class NoInternetConnectionException extends NetworkException {
  const NoInternetConnectionException([String? message])
      : super(
          message ?? '인터넷 연결을 확인해 주세요.',
          code: 'NO_INTERNET_CONNECTION',
        );
}

/// 서버 연결 실패
class ServerConnectionException extends NetworkException {
  const ServerConnectionException([String? message])
      : super(
          message ?? '서버에 연결할 수 없습니다.',
          code: 'SERVER_CONNECTION_FAILED',
        );
}

/// HTTP 요청 타임아웃
class RequestTimeoutException extends NetworkException {
  final Duration timeout;

  RequestTimeoutException(this.timeout, [String? message])
      : super(
          message ?? '요청 시간이 초과되었습니다. (${timeout.inSeconds}초)',
          code: 'REQUEST_TIMEOUT',
        );
}

/// HTTP 400번대 오류 (클라이언트 오류)
class ClientErrorException extends NetworkException {
  const ClientErrorException(int statusCode, [String? message])
      : super(
          message ?? '잘못된 요청입니다.',
          code: 'CLIENT_ERROR',
          statusCode: statusCode,
        );
}

/// HTTP 401 인증 오류
class UnauthorizedException extends NetworkException {
  const UnauthorizedException([String? message])
      : super(
          message ?? '인증이 필요합니다. 다시 로그인해 주세요.',
          code: 'UNAUTHORIZED',
          statusCode: 401,
        );
}

/// HTTP 403 권한 없음
class ForbiddenException extends NetworkException {
  const ForbiddenException([String? message])
      : super(
          message ?? '이 작업을 수행할 권한이 없습니다.',
          code: 'FORBIDDEN',
          statusCode: 403,
        );
}

/// HTTP 404 찾을 수 없음
class NotFoundException extends NetworkException {
  const NotFoundException([String? message])
      : super(
          message ?? '요청한 리소스를 찾을 수 없습니다.',
          code: 'NOT_FOUND',
          statusCode: 404,
        );
}

/// HTTP 429 요청 한도 초과
class TooManyRequestsException extends NetworkException {
  const TooManyRequestsException([String? message])
      : super(
          message ?? '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.',
          code: 'TOO_MANY_REQUESTS',
          statusCode: 429,
        );
}

/// HTTP 500번대 오류 (서버 오류)
class ServerErrorException extends NetworkException {
  const ServerErrorException(int statusCode, [String? message])
      : super(
          message ?? '서버에 문제가 발생했습니다.',
          code: 'SERVER_ERROR',
          statusCode: statusCode,
        );
}

/// 파일 업로드 실패
class FileUploadException extends NetworkException {
  final String? fileName;
  final int? fileSize;

  const FileUploadException(this.fileName, this.fileSize, [String? message])
      : super(
          message ?? '파일 업로드에 실패했습니다.',
          code: 'FILE_UPLOAD_FAILED',
        );
}

/// 응답 파싱 실패
class ResponseParsingException extends NetworkException {
  const ResponseParsingException([String? message])
      : super(
          message ?? '서버 응답을 처리할 수 없습니다.',
          code: 'RESPONSE_PARSING_FAILED',
        );
}

/// API 키 오류
class InvalidApiKeyException extends NetworkException {
  const InvalidApiKeyException([String? message])
      : super(
          message ?? 'API 키가 유효하지 않습니다.',
          code: 'INVALID_API_KEY',
          statusCode: 401,
        );
}

/// 네트워크 용량 초과
class NetworkCapacityExceededException extends NetworkException {
  const NetworkCapacityExceededException([String? message])
      : super(
          message ?? '네트워크 용량이 초과되었습니다.',
          code: 'NETWORK_CAPACITY_EXCEEDED',
        );
}

/// SSL/TLS 인증서 오류
class CertificateException extends NetworkException {
  const CertificateException([String? message])
      : super(
          message ?? 'SSL 인증서 오류가 발생했습니다.',
          code: 'CERTIFICATE_ERROR',
        );
}

/// 네트워크 예외 유틸리티 클래스
class NetworkExceptionHandler {
  /// 일반적인 Exception을 NetworkException으로 변환
  static NetworkException fromException(dynamic error) {
    if (error is NetworkException) {
      return error;
    }

    // SocketException 처리
    if (error is SocketException) {
      return const NoInternetConnectionException();
    }

    // TimeoutException 처리
    if (error is TimeoutException) {
      return RequestTimeoutException(const Duration(seconds: 30));
    }

    // HandshakeException (SSL/TLS 오류) 처리
    if (error is HandshakeException) {
      return const CertificateException();
    }

    final message = error.toString();

    // HTTP 상태 코드 기반 예외 분류

    if (message.contains('401')) {
      return const UnauthorizedException();
    }
    if (message.contains('403')) {
      return const ForbiddenException();
    }
    if (message.contains('404')) {
      return const NotFoundException();
    }
    if (message.contains('429')) {
      return const TooManyRequestsException();
    }
    if (message.contains('500') || message.contains('502') || message.contains('503')) {
      return const ServerErrorException(500);
    }

    // 일반적인 오류 패턴 매핑
    if (message.toLowerCase().contains('network') || 
        message.toLowerCase().contains('connection')) {
      return const NoInternetConnectionException();
    }
    
    if (message.toLowerCase().contains('timeout')) {
      return RequestTimeoutException(const Duration(seconds: 30));
    }

    // 기본적으로 서버 연결 예외로 분류
    return ServerConnectionException('네트워크 오류: $message');
  }

  /// HTTP 상태 코드를 NetworkException으로 변환
  static NetworkException fromStatusCode(int statusCode, [String? message]) {
    switch (statusCode) {
      case 400:
        return ClientErrorException(statusCode, message ?? '잘못된 요청입니다.');
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 429:
        return TooManyRequestsException(message);
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerErrorException(statusCode, message);
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return ClientErrorException(statusCode, message);
        } else if (statusCode >= 500) {
          return ServerErrorException(statusCode, message);
        }
        return ServerConnectionException(message ?? '알 수 없는 네트워크 오류가 발생했습니다.');
    }
  }

  /// 사용자 친화적인 오류 메시지 생성
  static String getUserFriendlyMessage(NetworkException exception) {
    switch (exception.code) {
      case 'NO_INTERNET_CONNECTION':
        return '인터넷 연결을 확인하고 다시 시도해 주세요.';
      case 'SERVER_CONNECTION_FAILED':
        return '서버에 연결할 수 없습니다. 잠시 후 다시 시도해 주세요.';
      case 'REQUEST_TIMEOUT':
        return '요청 시간이 초과되었습니다. 네트워크 상태를 확인해 주세요.';
      case 'UNAUTHORIZED':
        return '로그인이 필요합니다. 다시 로그인해 주세요.';
      case 'FORBIDDEN':
        return '이 기능을 사용할 권한이 없습니다.';
      case 'NOT_FOUND':
        return '요청한 정보를 찾을 수 없습니다.';
      case 'TOO_MANY_REQUESTS':
        return '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.';
      case 'SERVER_ERROR':
        return '서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.';
      case 'FILE_UPLOAD_FAILED':
        return '파일 업로드에 실패했습니다. 네트워크 상태를 확인해 주세요.';
      case 'RESPONSE_PARSING_FAILED':
        return '서버 응답 처리 중 문제가 발생했습니다.';
      case 'INVALID_API_KEY':
        return 'API 인증 오류가 발생했습니다. 앱을 재시작해 주세요.';
      case 'CERTIFICATE_ERROR':
        return 'SSL 인증서 오류가 발생했습니다. 네트워크 설정을 확인해 주세요.';
      default:
        return '네트워크 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    }
  }

  /// 재시도 가능한 예외인지 확인
  static bool isRetryable(NetworkException exception) {
    switch (exception.code) {
      case 'NO_INTERNET_CONNECTION':
      case 'SERVER_CONNECTION_FAILED':
      case 'REQUEST_TIMEOUT':
      case 'SERVER_ERROR':
      case 'TOO_MANY_REQUESTS':
        return true;
      case 'UNAUTHORIZED':
      case 'FORBIDDEN':
      case 'NOT_FOUND':
      case 'INVALID_API_KEY':
      case 'CERTIFICATE_ERROR':
        return false;
      default:
        return true;
    }
  }

  /// 로깅을 위한 상세 오류 정보 생성
  static Map<String, dynamic> getErrorDetails(NetworkException exception) {
    return {
      'type': exception.runtimeType.toString(),
      'code': exception.code,
      'statusCode': exception.statusCode,
      'message': exception.message,
      'timestamp': DateTime.now().toIso8601String(),
      'originalError': exception.originalError?.toString(),
      'isRetryable': isRetryable(exception),
    };
  }

  /// 인터넷 연결 상태 확인
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}