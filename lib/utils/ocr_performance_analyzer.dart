import 'dart:math';
import '../services/license_plate_ocr_service.dart';

/// OCR 엔진 성능 분석 및 최적 전략 결정
class OCRPerformanceAnalyzer {

  /// OCR 엔진별 특성 분석
  static Map<String, OCREngineProfile> analyzeEngineProfiles() {
    return {
      'google_mlkit': OCREngineProfile(
        name: 'Google ML Kit',
        strengths: [
          '한국어 스크립트 특화',
          '빠른 처리 속도',
          '낮은 메모리 사용량',
          '온디바이스 처리',
          'Flutter 네이티브 통합'
        ],
        weaknesses: [
          '복잡한 배경에서 정확도 저하',
          '작은 텍스트 인식 어려움',
          '이미지 품질에 민감'
        ],
        idealConditions: [
          '깔끔한 배경',
          '적당한 크기의 텍스트',
          '좋은 조명'
        ],
        avgProcessingTime: 200, // ms
        memoryUsage: 'Low',
        accuracy: 0.85,
        koreanSupport: 0.9,
      ),

      'tesseract': OCREngineProfile(
        name: 'Tesseract',
        strengths: [
          '높은 정확도',
          '다양한 폰트 지원',
          '복잡한 배경 처리',
          '세밀한 설정 가능',
          '오픈소스'
        ],
        weaknesses: [
          '느린 처리 속도',
          '높은 메모리 사용량',
          '초기화 시간 필요',
          '설정 복잡성'
        ],
        idealConditions: [
          '복잡한 배경',
          '작은 텍스트',
          '다양한 폰트'
        ],
        avgProcessingTime: 800, // ms
        memoryUsage: 'High',
        accuracy: 0.92,
        koreanSupport: 0.88,
      ),
    };
  }

  /// 상황별 최적 OCR 전략 결정
  static OCRStrategy determineOptimalStrategy({
    required String imageCondition,
    required int targetProcessingTime,
    required double accuracyThreshold,
    required bool batteryOptimized,
  }) {
    final profiles = analyzeEngineProfiles();

    // 이미지 조건별 점수 계산
    Map<String, double> engineScores = {};

    profiles.forEach((engineName, profile) {
      double score = 0.0;

      // 정확도 가중치 (40%)
      score += (profile.accuracy * 0.4);

      // 한글 지원 가중치 (30%)
      score += (profile.koreanSupport * 0.3);

      // 속도 가중치 (20%)
      double speedScore = targetProcessingTime <= 500 ?
          (1000 - profile.avgProcessingTime) / 1000 : 0.5;
      score += (speedScore * 0.2);

      // 배터리 최적화 가중치 (10%)
      if (batteryOptimized) {
        score += profile.memoryUsage == 'Low' ? 0.1 : 0.0;
      } else {
        score += 0.05;
      }

      // 이미지 조건 보정
      score *= _getConditionMultiplier(imageCondition, profile);

      engineScores[engineName] = score;
    });

    // 최고 점수 엔진 선택
    final bestEngine = engineScores.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    return OCRStrategy(
      primaryEngine: bestEngine.key,
      fallbackEngine: engineScores.keys
          .where((k) => k != bestEngine.key)
          .first,
      confidence: bestEngine.value,
      reasoning: _generateReasoning(bestEngine.key, profiles[bestEngine.key]!),
    );
  }

  /// 이미지 조건별 점수 배수 계산
  static double _getConditionMultiplier(String condition, OCREngineProfile profile) {
    switch (condition.toLowerCase()) {
      case 'clean': // 깔끔한 배경
        return profile.name == 'Google ML Kit' ? 1.2 : 1.0;
      case 'complex': // 복잡한 배경
        return profile.name == 'Tesseract' ? 1.3 : 0.8;
      case 'small_text': // 작은 텍스트
        return profile.name == 'Tesseract' ? 1.2 : 0.9;
      case 'poor_lighting': // 나쁜 조명
        return profile.name == 'Tesseract' ? 1.1 : 0.85;
      default:
        return 1.0;
    }
  }

  /// 결정 이유 생성
  static String _generateReasoning(String engineName, OCREngineProfile profile) {
    final reasons = <String>[];

    if (engineName == 'google_mlkit') {
      reasons.add('빠른 처리 속도 (${profile.avgProcessingTime}ms)');
      reasons.add('한국어 스크립트 특화');
      reasons.add('낮은 배터리 소모');
    } else {
      reasons.add('높은 정확도 (${(profile.accuracy * 100).toInt()}%)');
      reasons.add('복잡한 이미지 처리 우수');
      reasons.add('세밀한 텍스트 인식');
    }

    return reasons.join(', ');
  }

  /// 하이브리드 전략 제안
  static HybridOCRStrategy proposeHybridStrategy() {
    return HybridOCRStrategy(
      primaryConditions: {
        'google_mlkit': [
          '깔끔한 배경의 번호판',
          '표준 크기 텍스트',
          '좋은 조명',
          '빠른 처리 필요'
        ],
        'tesseract': [
          '복잡한 배경',
          '작거나 흐린 텍스트',
          '정확도가 중요한 경우',
          '처리 시간 여유'
        ]
      },
      fallbackRules: [
        'ML Kit 실패 시 → Tesseract 시도',
        '신뢰도 < 0.7 → 다른 엔진 시도',
        '전처리 후 재시도',
        '최종적으로 두 결과 조합'
      ],
      performanceTarget: OCRPerformanceTarget(
        accuracy: 0.9,
        maxProcessingTime: 3000,
        batteryEfficient: true,
      ),
    );
  }

