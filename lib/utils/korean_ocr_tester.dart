import 'dart:io';
import 'package:image/image.dart' as img;
import '../services/license_plate_ocr_service.dart';

/// 한글 OCR 성능 테스트 유틸리티
class KoreanOCRTester {
  static final _ocrService = LicensePlateOCRService.instance;

  /// 테스트용 한국 번호판 샘플 생성
  static Future<String> generateTestPlateImage(String plateNumber) async {
    try {
      // 400x200 크기의 흰색 배경 이미지 생성
      final image = img.Image(width: 400, height: 200);
      img.fill(image, color: img.ColorRgb8(255, 255, 255)); // 흰색 배경

      // 검은색 테두리 추가
      img.drawRect(image,
        x1: 10, y1: 10, x2: 390, y2: 190,
        color: img.ColorRgb8(0, 0, 0), thickness: 3);

      // 중앙에 번호판 텍스트 영역 표시 (시뮬레이션)
      img.drawRect(image,
        x1: 50, y1: 60, x2: 350, y2: 140,
        color: img.ColorRgb8(240, 240, 240));

      // 임시 파일로 저장
      final tempDir = Directory.systemTemp;
      final testImagePath = '${tempDir.path}/test_plate_${DateTime.now().millisecondsSinceEpoch}.png';
      final testFile = File(testImagePath);
      await testFile.writeAsBytes(img.encodePng(image));

      print('🖼️ 테스트 이미지 생성: $testImagePath');
      print('📝 테스트 번호판: $plateNumber');
      return testImagePath;

    } catch (e) {
      print('❌ 테스트 이미지 생성 실패: $e');
      rethrow;
    }
  }

  /// OCR 성능 비교 테스트
  static Future<void> performanceTest() async {
    print('🚀 한글 OCR 성능 비교 테스트 시작');
    print('=' * 50);

    // OCR 서비스 초기화
    await _ocrService.initialize();

    // 테스트할 번호판 패턴들
    final testPlates = [
      '12가3456',      // 기본 자동차 번호판
      '123가4567',     // 3자리 자동차 번호판
      '서울12가3456',   // 구형 번호판
      '영등포가1234',   // 오토바이 번호판
      '가1234',        // 간단한 형태
    ];

    final results = <String, Map<String, dynamic>>{};

    for (final plateNumber in testPlates) {
      print('\n🎯 테스트 중: $plateNumber');
      print('-' * 30);

      // 테스트 이미지 생성 (실제로는 사용자가 업로드한 이미지 사용)
      final testImagePath = await generateTestPlateImage(plateNumber);

      try {
        // OCR 인식 수행
        final startTime = DateTime.now();
        final result = await _ocrService.recognizeLicensePlate(testImagePath);
        final endTime = DateTime.now();
        final processingTime = endTime.difference(startTime);

        // 결과 저장
        results[plateNumber] = {
          'expected': plateNumber,
          'recognized': result?.plateNumber ?? '인식 실패',
          'confidence': result?.confidence ?? 0.0,
          'processing_time': processingTime.inMilliseconds,
          'ocr_provider': result?.ocrProvider ?? 'unknown',
          'success': result != null,
        };

        // 결과 출력
        if (result != null) {
          print('✅ 인식 성공: ${result.plateNumber}');
          print('📊 신뢰도: ${(result.confidence! * 100).toStringAsFixed(1)}%');
          print('⚡ 처리시간: ${processingTime.inMilliseconds}ms');
          print('🔧 OCR 엔진: ${result.ocrProvider}');

          // 정확도 체크
          final isAccurate = (result.plateNumber ?? '').replaceAll(' ', '') == plateNumber.replaceAll(' ', '');
          print('🎯 정확도: ${isAccurate ? "정확" : "부정확"}');
        } else {
          print('❌ 인식 실패');
        }

      } catch (e) {
        print('❌ 테스트 오류: $e');
        results[plateNumber] = {
          'expected': plateNumber,
          'recognized': '오류 발생',
          'confidence': 0.0,
          'processing_time': -1,
          'ocr_provider': 'error',
          'success': false,
        };
      } finally {
        // 임시 파일 삭제
        try {
          await File(testImagePath).delete();
        } catch (e) {
          print('⚠️ 임시 파일 삭제 실패: $e');
        }
      }
    }

    // 전체 결과 요약
    _printSummaryReport(results);
  }

