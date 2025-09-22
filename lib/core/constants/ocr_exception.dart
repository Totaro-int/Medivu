/// OCR 관련 예외 처리 클래스들
/// 이미지 인식, ML Kit 텍스트 인식 등 OCR 작업 중 발생할 수 있는 예외들을 정의
library;

import 'dart:async';

abstract class OCRException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const OCRException(this.message, {this.code, this.originalError});

  @override
  String toString() {
    if (code != null) {
      return 'OCRException [$code]: $message';
    }
    return 'OCRException: $message';
  }
}

/// ML Kit 초기화 실패
class MLKitInitializationException extends OCRException {
  const MLKitInitializationException([String? message])
      : super(message ?? 'ML Kit 초기화에 실패했습니다.', code: 'MLKIT_INIT_FAILED');
}

/// 이미지 처리 실패
class ImageProcessingException extends OCRException {
  const ImageProcessingException([String? message])
      : super(message ?? '이미지 처리에 실패했습니다.', code: 'IMAGE_PROCESSING_FAILED');
}

/// 텍스트 인식 실패
class TextRecognitionException extends OCRException {
  const TextRecognitionException([String? message])
      : super(message ?? '텍스트 인식에 실패했습니다.', code: 'TEXT_RECOGNITION_FAILED');
}

/// 번호판 인식 실패
class LicensePlateRecognitionException extends OCRException {
  const LicensePlateRecognitionException([String? message])
      : super(message ?? '번호판 인식에 실패했습니다.', code: 'LICENSE_PLATE_RECOGNITION_FAILED');
}

/// 인식 결과 신뢰도 낮음
class LowConfidenceException extends OCRException {
  final double confidence;
  final double threshold;

  LowConfidenceException(this.confidence, this.threshold, [String? message])
      : super(
          message ?? '인식 결과 신뢰도가 낮습니다. ($confidence < $threshold)',
          code: 'LOW_CONFIDENCE_RESULT',
        );
}

/// 텍스트를 찾을 수 없음
class NoTextFoundException extends OCRException {
  const NoTextFoundException([String? message])
      : super(message ?? '이미지에서 텍스트를 찾을 수 없습니다.', code: 'NO_TEXT_FOUND');
}

/// OCR 처리 시간 초과
class OCRTimeoutException extends OCRException {
  final Duration timeout;

  OCRTimeoutException(this.timeout, [String? message])
      : super(
          message ?? 'OCR 처리 시간이 초과되었습니다. (${timeout.inSeconds}초)',
          code: 'OCR_TIMEOUT',
        );
}

/// 이미지 형식 지원 안함
class UnsupportedImageFormatException extends OCRException {
  final String? format;

  const UnsupportedImageFormatException(this.format, [String? message])
      : super(
          message ?? '지원되지 않는 이미지 형식입니다.',
          code: 'UNSUPPORTED_IMAGE_FORMAT',
        );
}

/// 이미지 크기 문제
class ImageSizeException extends OCRException {
  final int? width;
  final int? height;

  const ImageSizeException(this.width, this.height, [String? message])
      : super(
          message ?? '이미지 크기가 적절하지 않습니다.',
          code: 'INVALID_IMAGE_SIZE',
        );
}

/// 카메라 이미지 캡처 실패
class CameraImageCaptureException extends OCRException {
  const CameraImageCaptureException([String? message])
      : super(message ?? '카메라 이미지 캡처에 실패했습니다.', code: 'CAMERA_CAPTURE_FAILED');
}

/// OCR 결과 처리 실패
class OCRResultProcessingException extends OCRException {
  const OCRResultProcessingException([String? message])
      : super(message ?? 'OCR 결과 처리에 실패했습니다.', code: 'OCR_RESULT_PROCESSING_FAILED');
}