  /// 실시간 성능 모니터링 분석
  static OCRPerformanceReport analyzeRuntimePerformance(
    List<Map<String, dynamic>> testResults
  ) {
    if (testResults.isEmpty) {
      return OCRPerformanceReport.empty();
    }

    // 엔진별 결과 분류
    final mlkitResults = testResults
        .where((r) => r['ocr_provider'].toString().contains('mlkit'))
        .toList();
    final tesseractResults = testResults
        .where((r) => r['ocr_provider'].toString().contains('tesseract'))
        .toList();

    return OCRPerformanceReport(
      mlkitStats: _calculateEngineStats(mlkitResults),
      tesseractStats: _calculateEngineStats(tesseractResults),
      recommendation: _generateRecommendation(mlkitResults, tesseractResults),
      totalTests: testResults.length,
      analysisDate: DateTime.now(),
    );
  }

  /// 엔진별 통계 계산
  static EngineStats _calculateEngineStats(List<Map<String, dynamic>> results) {
    if (results.isEmpty) {
      return EngineStats.empty();
    }

    final successes = results.where((r) => r['success'] == true).length;
    final avgTime = results
        .where((r) => r['processing_time'] > 0)
        .map((r) => r['processing_time'] as int)
        .fold(0, (a, b) => a + b) /
        max(1, results.where((r) => r['processing_time'] > 0).length);

    final avgConfidence = results
        .where((r) => r['confidence'] is double)
        .map((r) => r['confidence'] as double)
        .fold(0.0, (a, b) => a + b) /
        max(1, results.where((r) => r['confidence'] is double).length);

    return EngineStats(
      successRate: successes / results.length,
      avgProcessingTime: avgTime.toInt(),
      avgConfidence: avgConfidence,
      totalTests: results.length,
    );
  }

  /// 추천 사항 생성
  static String _generateRecommendation(
    List<Map<String, dynamic>> mlkitResults,
    List<Map<String, dynamic>> tesseractResults
  ) {
    if (mlkitResults.isEmpty && tesseractResults.isEmpty) {
      return '테스트 데이터가 부족합니다.';
    }

    final mlkitStats = _calculateEngineStats(mlkitResults);
    final tesseractStats = _calculateEngineStats(tesseractResults);

    final recommendations = <String>[];

    // 성공률 비교
    if (mlkitStats.successRate > tesseractStats.successRate + 0.1) {
      recommendations.add('Google ML Kit가 더 안정적');
    } else if (tesseractStats.successRate > mlkitStats.successRate + 0.1) {
      recommendations.add('Tesseract가 더 정확');
    }

    // 속도 비교
    if (mlkitStats.avgProcessingTime < tesseractStats.avgProcessingTime - 200) {
      recommendations.add('ML Kit가 더 빠름');
    }

    // 종합 추천
    if (mlkitStats.successRate >= 0.8 && mlkitStats.avgProcessingTime < 1000) {
      recommendations.add('일반적으로 ML Kit 우선 사용 권장');
    } else if (tesseractStats.successRate >= 0.9) {
      recommendations.add('정확도가 중요한 경우 Tesseract 사용');
    }

    return recommendations.isEmpty ?
        '두 엔진 모두 균등한 성능' :
        recommendations.join(', ');
  }
}

/// OCR 엔진 프로필
class OCREngineProfile {
  final String name;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> idealConditions;
  final int avgProcessingTime;
  final String memoryUsage;
  final double accuracy;
  final double koreanSupport;

  OCREngineProfile({
    required this.name,
    required this.strengths,
    required this.weaknesses,
    required this.idealConditions,
    required this.avgProcessingTime,
    required this.memoryUsage,
    required this.accuracy,
    required this.koreanSupport,
  });
}

/// OCR 전략
class OCRStrategy {
  final String primaryEngine;
  final String fallbackEngine;
  final double confidence;
  final String reasoning;

  OCRStrategy({
    required this.primaryEngine,
    required this.fallbackEngine,
    required this.confidence,
    required this.reasoning,
  });
}

/// 하이브리드 OCR 전략
class HybridOCRStrategy {
  final Map<String, List<String>> primaryConditions;
  final List<String> fallbackRules;
  final OCRPerformanceTarget performanceTarget;

  HybridOCRStrategy({
    required this.primaryConditions,
    required this.fallbackRules,
    required this.performanceTarget,
  });
}

/// 성능 목표
class OCRPerformanceTarget {
  final double accuracy;
  final int maxProcessingTime;
  final bool batteryEfficient;

  OCRPerformanceTarget({
    required this.accuracy,
    required this.maxProcessingTime,
    required this.batteryEfficient,
  });
}

/// 엔진 통계
class EngineStats {
  final double successRate;
  final int avgProcessingTime;
  final double avgConfidence;
  final int totalTests;

  EngineStats({
    required this.successRate,
    required this.avgProcessingTime,
    required this.avgConfidence,
    required this.totalTests,
  });

  static EngineStats empty() => EngineStats(
    successRate: 0.0,
    avgProcessingTime: 0,
    avgConfidence: 0.0,
    totalTests: 0,
  );
}

/// 성능 리포트
class OCRPerformanceReport {
  final EngineStats mlkitStats;
  final EngineStats tesseractStats;
  final String recommendation;
  final int totalTests;
  final DateTime analysisDate;

  OCRPerformanceReport({
    required this.mlkitStats,
    required this.tesseractStats,
    required this.recommendation,
    required this.totalTests,
    required this.analysisDate,
  });

  static OCRPerformanceReport empty() => OCRPerformanceReport(
    mlkitStats: EngineStats.empty(),
    tesseractStats: EngineStats.empty(),
    recommendation: '데이터 없음',
    totalTests: 0,
    analysisDate: DateTime.now(),
  );
}