  /// 실제 이미지 파일로 테스트
  static Future<Map<String, dynamic>> testWithRealImage(String imagePath, String expectedPlate) async {
    print('🖼️ 실제 이미지 테스트: $imagePath');
    print('🎯 예상 결과: $expectedPlate');

    try {
      final startTime = DateTime.now();
      final result = await _ocrService.recognizeLicensePlate(imagePath);
      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime);

      final testResult = {
        'image_path': imagePath,
        'expected': expectedPlate,
        'recognized': result?.plateNumber ?? '인식 실패',
        'confidence': result?.confidence ?? 0.0,
        'processing_time': processingTime.inMilliseconds,
        'ocr_provider': result?.ocrProvider ?? 'unknown',
        'success': result != null,
        'raw_text': result?.rawText ?? '',
      };

      // 결과 출력
      print('📊 테스트 결과:');
      if (result != null) {
        print('  ✅ 인식 결과: ${result.plateNumber}');
        print('  📈 신뢰도: ${(result.confidence! * 100).toStringAsFixed(1)}%');
        print('  ⚡ 처리시간: ${processingTime.inMilliseconds}ms');
        print('  🔧 OCR 엔진: ${result.ocrProvider}');
        print('  📝 원본 텍스트: ${result.rawText}');

        // 정확도 평가
        final accuracy = _calculateAccuracy(expectedPlate, result.plateNumber ?? '');
        print('  🎯 정확도: ${(accuracy * 100).toStringAsFixed(1)}%');
        testResult['accuracy'] = accuracy;
      } else {
        print('  ❌ 인식 실패');
        testResult['accuracy'] = 0.0;
      }

      return testResult;

    } catch (e) {
      print('❌ 테스트 오류: $e');
      return {
        'image_path': imagePath,
        'expected': expectedPlate,
        'recognized': '오류 발생',
        'confidence': 0.0,
        'processing_time': -1,
        'ocr_provider': 'error',
        'success': false,
        'accuracy': 0.0,
        'error': e.toString(),
      };
    }
  }

  /// 정확도 계산 (문자열 유사도)
  static double _calculateAccuracy(String expected, String actual) {
    if (expected.isEmpty && actual.isEmpty) return 1.0;
    if (expected.isEmpty || actual.isEmpty) return 0.0;

    final exp = expected.replaceAll(' ', '').toLowerCase();
    final act = actual.replaceAll(' ', '').toLowerCase();

    if (exp == act) return 1.0;

    // 레벤슈타인 거리를 이용한 유사도 계산
    final maxLen = exp.length > act.length ? exp.length : act.length;
    final distance = _levenshteinDistance(exp, act);
    return (maxLen - distance) / maxLen;
  }

  /// 레벤슈타인 거리 계산
  static int _levenshteinDistance(String s1, String s2) {
    final matrix = List.generate(s1.length + 1,
        (i) => List.filled(s2.length + 1, 0));

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // 삭제
          matrix[i][j - 1] + 1,      // 삽입
          matrix[i - 1][j - 1] + cost // 대체
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// 테스트 결과 요약 리포트
  static void _printSummaryReport(Map<String, Map<String, dynamic>> results) {
    print('\n' + '=' * 50);
    print('📊 한글 OCR 성능 테스트 결과 요약');
    print('=' * 50);

    var totalTests = results.length;
    var successfulTests = results.values.where((r) => r['success'] == true).length;
    var avgProcessingTime = results.values
        .where((r) => r['processing_time'] > 0)
        .map((r) => r['processing_time'] as int)
        .fold(0, (a, b) => a + b) /
        results.values.where((r) => r['processing_time'] > 0).length;

    print('🎯 총 테스트: $totalTests개');
    print('✅ 성공: $successfulTests개');
    print('❌ 실패: ${totalTests - successfulTests}개');
    print('📈 성공률: ${(successfulTests / totalTests * 100).toStringAsFixed(1)}%');
    print('⚡ 평균 처리시간: ${avgProcessingTime.toStringAsFixed(0)}ms');

    print('\n📋 상세 결과:');
    print('-' * 50);

    results.forEach((plate, result) {
      final status = result['success'] ? '✅' : '❌';
      final confidence = result['confidence'] is double ?
          ((result['confidence'] as double) * 100).toStringAsFixed(1) : '0.0';

      print('$status $plate → ${result["recognized"]} (${confidence}%, ${result["processing_time"]}ms)');
    });

    // OCR 엔진별 성능 분석
    final ocrProviders = <String, List<Map<String, dynamic>>>{};
    results.values.forEach((result) {
      final provider = result['ocr_provider'] as String;
      ocrProviders[provider] ??= [];
      ocrProviders[provider]!.add(result);
    });

    if (ocrProviders.length > 1) {
      print('\n🔧 OCR 엔진별 성능:');
      print('-' * 30);

      ocrProviders.forEach((provider, results) {
        final successCount = results.where((r) => r['success'] == true).length;
        final avgTime = results
            .where((r) => r['processing_time'] > 0)
            .map((r) => r['processing_time'] as int)
            .fold(0, (a, b) => a + b) /
            results.where((r) => r['processing_time'] > 0).length;

        print('$provider: ${successCount}/${results.length} 성공 (${avgTime.toStringAsFixed(0)}ms 평균)');
      });
    }

    print('\n' + '=' * 50);
  }
}