/// OCR 예외 처리 유틸리티 클래스
class OCRExceptionHandler {
  /// 일반적인 Exception을 OCRException으로 변환
  static OCRException fromException(dynamic error, [String? message]) {
    if (error is OCRException) {
      return error;
    }

    // 타임아웃 예외 처리
    if (error is TimeoutException) {
      return OCRTimeoutException(const Duration(seconds: 30));
    }

    // 카메라 관련 예외 처리
    if (error.toString().toLowerCase().contains('camera')) {
      return CameraImageCaptureException('카메라 관련 오류: $message');
    }

    // 이미지 처리 관련 예외 처리
    if (error.toString().toLowerCase().contains('image')) {
      return TextRecognitionException('OCR 이미지 처리 실패: $message');
    }

    // 일반적인 오류를 텍스트 인식 실패로 분류
    return TextRecognitionException(message ?? error.toString());
  }

  /// 사용자 친화적인 오류 메시지 생성
  static String getUSerFriendlyMessage(OCRException exception) {
    switch (exception.code) {
      case 'MLKIT_INIT_FAILED':
        return 'OCR 기능을 초기화할 수 없습니다. 앱을 다시 시작해 보세요.';
      case 'IMAGE_PROCESSING_FAILED':
        return '이미지를 처리할 수 없습니다. 다른 이미지를 시도해 보세요.';
      case 'TEXT_RECOGNITION_FAILED':
        return '텍스트를 인식할 수 없습니다. 이미지의 텍스트가 선명한지 확인해 보세요.';
      case 'LICENSE_PLATE_RECOGNITION_FAILED':
        return '번호판을 인식할 수 없습니다. 번호판이 선명하게 보이는지 확인해 보세요.';
      case 'LOW_CONFIDENCE_RESULT':
        return '인식 결과의 정확도가 낮습니다. 더 선명한 이미지를 사용해 보세요.';
      case 'NO_TEXT_FOUND':
        return '이미지에서 텍스트를 찾을 수 없습니다. 텍스트가 포함된 이미지인지 확인해 보세요.';
      case 'OCR_TIMEOUT':
        return 'OCR 처리 시간이 초과되었습니다. 네트워크 상태를 확인하거나 다시 시도해 보세요.';
      case 'UNSUPPORTED_IMAGE_FORMAT':
        return '지원되지 않는 이미지 형식입니다. JPG, PNG 형식을 사용해 보세요.';
      case 'INVALID_IMAGE_SIZE':
        return '이미지 크기가 너무 크거나 작습니다. 적절한 크기의 이미지를 사용해 보세요.';
      case 'CAMERA_CAPTURE_FAILED':
        return '카메라로 이미지를 촬영할 수 없습니다. 카메라 권한을 확인해 보세요.';
      case 'OCR_RESULT_PROCESSING_FAILED':
        return 'OCR 결과를 처리하는 중 문제가 발생했습니다. 다시 시도해 보세요.';
      default:
        return 'OCR 처리 중 문제가 발생했습니다. 다시 시도해 보세요.';
    }
  }

  /// 재시도 가능한 예외인지 확인
  static bool isRetryable(OCRException exception) {
    switch (exception.code) {
      case 'MLKIT_INIT_FAILED':
      case 'OCR_TIMEOUT':
      case 'CAMERA_CAPTURE_FAILED':
      case 'OCR_RESULT_PROCESSING_FAILED':
        return true;
      case 'UNSUPPORTED_IMAGE_FORMAT':
      case 'INVALID_IMAGE_SIZE':
      case 'NO_TEXT_FOUND':
        return false;
      default:
        return true;
    }
  }

  /// 로깅을 위한 상세 오류 정보 생성
  static Map<String, dynamic> getErrorDetails(OCRException exception) {
    final Map<String, dynamic> details = {
      'type': exception.runtimeType.toString(),
      'code': exception.code,
      'message': exception.message,
      'timestamp': DateTime.now().toIso8601String(),
      'originalError': exception.originalError?.toString(),
      'isRetryable': isRetryable(exception),
      'userMessage': getUSerFriendlyMessage(exception),
    };

    // 특별한 예외 유형에 대한 추가 정보
    if (exception is LowConfidenceException) {
      details['confidence'] = exception.confidence;
      details['threshold'] = exception.threshold;
    } else if (exception is OCRTimeoutException) {
      details['timeoutSeconds'] = exception.timeout.inSeconds;
    } else if (exception is UnsupportedImageFormatException) {
      details['format'] = exception.format;
    } else if (exception is ImageSizeException) {
      details['width'] = exception.width;
      details['height'] = exception.height;
    }

    return details;
  }
}