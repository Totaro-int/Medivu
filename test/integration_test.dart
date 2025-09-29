import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:noise0/providers/recording_provider.dart';
import 'package:noise0/providers/noise_provider.dart';
import 'package:noise0/providers/auth_provider.dart';
import 'package:noise0/services/local_database_service.dart';
import 'package:noise0/models/noise_data_model.dart';

void main() {
  group('Integration Tests', () {
    late RecordingProvider recordingProvider;
    late NoiseProvider noiseProvider;
    late AuthProvider authProvider;

    setUpAll(() {
      // FFI 초기화 (테스트 환경용)
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      recordingProvider = RecordingProvider.instance;
      noiseProvider = NoiseProvider.instance;
      authProvider = AuthProvider.instance;
    });

    test('전체 워크플로우 테스트', () async {
      // 1. 사용자 로그인
      final loginSuccess = await authProvider.login('test@integration.com', 'password123');
      expect(loginSuccess, true);
      expect(authProvider.isLoggedIn, true);
      
      // 2. RecordingProvider 초기화
      await recordingProvider.initialize();
      expect(recordingProvider.recordingCount >= 0, true);
      
      // 3. 새 녹화 세션 시작
      final sessionStarted = await recordingProvider.startNewSession();
      expect(sessionStarted, true);
      expect(recordingProvider.hasActiveSession, true);
      
      // 4. 소음 측정 시작
      final noiseStarted = await recordingProvider.startNoiseListening();
      expect(noiseStarted, true);
      expect(recordingProvider.isNoiseListening, true);
      
      // 5. 모의 소음 데이터 추가
      for (int i = 0; i < 10; i++) {
        final mockDecibel = 50.0 + (i * 2.5); // 50-72.5 dB
        recordingProvider.updateNoiseReading(mockDecibel);
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // 6. 소음 데이터 확인
      expect(recordingProvider.currentNoiseData?.measurementCount, 10);
      expect(recordingProvider.currentNoiseData?.maxDecibel, 72.5);
      expect(recordingProvider.currentNoiseData?.minDecibel, 50.0);
      
      // 7. 녹화 세션 종료
      recordingProvider.endCurrentSession();
      expect(recordingProvider.hasActiveSession, false);
      expect(recordingProvider.isNoiseListening, false);
    });

    test('NoiseProvider 단독 테스트', () async {
      // NoiseProvider 초기화 확인
      expect(noiseProvider.isInitialized, false);
      expect(noiseProvider.isListening, false);
      
      // 측정 데이터 초기 상태 확인
      expect(noiseProvider.measurementCount, 0);
      expect(noiseProvider.currentDecibel, 0.0);
      
      // 통계 정보 확인
      final stats = noiseProvider.statistics;
      expect(stats['count'], 0);
      expect(stats['current'], '0.0');
    });

    test('데이터 저장 및 조회 통합 테스트', () async {
      // 사용자 로그인
      await authProvider.login('data@test.com', 'password123');
      
      // 녹화 세션 생성 및 데이터 추가
      await recordingProvider.startNewSession();
      await recordingProvider.startNoiseListening();
      
      // 테스트 데이터 생성
      final testReadings = [45.2, 67.8, 73.1, 58.9, 62.3, 80.5];
      for (final reading in testReadings) {
        recordingProvider.updateNoiseReading(reading);
      }
      
      // 현재 녹화 데이터 확인
      final currentRecording = recordingProvider.currentRecording;
      expect(currentRecording?.noiseData.readings.length, testReadings.length);
      expect(currentRecording?.noiseData.maxDecibel, 80.5);
      expect(currentRecording?.noiseData.minDecibel, 45.2);
      
      // 평균 계산 확인
      final expectedAvg = testReadings.reduce((a, b) => a + b) / testReadings.length;
      expect(currentRecording?.noiseData.avgDecibel, closeTo(expectedAvg, 0.1));
      
      recordingProvider.endCurrentSession();
    });

    test('에러 처리 테스트', () async {
      // 로그인 없이 세션 시작 시도
      authProvider.logout();
      final sessionStarted = await recordingProvider.startNewSession();
      expect(sessionStarted, false);
      expect(recordingProvider.error?.contains('Login') ?? recordingProvider.error?.contains('로그인'), true);
      
      // 유효하지 않은 소음 데이터 처리
      await authProvider.login('error@test.com', 'password123');
      await recordingProvider.startNewSession();
      await recordingProvider.startNoiseListening();
      
      // NaN 값 처리 확인
      final beforeCount = recordingProvider.currentNoiseData?.measurementCount ?? 0;
      recordingProvider.updateNoiseReading(double.nan);
      recordingProvider.updateNoiseReading(double.infinity);
      
      // 유효하지 않은 값은 추가되지 않아야 함
      expect(recordingProvider.currentNoiseData?.measurementCount, beforeCount);
      
      recordingProvider.endCurrentSession();
    });

    tearDown(() async {
      // 각 테스트 후 상태 정리
      recordingProvider.endCurrentSession();
      await noiseProvider.stopListening();
      await authProvider.logout();
      await LocalDatabaseService.instance.clearAllData();
    });
  });
}