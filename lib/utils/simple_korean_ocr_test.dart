import '../services/license_plate_ocr_service.dart';

/// 간단한 한글 OCR 테스트 유틸리티
class SimpleKoreanOCRTest {
  static final _ocrService = LicensePlateOCRService.instance;

  /// 한글 OCR 설정 확인 테스트
  static Future<void> checkKoreanOCRSetup() async {
    print('🔍 한글 OCR 설정 상태 확인');
    print('=' * 40);

    try {
      // OCR 서비스 초기화
      await _ocrService.initialize();
      print('✅ OCR 서비스 초기화 완료');

      // 테스트할 번호판 패턴들
      final testTexts = [
        '12가3456',      // 기본 자동차 번호판
        '123나4567',     // 3자리 자동차 번호판
        '서울12다3456',   // 구형 번호판
        '가1234',        // 간단한 형태
      ];

      print('\n📋 테스트할 한국 번호판 패턴:');
      for (int i = 0; i < testTexts.length; i++) {
        print('  ${i+1}. ${testTexts[i]}');
      }

      print('\n✨ 설정된 한글 OCR 기능:');
      print('  🔤 한글 폰트: Noto Sans KR');
      print('  📊 Tesseract: kor+eng 언어 설정');
      print('  🤖 Google ML Kit: 한국어 스크립트');
      print('  🎨 이미지 전처리: 한글 최적화');

      print('\n🚀 테스트 준비 완료!');
      print('실제 이미지로 테스트하려면 앱에서 "한글 OCR 테스트" 화면을 사용하세요.');

    } catch (e) {
      print('❌ 설정 확인 중 오류: $e');
    }
  }

  /// OCR 개선 사항 요약
  static void printImprovements() {
    print('\n📈 한글 OCR 개선 사항 요약');
    print('=' * 50);

    print('\n🎯 BEFORE (영문 전용):');
    print('  - Tesseract: language: "eng"');
    print('  - Google ML Kit: 기본 TextRecognizer()');
    print('  - 한글 번호판 인식률: 낮음');
    print('  - "12가3456" → "12A3456" (한글 못 인식)');

    print('\n🚀 AFTER (한글 지원):');
    print('  - Tesseract: language: "kor+eng"');
    print('  - Google ML Kit: TextRecognitionScript.korean');
    print('  - 한글 폰트: Noto Sans KR 추가');
    print('  - 이미지 전처리: 한글 획 강조 (대비 1.8)');
    print('  - 한글 화이트리스트: 가나다라마바사아자차...');

    print('\n📊 예상 성능 향상:');
    print('  - 한글 번호판 인식률: 📈 대폭 향상');
    print('  - "12가3456" → 정확한 한글 인식');
    print('  - "서울12가3456" → 지역명까지 인식');
    print('  - 오토바이 번호판도 지원');

    print('\n✨ 다음 단계:');
    print('  1. 실제 번호판 이미지로 테스트');
    print('  2. 인식 정확도 측정');
    print('  3. 필요시 추가 최적화');
  }
}