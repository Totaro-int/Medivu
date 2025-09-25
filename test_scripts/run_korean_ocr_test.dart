import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../lib/utils/korean_ocr_tester.dart';

/// 한글 OCR 테스트 실행 스크립트
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 ActFinder 한글 OCR 성능 테스트 시작');
  print('=' * 60);

  try {
    // 성능 벤치마크 테스트 실행
    await KoreanOCRTester.performanceTest();

    print('\n✅ 테스트 완료!');
    print('📱 실제 앱에서 더 자세한 테스트를 진행하세요:');
    print('   flutter run → 한글 OCR 테스트 화면 이동');

  } catch (e) {
    print('❌ 테스트 실행 중 오류: $e');
    exit(1);
  }

  exit(0);
}