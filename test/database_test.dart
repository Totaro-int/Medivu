import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:medivu_app/services/database_helper.dart';
import 'package:medivu_app/services/local_database_service.dart';
import 'package:medivu_app/models/recording_model.dart';
import 'package:medivu_app/models/noise_data_model.dart';

void main() {
  group('Database Tests', () {
    late DatabaseHelper dbHelper;
    late LocalDatabaseService dbService;

    setUpAll(() {
      // FFI 초기화 (테스트 환경용)
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      dbHelper = DatabaseHelper.instance;
      dbService = LocalDatabaseService.instance;
    });

    test('데이터베이스 초기화 테스트', () async {
      final db = await dbHelper.database;
      expect(db.isOpen, true);
      
      // 테이블 존재 확인
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table';"
      );
      
      final tableNames = tables.map((t) => t['name']).toList();
      expect(tableNames.contains('users'), true);
      expect(tableNames.contains('sessions'), true);
      expect(tableNames.contains('noise_logs'), true);
      expect(tableNames.contains('license_plates'), true);
      expect(tableNames.contains('reports'), true);
    });

    test('사용자 생성 및 조회 테스트', () async {
      const testEmail = 'test@example.com';
      
      // 사용자 생성
      final user = await dbService.createOrGetUser(testEmail);
      expect(user.email, testEmail);
      expect(user.id.isNotEmpty, true);
      
      // 동일한 이메일로 재조회 시 같은 사용자 반환 확인
      final sameUser = await dbService.createOrGetUser(testEmail);
      expect(sameUser.id, user.id);
      expect(sameUser.email, testEmail);
    });

    test('녹화 데이터 저장 및 조회 테스트', () async {
      // 테스트 사용자 생성
      final user = await dbService.createOrGetUser('recorder@test.com');
      
      // 테스트 녹화 데이터 생성
      final noiseData = NoiseDataModel(
        currentDecibel: 65.5,
        minDecibel: 45.2,
        maxDecibel: 80.1,
        avgDecibel: 62.8,
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        endTime: DateTime.now(),
        measurementCount: 300,
        readings: List.generate(300, (i) => 50.0 + (i % 30)),
      );
      
      final recording = RecordingModel(
        id: 'test_recording_001',
        startTime: noiseData.startTime,
        endTime: noiseData.endTime,
        noiseData: noiseData,
        userId: user.id,
        status: RecordingStatus.completed,
        videoPath: '/test/path/video.mp4',
      );
      
      // 녹화 데이터 저장
      final savedId = await dbService.saveRecording(recording);
      expect(savedId.isNotEmpty, true);
      
      // 저장된 데이터 조회
      final recordings = await dbService.getUserRecordings(user.id);
      expect(recordings.length, 1);
      expect(recordings.first.userId, user.id);
      expect(recordings.first.noiseData.maxDecibel, 80.1);
      expect(recordings.first.videoPath, '/test/path/video.mp4');
    });

    test('소음 로그 데이터 확인', () async {
      final user = await dbService.createOrGetUser('noisetest@test.com');
      
      final testReadings = [45.5, 67.2, 73.1, 58.9, 62.3];
      final noiseData = NoiseDataModel(
        currentDecibel: testReadings.last,
        minDecibel: testReadings.reduce((a, b) => a < b ? a : b),
        maxDecibel: testReadings.reduce((a, b) => a > b ? a : b),
        avgDecibel: testReadings.reduce((a, b) => a + b) / testReadings.length,
        startTime: DateTime.now().subtract(const Duration(seconds: 30)),
        endTime: DateTime.now(),
        measurementCount: testReadings.length,
        readings: testReadings,
      );
      
      final recording = RecordingModel(
        id: 'noise_test_001',
        startTime: noiseData.startTime,
        endTime: noiseData.endTime,
        noiseData: noiseData,
        userId: user.id,
        status: RecordingStatus.completed,
      );
      
      await dbService.saveRecording(recording);
      
      // 조회된 데이터의 소음 로그 확인
      final recordings = await dbService.getUserRecordings(user.id);
      final retrievedRecording = recordings.first;
      
      expect(retrievedRecording.noiseData.readings.length, testReadings.length);
      expect(retrievedRecording.noiseData.maxDecibel, 73.1);
      expect(retrievedRecording.noiseData.minDecibel, 45.5);
    });

    tearDown(() async {
      // 테스트 후 데이터 정리
      await dbHelper.clearDatabase();
    });
  });
}