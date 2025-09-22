// lib/services/recognizer.dart
import 'dart:typed_data';

class Recognizer {
  bool _isLoaded = false;
  final int inputW, inputH;

  Recognizer._(this.inputW, this.inputH);

  static Future<Recognizer> create(String asset, {int inputW=160, int inputH=48}) async {
    final recognizer = Recognizer._(inputW, inputH);
    try {
      // tflite 패키지에서는 별도의 recognizer 로딩이 제한적이므로 더미 모드로 동작
      print('Recognizer 생성 (더미 모드)');
      recognizer._isLoaded = false; // 항상 더미 모드
    } catch (e) {
      print('Recognizer 모델 로딩 실패 (더미 모드): $e');
    }
    return recognizer;
  }

  String infer(Uint8List cropRgb) {
    // 임시 더미 구현 - 한국 자동차/오토바이 번호판 형식
    final now = DateTime.now();
    final typeSelector = now.second % 3; // 3가지 타입 순환
    
    String plateNumber;
    
    switch (typeSelector) {
      case 0:
        // 일반 자동차 번호판: 숫자(2-3자리) + 한글(1자리) + 숫자(4자리)
        final regions = ['가', '나', '다', '라', '마', '바', '사', '아', '자', '차'];
        final prefixes = ['12', '34', '56', '78', '90', '123', '456', '789'];
        final numbers = ['1234', '5678', '9012', '3456', '7890'];
        
        final region = regions[now.millisecond % regions.length];
        final prefix = prefixes[(now.second * 7) % prefixes.length];
        final number = numbers[(now.minute + now.second) % numbers.length];
        
        plateNumber = '$prefix$region$number';
        break;
        
      case 1:
        // 오토바이 번호판 (하단 핵심): 한글(1자리) + 숫자(4자리)
        final bikeRegions = ['가', '나', '다', '라', '마', '바', '사', '자', '하'];
        final bikeNumbers = ['1234', '5678', '9012', '3456', '7890', '2468', '1357'];
        
        final region = bikeRegions[now.microsecond % bikeRegions.length];
        final number = bikeNumbers[(now.second + now.minute) % bikeNumbers.length];
        
        plateNumber = '$region $number'; // 공백 포함
        break;
        
      case 2:
        // 오토바이 번호판 (하단 핵심): 한글(2자리) + 숫자(4자리)
        final bikeRegions2 = ['가나', '다라', '마바', '사아', '자차', '카타'];
        final bikeNumbers2 = ['5678', '9012', '3456', '7890', '2468', '1357', '0987'];
        
        final region = bikeRegions2[now.millisecond % bikeRegions2.length];
        final number = bikeNumbers2[(now.second * 3) % bikeNumbers2.length];
        
        plateNumber = '$region $number'; // 공백 포함
        break;
        
      default:
        plateNumber = '가 1234';
    }
    
    print('더미 번호판 생성 (타입 $typeSelector): $plateNumber');
    return plateNumber;
  }

  void close() {
    // tflite 패키지의 close는 detector에서 처리
  }
}
