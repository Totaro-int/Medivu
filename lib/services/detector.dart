// lib/services/detector.dart
import 'dart:typed_data';
import '../models/geometry_models.dart';

class Detection {
  final RectF box;
  final double score;
  Detection(this.box, this.score);
}

class Detector {
  bool _isLoaded = false;
  final int inputW, inputH;

  Detector._(this.inputW, this.inputH);

  static Future<Detector> create(String asset, {int inputW=640, int inputH=640}) async {
    final detector = Detector._(inputW, inputH);
    // 더미 구현 - TFLite 호환성 이슈로 현재는 더미 모드만 지원
    print('Detector 생성 완료 (더미 모드)');
    detector._isLoaded = false;
    return detector;
  }

  List<Detection> infer(Uint8List rgbBytes, int width, int height) {
    // 임시 더미 구현 - 실제 모델이 없을 때 테스트용
    // 화면 중앙에 가상의 번호판 영역을 생성
    final centerX = width * 0.5;
    final centerY = height * 0.5;
    final plateW = width * 0.4;
    final plateH = height * 0.1;
    
    return [
      Detection(
        RectF(
          centerX - plateW / 2,
          centerY - plateH / 2,
          plateW,
          plateH,
        ),
        0.9, // 높은 confidence score
      ),
    ];
  }

  void close() {
    // 더미 구현 - 정리할 리소스 없음
  }
}
