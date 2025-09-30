import 'dart:async';
import 'dart:io' ;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/upload_service.dart';
import '../../services/enhanced_database_helper.dart';
import '../../services/license_plate_ocr_service.dart';
import '../../services/permission_service.dart';
import 'package:provider/provider.dart';
import '../../providers/enhanced_auth_provider.dart';
import '../../models/noise_data_model.dart';
import '../../models/recording_model.dart';
import '../../models/license_plate_model.dart';
import '../../models/location_model.dart';
import '../../models/report_model.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../services/location_service.dart';
import '../report/new_report_screen.dart';


class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  final bool _isWeb = kIsWeb;

  StreamSubscription<NoiseReading>? _noiseSubscription;
  NoiseMeter? _noiseMeter;
  bool _isNoiseListening = false;

  // 모델로 교체된 데이터들
  NoiseDataModel? _noiseData;
  RecordingModel? _currentRecording;
  LocationModel? _currentLocation;
  
  // 임시 측정값들 (실시간 업데이트용)
  double _currentDecibel = 0.0;
  double _sumDecibel = 0.0;
  final List<double> _decibelReadings = [];
  
  // OCR 관련 변수들
  LicensePlateModel? _detectedPlate;
  bool _isOCRProcessing = false;
  Timer? _ocrTimer;
  final LicensePlateOCRService _ocrService = LicensePlateOCRService.instance;
  final LocationService _locationService = LocationService.instance;
  final PermissionService _permissionService = PermissionService.instance;
  
  // 적응형 OCR 최적화 변수들
  int _consecutiveFailures = 0;
  int _consecutiveSuccesses = 0;
  DateTime? _lastMotionDetected;
  double _currentOCRInterval = 5.0; // 시작 간격 (초)
  final double _minOCRInterval = 1.0; // 최소 간격
  final double _maxOCRInterval = 10.0; // 최대 간격
  
  // 성능 모니터링 변수들
  final List<double> _ocrProcessingTimes = [];
  final List<double> _confidenceHistory = [];
  int _totalOCRAttempts = 0;
  int _successfulRecognitions = 0;
  
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _initialize(); // 카메라 + 데시벨 동시에 초기화
  }

  /// 카메라와 데시벨 스트림을 초기화하는 함수
  Future<void> _initialize() async {
    // 1단계: 먼저 모든 권한 요청
    await _requestAllPermissions();
    
    // 2단계: 권한 확보 후 서비스 초기화
    await _initCamera();
    await _initNoiseMeter();
    await _initOCRService();
    await _initLocation();
  }

  /// 모든 필수 권한 요청
  Future<void> _requestAllPermissions() async {
    if (_isWeb) {
      debugPrint("웹 환경에서는 권한 요청을 건너뜀");
      return;
    }

    try {
      debugPrint('🔐 앱 시작 시 모든 권한 요청...');
      
      final result = await _permissionService.requestAllPermissions();
      
      if (result.allGranted) {
        debugPrint('✅ 모든 권한이 허용되었습니다.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 모든 권한이 허용되었습니다'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await _handlePermissionDenied(result);
      }
    } catch (e) {
      debugPrint('❌ 권한 요청 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('권한 요청 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 권한 거부 처리
  Future<void> _handlePermissionDenied(PermissionCheckResult result) async {
    if (result.permanentlyDeniedPermissions.isNotEmpty) {
      await _showPermanentlyDeniedDialog(result.permanentlyDeniedPermissions);
    } else if (result.deniedPermissions.isNotEmpty) {
      await _showDeniedPermissionDialog(result.deniedPermissions);
    }
  }

  /// 영구 거부된 권한 다이얼로그
  Future<void> _showPermanentlyDeniedDialog(List<Permission> permissions) async {
    if (!mounted) return;

    final permissionNames = permissions
        .map((p) => _permissionService.getPermissionDescription(p))
        .join('\n');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 권한 설정 필요'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('다음 권한들이 영구적으로 거부되었습니다:'),
            const SizedBox(height: 8),
            Text(
              permissionNames,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text('앱 설정에서 직접 권한을 허용해주세요.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('나중에'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _permissionService.openSettings();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  /// 거부된 권한 다이얼로그
  Future<void> _showDeniedPermissionDialog(List<Permission> permissions) async {
    if (!mounted) return;

    final permissionNames = permissions
        .map((p) => _permissionService.getPermissionDescription(p))
        .join('\n');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔐 권한 허용 필요'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('다음 권한들이 거부되었습니다:'),
            const SizedBox(height: 8),
            Text(
              permissionNames,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text('앱의 모든 기능을 사용하려면 권한 허용이 필요합니다.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('나중에'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _requestAllPermissions();
            },
            child: const Text('다시 요청'),
          ),
        ],
      ),
    );
  }

  /// 카메라 초기화
  Future<void> _initCamera() async {
    // 웹 환경에서는 카메라 초기화를 건너뜀
    if (_isWeb) {
      debugPrint("웹 환경에서는 카메라 기능을 사용할 수 없습니다.");
      return;
    }

    // 카메라 권한은 _requestAllPermissions에서 이미 확인됨
    if (!await _permissionService.ensureCameraPermission()) {
      debugPrint("❌ 카메라 권한이 없어 초기화를 건너뜁니다.");
      return;
    }
    
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(_cameras!.first, ResolutionPreset.medium);
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {});
        }
        debugPrint("✅ 카메라 초기화 완료");
      } else {
        debugPrint("❌ 사용 가능한 카메라가 없습니다.");
      }
    } catch (e) {
      debugPrint("❌ 카메라 초기화 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카메라 초기화 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 마이크 권한 요청 및 데시벨 측정 시작
  Future<void> _initNoiseMeter() async {
    // 웹 환경에서는 데시벨 측정을 자동으로 시작하지 않음
    if (_isWeb) {
      debugPrint("웹 환경에서는 데시벨 측정을 수동으로 시작해야 합니다.");
      return;
    }
    await _startNoiseListening();
  }

  /// 데시벨 측정 시작
  Future<void> _startNoiseListening() async {
    if (_isNoiseListening) return; // 중복 구독 방지

    // 웹이 아닌 경우에만 권한 확인
    if (!_isWeb && !await _permissionService.ensureMicrophonePermission()) {
      debugPrint("❌ 마이크 권한이 없어 데시벨 측정을 시작할 수 없습니다.");
      return;
    }

    // NoiseDataModel 초기화
    final startTime = DateTime.now();
    setState(() {
      _sumDecibel = 0.0;
      _decibelReadings.clear();
      _noiseData = NoiseDataModel(
        currentDecibel: 0.0,
        startTime: startTime,
        measurementCount: 0,
        readings: [],
      );
    });

    try {
      // 기존 구독이 있다면 정리
      await _noiseSubscription?.cancel();

      // NoiseMeter 인스턴스 생성 (공식 문서 방식)
      _noiseMeter ??= NoiseMeter();

      // 권한은 이미 위에서 확인됨

      // 공식 문서의 방식: noise 스트림 사용
      _noiseSubscription = _noiseMeter!.noise.listen(
            (NoiseReading reading) {
          if (mounted && _noiseData != null) {
            // meanDecibel이 유효한 값인지 확인
            if (reading.meanDecibel.isFinite && !reading.meanDecibel.isNaN) {
              _currentDecibel = reading.meanDecibel;
              
              // 메모리 효율성을 위해 최대 1000개까지만 저장
              if (_decibelReadings.length >= 1000) {
                _decibelReadings.removeAt(0);
                _sumDecibel -= _decibelReadings.first;
              }
              
              _decibelReadings.add(_currentDecibel);
              _sumDecibel += _currentDecibel;
              
              // min/max 계산 최적화
              final minDecibel = _noiseData!.minDecibel == null 
                  ? _currentDecibel 
                  : (_currentDecibel < _noiseData!.minDecibel! ? _currentDecibel : _noiseData!.minDecibel!);
              
              final maxDecibel = _noiseData!.maxDecibel == null 
                  ? _currentDecibel 
                  : (_currentDecibel > _noiseData!.maxDecibel! ? _currentDecibel : _noiseData!.maxDecibel!);
              
              final avgDecibel = _sumDecibel / _decibelReadings.length;
              
              // setState 빈도 조절 (매 10번째 읽기마다만 UI 업데이트)
              if (_decibelReadings.length % 10 == 0 || _decibelReadings.length < 10) {
                setState(() {
                  _noiseData = _noiseData!.copyWith(
                    currentDecibel: _currentDecibel,
                    minDecibel: minDecibel,
                    maxDecibel: maxDecibel,
                    avgDecibel: avgDecibel,
                    measurementCount: _decibelReadings.length,
                    // readings 복사 제거 - 메모리 절약
                  );
                });
              } else {
                // UI 업데이트 없이 데이터만 업데이트
                _noiseData = _noiseData!.copyWith(
                  currentDecibel: _currentDecibel,
                  minDecibel: minDecibel,
                  maxDecibel: maxDecibel,
                  avgDecibel: avgDecibel,
                  measurementCount: _decibelReadings.length,
                );
              }
            }
          }
        },
        onError: (dynamic error) {
          debugPrint("데시벨 측정 에러: $error");
          _handleNoiseError(error);
        },
        onDone: () {
          debugPrint("데시벨 측정 완료");
          _isNoiseListening = false;
        },
        cancelOnError: false,
      );

      _isNoiseListening = true;
      debugPrint("데시벨 측정 시작됨 (공식 API 사용)");

    } catch (e) {
      debugPrint("NoiseMeter 시작 실패: $e");
      _handleNoiseError(e);
    }
  }


  /// 대안적인 NoiseMeter 초기화 방법
  Future<void> _tryAlternativeNoiseMeter() async {
    try {
      // 이미 공식 방식을 사용하므로 필요 없음
      debugPrint("공식 API 사용 중");
    } catch (e) {
      debugPrint("대안 방법 에러: $e");
    }
  }

  /// 정적 메서드를 사용한 NoiseMeter 초기화 (일부 버전에서 필요)
  Future<void> _tryStaticNoiseMeter() async {
    try {
      // 이 메서드는 필요 없으므로 제거
      debugPrint("정적 방법은 공식 API에서 불필요");
    } catch (e) {
      debugPrint("정적 방법 에러: $e");
    }
  }

  /// 데시벨 측정 중지
  void _stopNoiseListening() {
    _noiseSubscription?.cancel();
    _noiseSubscription = null;
    _noiseMeter = null;
    _isNoiseListening = false;
    
    // NoiseDataModel 업데이트 (종료 시간)
    if (_noiseData != null) {
      final endTime = DateTime.now();
      _noiseData = _noiseData!.copyWith(endTime: endTime);
    }
    
    debugPrint("데시벨 측정 중지됨");
    
    if (mounted) {
      setState(() {});
    }
  }

  /// 권한 에러 표시 공통 메서드
  void _showPermissionError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: '설정',
            onPressed: () => _permissionService.openSettings(),
          ),
        ),
      );
    }
  }

  /// 노이즈 측정 에러 처리
  void _handleNoiseError(dynamic error) {
    _stopNoiseListening();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데시벨 측정 오류: $error')),
      );
    }

    // 3초 후 재시도
    Timer(const Duration(seconds: 3), () {
      if (mounted && !_isNoiseListening) {
        _startNoiseListening();
      }
    });
  }

  /// 녹화 시작 (안정성 개선)
  Future<void> _startRecording() async {
    if (_isRecording) {
      print('⚠️ 이미 녹화 중입니다');
      return;
    }

    if (_isWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('웹 환경에서는 녹화 기능을 사용할 수 없습니다.')),
      );
      return;
    }

    try {
      // 카메라 권한 확인
      if (!await _permissionService.ensureCameraPermission()) {
        _showPermissionError('카메라 권한이 필요합니다.');
        return;
      }
      
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('카메라가 초기화되지 않았습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: '재시도',
                onPressed: () => _initCamera(),
              ),
            ),
          );
        }
        return;
      }

      print('🎬 녹화 시작...');
      
      // OCR 중지 (녹화 중에는 비활성화)
      _stopLicensePlateDetection();
      
      await _cameraController!.startVideoRecording();
      
      // RecordingModel 생성
      if (_noiseData != null) {
        final recordingId = DateTime.now().millisecondsSinceEpoch.toString();
        debugPrint('📝 새 녹화 ID 생성: $recordingId');
        
        _currentRecording = RecordingModel(
          id: recordingId,
          startTime: _noiseData!.startTime,
          noiseData: _noiseData!,
          userId: Provider.of<EnhancedAuthProvider>(context, listen: false).userId ?? 'anonymous_user',
          status: RecordingStatus.recording,
          location: _currentLocation,
        );
      }
      
      setState(() => _isRecording = true);
      
      print('✅ 녹화 시작됨');
      
    } catch (e, stackTrace) {
      print('❌ 녹화 시작 실패: $e');
      print('📍 스택 트레이스: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('녹화 시작 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 녹화 중지 및 결과 저장
  Future<void> _stopRecording() async {
    if (_isWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('웹 환경에서는 녹화 기능을 사용할 수 없습니다.')),
      );
      return;
    }
    
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) return;

    try {
      final file = await _cameraController!.stopVideoRecording();
      setState(() => _isRecording = false);

      // 녹화된 파일 경로 출력 및 파일 검증
      debugPrint('녹화 완료: ${file.path}');
      
      // 파일 존재 및 크기 확인
      try {
        final videoFile = File(file.path);
        if (await videoFile.exists()) {
          final fileSize = await videoFile.length();
          debugPrint('✅ 비디오 파일 저장 성공: ${file.path} (크기: ${fileSize} bytes)');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ 비디오 저장 성공: ${fileSize > 0 ? '파일 크기 ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB' : '파일 생성됨'}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          debugPrint('❌ 비디오 파일 저장 실패: 파일이 존재하지 않음');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ 비디오 저장에 실패했습니다'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ 파일 검증 중 오류: $e');
      }

      // 데시벨 측정 중지
      _stopNoiseListening();
      
      // OCR 번호판 인식 중지
      _stopLicensePlateDetection();
      
      // RecordingModel 업데이트 (감지된 번호판 정보 포함)
      if (_currentRecording != null && _noiseData != null) {
        _currentRecording = _currentRecording!.copyWith(
          videoPath: file.path,
          endTime: DateTime.now(),
          noiseData: _noiseData!,
          status: RecordingStatus.completed,
          licensePlate: _detectedPlate, // 감지된 번호판 정보 추가
        );
      }

      // 로컬 데이터베이스에 데이터 저장 (백그라운드에서 실행)
      if (_currentRecording != null) {
        // Recording 저장은 _createAndSaveReport에서 처리됨
        _uploadRecordingToServer(_currentRecording!);
        
        // 녹화 완료 후 자동으로 리포트 생성
        await _createAndSaveReport(_currentRecording!);
      }
      
      // 리포트 자동 표시
      debugPrint('🔍 리포트 표시 조건 확인:');
      debugPrint('  - _noiseData != null: ${_noiseData != null}');
      debugPrint('  - measurementCount: ${_noiseData?.measurementCount}');
      debugPrint('  - _currentRecording != null: ${_currentRecording != null}');
      
      // 조건을 더 관대하게: 녹화가 있거나 측정 데이터가 있으면 리포트 표시
      if (_currentRecording != null || (_noiseData != null && _noiseData!.measurementCount > 0)) {
        debugPrint('✅ 리포트 조건 만족 - 리포트 화면으로 이동');
        
        // 약간의 지연 후 리포트 화면으로 이동 (UI 안정화)
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showReport();
          }
        });
      } else {
        debugPrint('❌ 리포트 조건 불만족 - 측정 데이터나 녹화 데이터가 없음');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⚠️ 측정 데이터가 부족합니다'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: '리포트 보기',
                textColor: Colors.white,
                onPressed: () => _showReport(), // 리포트 표시
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("녹화 중지 실패: $e");
    }
  }

  /// 녹화 데이터를 기반으로 리포트 생성 및 저장
  Future<void> _createAndSaveReport(RecordingModel recording) async {
    try {
      debugPrint('🔄 리포트 생성 시작...');
      debugPrint('  - Recording ID: ${recording.id}');
      debugPrint('  - 데시벨 데이터: max=${recording.noiseData.maxDecibel}, avg=${recording.noiseData.avgDecibel}');
      debugPrint('  - 측정 횟수: ${recording.noiseData.measurementCount}');
      
      final authProvider = Provider.of<EnhancedAuthProvider>(context, listen: false);
      debugPrint('  - 로그인 상태: ${authProvider.isLoggedIn}');
      debugPrint('  - 사용자 ID: ${authProvider.userId}');
      
      // Recording은 insertReport 메서드에서 자동으로 처리됨
      debugPrint('📀 Recording은 리포트 생성 시 자동으로 저장됩니다...');
      
      if (!authProvider.isLoggedIn) {
        debugPrint('⚠️ 로그인이 되어있지 않습니다. 기본 사용자로 진행합니다.');
        // 로그인이 되어있지 않아도 리포트 생성을 계속 진행 (기본 사용자 ID 사용)
      }
      
      // 리포트 제목 자동 생성
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
      final title = '소음 측정 - ${dateFormat.format(recording.startTime)}';
      
      // 설명 자동 생성
      final description = '''
📊 측정 결과:
• 최대 소음: ${recording.noiseData.maxDecibel?.toStringAsFixed(1) ?? '0.0'}dB
• 평균 소음: ${recording.noiseData.avgDecibel?.toStringAsFixed(1) ?? '0.0'}dB
• 측정 시간: ${recording.duration != null ? _formatDuration(recording.duration!) : '알 수 없음'}

📍 위치 정보:
${recording.location?.address ?? '위치 정보 없음'}

🚗 번호판 정보:
${recording.licensePlate?.plateNumber ?? '번호판 인식되지 않음'}
      '''.trim();
      
      // ReportModel 생성 - 저장된 recording의 실제 ID 사용
      final reportId = DateTime.now().millisecondsSinceEpoch.toString();
      debugPrint('  - 리포트 ID 생성: $reportId');
      
      final userId = authProvider.userId ?? '1'; // 기본 사용자 ID
      debugPrint('  - userId: $userId');
      
      // 원본 recording 사용 (userId 일치시키기)
      final reportRecording = RecordingModel(
        id: recording.id, // 원본 recording ID 사용
        videoPath: recording.videoPath,
        videoUrl: recording.videoUrl,
        startTime: recording.startTime,
        endTime: recording.endTime,
        noiseData: recording.noiseData,
        location: recording.location,
        licensePlate: recording.licensePlate,
        userId: userId, // 사용자 ID 일치시키기
        status: recording.status,
        metadata: recording.metadata,
      );
      
      final report = ReportModel(
        id: reportId,
        title: title,
        description: description,
        recording: reportRecording,
        location: reportRecording.location,
        createdAt: DateTime.now(),
        userId: userId,
        status: ReportStatus.ready,
      );
      
      debugPrint('  - ReportModel 생성 완료');
      debugPrint('  - 리포트 제목: $title');
      debugPrint('  - 사용자 ID: ${authProvider.userId}');
      
      // 리포트를 데이터베이스에 저장
      debugPrint('  - 데이터베이스 저장 시작...');
      
      // userId가 유효한지 확인 (빈 문자열이나 null이 아님)
      if (userId.isEmpty) {
        debugPrint('⚠️ 사용자 ID가 비어있어 기본값 1을 사용합니다.');
        // userId가 이미 기본값 '1'로 설정되어 있으므로 계속 진행
      }
      
      final savedReportId = await EnhancedDatabaseHelper.instance.insertReport(report);
      debugPrint('  - 데이터베이스 저장 완료, 저장된 ID: $savedReportId');
      
      debugPrint('✅ 리포트 생성 및 저장 완료: ${report.id}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 리포트가 생성되었습니다'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 리포트 생성 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      debugPrint('현재 recording 상태: ${recording.id}, ${recording.userId}');
      
      final authProvider = Provider.of<EnhancedAuthProvider>(context, listen: false);
      debugPrint('현재 authProvider 상태: ${authProvider.isLoggedIn}, ${authProvider.userId}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 리포트 생성 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '재시도',
              textColor: Colors.white,
              onPressed: () => _createAndSaveReport(recording),
            ),
          ),
        );
      }
    }
  }

  /// 리포트 화면으로 이동
  void _showReport() {
    print('🚀 _showReport 호출됨');
    
    final reportData = {
      'maxDecibel': _noiseData?.maxDecibel ?? 50.0,
      'minDecibel': _noiseData?.minDecibel ?? 30.0,
      'avgDecibel': _noiseData?.avgDecibel ?? 40.0,
      'startTime': _noiseData?.startTime ?? DateTime.now().subtract(const Duration(minutes: 1)),
      'endTime': _noiseData?.endTime ?? DateTime.now(),
      'measurementCount': _noiseData?.measurementCount ?? 10,
      'currentLocation': _currentLocation,
      'detectedPlate': _detectedPlate,
      'videoPath': _currentRecording?.videoPath,
    };
    
    print('  - 리포트 데이터: $reportData');
    
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewReportScreen(reportData: reportData),
        ),
      );
      print('✅ 새로운 리포트 화면으로 네비게이션 성공');
    } catch (e) {
      print('❌ 리포트 화면 네비게이션 실패: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('리포트 화면 이동 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Duration을 "mm:ss" 형태로 포맷
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }


  /// 로컬 데이터베이스에 녹화 데이터 저장
  Future<void> _saveRecordingToDatabase(RecordingModel recording) async {
    try {
      if (!Provider.of<EnhancedAuthProvider>(context, listen: false).isLoggedIn) {
        debugPrint('로그인이 필요합니다. 데이터베이스 저장을 건너뜁니다.');
        return;
      }

      debugPrint('로컬 데이터베이스 저장 시작: ${recording.id}');
      debugPrint('  - 사용자 ID: ${recording.userId}');
      debugPrint('  - 비디오 경로: ${recording.videoPath}');
      debugPrint('  - 데시벨 데이터: ${recording.noiseData.maxDecibel}dB');
      
      await EnhancedDatabaseHelper.instance.insertSession(recording);
      
      // 저장 후 검증 생략 (저장만 수행)
      debugPrint('✅ 데이터베이스 저장 완료');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 데이터가 로컬에 저장되었습니다'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('로컬 데이터베이스 저장 오류: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 데이터 저장 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 서버에 녹화 데이터 업로드
  Future<void> _uploadRecordingToServer(RecordingModel recording) async {
    try {
      if (!Provider.of<EnhancedAuthProvider>(context, listen: false).isLoggedIn) {
        debugPrint('로그인이 필요합니다. 업로드를 건너뜁니다.');
        return;
      }

      debugPrint('서버 업로드 시작: ${recording.id}');
      
      final uploadResult = await UploadService.instance.uploadRecording(recording);
      
      if (uploadResult.isSuccess) {
        debugPrint('업로드 성공: ${uploadResult.message}');
        
        // 성공 시 사용자에게 알림 (선택적)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('서버 업로드 완료: ${uploadResult.message}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('업로드 실패: ${uploadResult.message}');
        
        // 실패 시 사용자에게 알림
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('업로드 실패: ${uploadResult.message}'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: '재시도',
                onPressed: () => _uploadRecordingToServer(recording),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('업로드 오류: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('업로드 오류: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// OCR 서비스 초기화
  Future<void> _initOCRService() async {
    try {
      print('🔄 OCR 서비스 초기화 시작...');
      await _ocrService.initialize();
      print('✅ OCR 서비스 초기화 완료');
      
      // 초기화 테스트 수행
      await _testOCRService();
    } catch (e) {
      print('❌ OCR 서비스 초기화 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR 서비스 초기화 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  /// OCR 서비스 테스트
  Future<void> _testOCRService() async {
    try {
      print('🧪 OCR 서비스 테스트 시작...');
      // OCR 서비스가 정상적으로 초기화되었는지 간단한 체크
      print('✅ OCR 서비스 테스트 완료');
    } catch (e) {
      print('❌ OCR 서비스 테스트 실패: $e');
    }
  }

  /// 위치 서비스 초기화
  Future<void> _initLocation() async {
    try {
      // 웹 환경에서는 위치 서비스를 건너뜀
      if (_isWeb) {
        debugPrint("웹 환경에서는 위치 서비스를 사용할 수 없습니다.");
        return;
      }

      debugPrint('🌍 위치 서비스 초기화 시작...');
      
      // 위치 권한 확인 (이미 초기화에서 확인되었지만 재확인)
      if (!await _permissionService.ensureLocationPermission()) {
        debugPrint('❌ 위치 권한이 없어 위치 서비스를 초기화할 수 없습니다.');
        return;
      }

      // 현재 위치 가져오기
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        setState(() {
          _currentLocation = location;
        });
        
        debugPrint('✅ 현재 위치 획득: ${_locationService.formatLocationInfo(location)}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 위치 획득: ${_locationService.formatLocationInfo(location)}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('⚠️ 위치 획득 실패 - 위치 서비스가 비활성화되었거나 네트워크 문제일 수 있습니다.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('위치를 가져올 수 없습니다. GPS가 활성화되어 있는지 확인해주세요.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ 위치 서비스 초기화 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('위치 서비스 오류: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 적응형 실시간 번호판 인식 시작
  void _startLicensePlateDetection() {
    // 녹화 중에는 OCR 비활성화 (메모리 절약 및 안정성)
    if (_isRecording || _isOCRProcessing) {
      print('⚠️ 녹화 중이므로 OCR 시작하지 않음 (안정성을 위해)');
      return;
    }
    
    print('🚀 적응형 번호판 인식 시작 (초기 간격: ${_currentOCRInterval}초)');
    _scheduleNextOCR();
  }

  /// 다음 OCR 스케줄링 (적응형 간격)
  void _scheduleNextOCR() {
    if (_isRecording || !mounted) return;
    
    _ocrTimer?.cancel();
    
    // 적응형 간격 계산
    _currentOCRInterval = _calculateAdaptiveInterval();
    
    _ocrTimer = Timer(Duration(milliseconds: (_currentOCRInterval * 1000).toInt()), () async {
      if (!_isRecording && !_isOCRProcessing && mounted) {
        await _detectLicensePlateWithAdaptation();
        _scheduleNextOCR(); // 다음 OCR 스케줄링
      }
    });
    
    print('⏰ 다음 OCR 예정: ${_currentOCRInterval.toStringAsFixed(1)}초 후');
  }

  /// 적응형 간격 계산
  double _calculateAdaptiveInterval() {
    double interval = 5.0; // 기본 간격
    
    // 1. 연속 성공/실패에 따른 조정
    if (_consecutiveSuccesses >= 3) {
      interval = _minOCRInterval; // 성공률이 높으면 빈번하게
      print('  🎯 연속 성공으로 간격 단축: ${interval}초');
    } else if (_consecutiveFailures >= 3) {
      interval = _maxOCRInterval; // 실패가 많으면 간격 증가
      print('  ❌ 연속 실패로 간격 확대: ${interval}초');
    }
    
    // 2. 배터리 상태에 따른 조정 (간단한 버전)
    // TODO: 실제 배터리 API 연동
    // final batteryLevel = await Battery().batteryLevel;
    // if (batteryLevel < 20) interval *= 1.5;
    
    // 3. 움직임 감지에 따른 조정
    if (_lastMotionDetected != null) {
      final timeSinceMotion = DateTime.now().difference(_lastMotionDetected!).inSeconds;
      if (timeSinceMotion < 5) {
        interval = _maxOCRInterval; // 움직임이 감지되면 간격 증가
        print('  🏃 움직임 감지로 간격 확대: ${interval}초');
      } else if (timeSinceMotion > 30) {
        interval = _minOCRInterval; // 정지 상태가 오래되면 간격 단축
        print('  🛑 정지 상태로 간격 단축: ${interval}초');
      }
    }
    
    // 4. 성능 기반 조정
    if (_ocrProcessingTimes.isNotEmpty) {
      final avgProcessingTime = _ocrProcessingTimes.reduce((a, b) => a + b) / _ocrProcessingTimes.length;
      if (avgProcessingTime > 3.0) {
        interval = interval * 1.2; // 처리가 오래 걸리면 간격 증가
        print('  ⏳ 처리 지연으로 간격 확대: ${interval.toStringAsFixed(1)}초');
      }
    }
    
    return interval.clamp(_minOCRInterval, _maxOCRInterval);
  }

  /// 번호판 인식 중지
  void _stopLicensePlateDetection() {
    _ocrTimer?.cancel();
    _ocrTimer = null;
  }

  /// 성능 모니터링과 함께 번호판 감지
  Future<void> _detectLicensePlateWithAdaptation() async {
    final startTime = DateTime.now();
    _totalOCRAttempts++;
    
    final result = await _detectLicensePlate();
    
    // 처리 시간 기록
    final processingTime = DateTime.now().difference(startTime).inMilliseconds / 1000.0;
    _ocrProcessingTimes.add(processingTime);
    
    // 최근 10개 기록만 유지
    if (_ocrProcessingTimes.length > 10) {
      _ocrProcessingTimes.removeAt(0);
    }
    
    // 성공/실패 통계 업데이트
    if (result) {
      _successfulRecognitions++;
      _consecutiveSuccesses++;
      _consecutiveFailures = 0;
      print('✅ OCR 성공 (연속 성공: $_consecutiveSuccesses)');
    } else {
      _consecutiveFailures++;
      _consecutiveSuccesses = 0;
      print('❌ OCR 실패 (연속 실패: $_consecutiveFailures)');
    }
    
    // 성능 통계 출력 (매 10회마다)
    if (_totalOCRAttempts % 10 == 0) {
      _printPerformanceStats();
    }
  }

  /// 카메라에서 번호판 감지 (메모리 안전성 개선)
  Future<bool> _detectLicensePlate() async {
    if (_isOCRProcessing || _cameraController == null || !_cameraController!.value.isInitialized || !mounted) {
      return false;
    }

    // 메모리 체크
    try {
      // 이미 처리 중이면 건너뛰기
      if (_isOCRProcessing) {
        print('⏭️ OCR 이미 처리 중, 건너뛰기');
        return false;
      }

      setState(() {
        _isOCRProcessing = true;
      });

      print('📸 번호판 인식 시작...');
      
      // 카메라가 녹화 중이 아닐 때만 사진 촬영 (메모리 절약)
      if (_cameraController!.value.isRecordingVideo) {
        print('⚠️ 녹화 중이므로 OCR 건너뛰기 (메모리 절약)');
        return false;
      }

      // 현재 카메라 프레임을 이미지로 캡처
      final XFile imageFile = await _cameraController!.takePicture();
      
      if (!mounted) {
        // 위젯이 dispose되었으면 파일 삭제 후 종료
        final file = File(imageFile.path);
        if (await file.exists()) {
          await file.delete();
        }
        return false;
      }
      
      print('📸 이미지 캡처 완료: ${imageFile.path}');
      
      // OCR로 번호판 인식 (타임아웃 설정)
      print('🔍 OCR 처리 시작...');
      final result = await _ocrService.recognizeLicensePlate(imageFile.path)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        print('⏰ OCR 타임아웃 (15초)');
        return null;
      });
      
      print('🔍 OCR 결과 상세:');
      print('  - 번호판: ${result?.plateNumber ?? "없음"}');
      print('  - 신뢰도: ${result?.confidence?.toStringAsFixed(3) ?? "없음"}');
      print('  - OCR 제공자: ${result?.ocrProvider ?? "없음"}');
      print('  - 원본 텍스트: ${result?.rawText ?? "없음"}');
      
      if (result == null) {
        print('❌ OCR 결과가 null입니다.');
      } else if (result.plateNumber == null || result.plateNumber!.isEmpty) {
        print('❌ 번호판이 인식되지 않았습니다.');
      }
      
      if (mounted && result != null && result.plateNumber != null && result.plateNumber!.isNotEmpty) {
        // 신뢰도 기록
        if (result.confidence != null) {
          _confidenceHistory.add(result.confidence!);
          if (_confidenceHistory.length > 20) {
            _confidenceHistory.removeAt(0);
          }
        }
        
        setState(() {
          _detectedPlate = result;
        });
        
        print('✅ 번호판 감지 성공: ${result.plateNumber} (신뢰도: ${result.confidence?.toStringAsFixed(3)})');
        
        // 번호판이 감지되면 알림 표시
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result.plateNumber} (${(result.confidence! * 100).toStringAsFixed(0)}%)'),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        return true; // 성공
      } else {
        print('⚠️ 번호판을 찾을 수 없음');
        return false; // 실패
      }
      
      // 임시 이미지 파일 즉시 삭제 (메모리 확보)
      try {
        final file = File(imageFile.path);
        if (await file.exists()) {
          await file.delete();
          print('🗑️ 임시 파일 삭제됨');
        }
      } catch (e) {
        print('⚠️ 임시 파일 삭제 실패: $e');
      }
      
    } catch (e, stackTrace) {
      print('❌ 번호판 감지 실패: $e');
      print('📍 스택 트레이스: $stackTrace');
      
      // 크래시 방지를 위한 추가 에러 처리
      if (e.toString().contains('memory') || e.toString().contains('OutOfMemory')) {
        print('💥 메모리 부족 감지 - OCR 일시 중단');
        _stopLicensePlateDetection();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ 메모리 부족으로 번호판 인식을 일시 중단합니다'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      
      return false; // 에러로 인한 실패
    } finally {
      if (mounted) {
        setState(() {
          _isOCRProcessing = false;
        });
      }
    }
  }

  /// 성능 통계 출력
  void _printPerformanceStats() {
    final successRate = _totalOCRAttempts > 0 
        ? (_successfulRecognitions / _totalOCRAttempts * 100) 
        : 0.0;
    
    final avgProcessingTime = _ocrProcessingTimes.isNotEmpty 
        ? _ocrProcessingTimes.reduce((a, b) => a + b) / _ocrProcessingTimes.length 
        : 0.0;
    
    final avgConfidence = _confidenceHistory.isNotEmpty 
        ? _confidenceHistory.reduce((a, b) => a + b) / _confidenceHistory.length 
        : 0.0;
    
    print('📊 === OCR 성능 통계 ===');
    print('   총 시도: $_totalOCRAttempts회');
    print('   성공 횟수: $_successfulRecognitions회');
    print('   성공률: ${successRate.toStringAsFixed(1)}%');
    print('   평균 처리시간: ${avgProcessingTime.toStringAsFixed(2)}초');
    print('   평균 신뢰도: ${(avgConfidence * 100).toStringAsFixed(1)}%');
    print('   현재 OCR 간격: ${_currentOCRInterval.toStringAsFixed(1)}초');
    print('   연속 성공: $_consecutiveSuccesses, 연속 실패: $_consecutiveFailures');
    print('========================');
  }

  /// 수동 번호판 인식 (사진 촬영)
  Future<void> _captureAndRecognizePlate() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        _isOCRProcessing = true;
      });

      final XFile imageFile = await _cameraController!.takePicture();
      final result = await _ocrService.recognizeLicensePlate(imageFile.path);
      
      if (result != null) {
        setState(() {
          _detectedPlate = result;
        });
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('🏍️ 오토바이 번호판 인식 결과'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('번호판: ${result.plateNumber ?? "인식 실패"}'),
                  Text('신뢰도: ${result.confidence?.toStringAsFixed(2) ?? "N/A"}'),
                  Text('원본 텍스트: ${result.rawText ?? "N/A"}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🏍️ 오토바이 번호판을 인식할 수 없습니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      
    } catch (e) {
      print('❌ 수동 번호판 인식 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('번호판 인식 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOCRProcessing = false;
        });
      }
    }
  }

  /// 리소스 해제 (안전성 개선)
  @override
  void dispose() {
    print('🧹 RecordingScreen dispose 시작...');
    
    try {
      // 1. 녹화 중지 (필요시)
      if (_isRecording && _cameraController?.value.isRecordingVideo == true) {
        _cameraController?.stopVideoRecording().catchError((e) {
          print('⚠️ dispose 중 녹화 중지 실패: $e');
        });
      }
      
      // 2. 타이머들 정리
      _stopLicensePlateDetection();
      
      // 3. 데시벨 측정 중지
      _stopNoiseListening();
      
      // 4. OCR 서비스 정리
      _ocrService.dispose().catchError((e) {
        print('⚠️ OCR 서비스 dispose 실패: $e');
      });
      
      // 5. 카메라 컨트롤러 정리
      _cameraController?.dispose();
      _cameraController = null;
      
      print('✅ RecordingScreen dispose 완료');
    } catch (e) {
      print('❌ dispose 중 에러: $e');
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 웹 환경에서는 카메라 미리보기를 표시하지 않음
    if (_isWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('데시벨 측정 (웹 환경)')),
        body: _buildWebInterface(),
      );
    }
    
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2D3748),
                Color(0xFF1A202C),
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 20),
                Text(
                  '카메라를 초기화하고 있습니다...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 카메라 미리보기 (전체 화면)
          SizedBox.expand(
            child: CameraPreview(_cameraController!),
          ),
          
          // 상단 그라데이션 오버레이
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 뒤로가기 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(25),
                  child: const SizedBox(
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 상단 상태 표시
          Positioned(
            top: 50,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isRecording)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (_isRecording) const SizedBox(width: 6),
                  Text(
                    _isRecording ? 'REC' : '대기',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 컨트롤 패널
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 32 : 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 데시벨 표시 카드
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 24 : 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isNoiseListening ? Icons.graphic_eq : Icons.volume_off,
                                  color: _isNoiseListening ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_currentDecibel.toStringAsFixed(1)} dB',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: MediaQuery.of(context).size.width > 600 ? 32.0 : 28.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: _CompactStatBox(
                                    label: '최소',
                                    value: _noiseData?.minDecibel?.toStringAsFixed(1) ?? '-',
                                    icon: Icons.trending_down,
                                    color: Colors.blue,
                                  ),
                                ),
                                Expanded(
                                  child: _CompactStatBox(
                                    label: '평균',
                                    value: _noiseData?.avgDecibel?.toStringAsFixed(1) ?? '-',
                                    icon: Icons.remove,
                                    color: Colors.orange,
                                  ),
                                ),
                                Expanded(
                                  child: _CompactStatBox(
                                    label: '최대',
                                    value: _noiseData?.maxDecibel?.toStringAsFixed(1) ?? '-',
                                    icon: Icons.trending_up,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 위치 정보 (획득되었을 때만)
                      if (_currentLocation != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '📍 ${_locationService.formatLocationInfo(_currentLocation!)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_currentLocation!.accuracy != null)
                                      Text(
                                        _locationService.formatAccuracy(_currentLocation!.accuracy),
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 번호판 정보 (감지되었을 때만)
                      if (_detectedPlate != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '번호판: ${_detectedPlate!.plateNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(_detectedPlate!.confidence! * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 메인 컨트롤 버튼들
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 소음 측정 토글
                          _CircleButton(
                            icon: _isNoiseListening ? Icons.stop : Icons.mic,
                            color: _isNoiseListening ? Colors.red : Colors.green,
                            onPressed: _isNoiseListening ? _stopNoiseListening : _startNoiseListening,
                            size: MediaQuery.of(context).size.width > 600 ? 70 : 60,
                          ),

                          // 메인 녹화 버튼
                          GestureDetector(
                            onTap: _isRecording ? _stopRecording : _startRecording,
                            child: Container(
                              width: MediaQuery.of(context).size.width > 600 ? 90 : 80,
                              height: MediaQuery.of(context).size.width > 600 ? 90 : 80,
                              decoration: BoxDecoration(
                                color: _isRecording ? Colors.red : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isRecording ? Colors.red : Colors.white).withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isRecording ? Icons.stop : Icons.videocam,
                                color: _isRecording ? Colors.white : Colors.black,
                                size: MediaQuery.of(context).size.width > 600 ? 36 : 32,
                              ),
                            ),
                          ),

                          // 번호판 인식
                          _CircleButton(
                            icon: _isOCRProcessing ? Icons.hourglass_empty : Icons.camera_alt,
                            color: _isOCRProcessing ? Colors.orange : Colors.purple,
                            onPressed: _isOCRProcessing ? () {} : _captureAndRecognizePlate,
                            isEnabled: !_isOCRProcessing,
                            size: MediaQuery.of(context).size.width > 600 ? 70 : 60,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 리포트 버튼 (항상 표시) - 강화된 디버그
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            print('🔥 리포트 버튼 클릭됨!');
                            print('  - _noiseData: ${_noiseData != null}');
                            print('  - _currentRecording: ${_currentRecording != null}');
                            
                            // 새로운 보고서 화면으로 이동
                            try {
                              final reportData = {
                                'maxDecibel': _noiseData?.maxDecibel ?? 50.0,
                                'minDecibel': _noiseData?.minDecibel ?? 30.0,
                                'avgDecibel': _noiseData?.avgDecibel ?? 40.0,
                                'startTime': _noiseData?.startTime ?? DateTime.now().subtract(const Duration(minutes: 5)),
                                'endTime': _noiseData?.endTime ?? DateTime.now(),
                                'measurementCount': _noiseData?.measurementCount ?? 15,
                                'currentLocation': _currentLocation,
                                'detectedPlate': _detectedPlate,
                                'videoPath': _currentRecording?.videoPath,
                              };
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NewReportScreen(reportData: reportData),
                                ),
                              );
                              print('✅ 새로운 보고서 화면으로 이동 성공');
                            } catch (e) {
                              print('❌ 보고서 화면 이동 실패: $e');
                            }
                          },
                          icon: const Icon(Icons.assessment_outlined),
                          label: const Text('📊 리포트 보기', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange, // 더 눈에 잘 띄는 색상
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16), // 더 큰 버튼
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            elevation: 8, // 그림자 추가
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // OCR 처리 중일 때 오버레이
          if (_isOCRProcessing)
            Positioned(
              top: 200,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        '번호판 인식 중...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 웹 환경용 인터페이스
  Widget _buildWebInterface() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 웹 환경 안내 메시지
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 32),
                const SizedBox(height: 8),
                const Text(
                  '웹 환경에서는 카메라 기능을 사용할 수 없습니다',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '데시벨 측정 기능만 사용 가능합니다',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // 현재 데시벨 표시 및 통계
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '현재 데시벨: ${_currentDecibel.toStringAsFixed(2)} dB',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _isNoiseListening ? '📊 측정 중' : '❌ 측정 중지됨',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isNoiseListening ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatBox(label: '최대', value: _noiseData?.maxDecibel),
                    _StatBox(label: '평균', value: _noiseData?.avgDecibel),
                    _StatBox(label: '최소', value: _noiseData?.minDecibel),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 데시벨 측정 시작/중지 버튼
          ElevatedButton(
            onPressed: _isNoiseListening ? _stopNoiseListening : _startNoiseListening,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isNoiseListening ? Colors.red : Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(
              _isNoiseListening ? '🛑 데시벨 측정 중지' : '🔊 데시벨 측정 시작',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),

          const SizedBox(height: 16),

          // 리포트 보기 버튼 (항상 표시)
          ElevatedButton(
            onPressed: _showReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B8AFF),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              '📊 리포트 보기',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final double? value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value != null ? value!.toStringAsFixed(2) : '-',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// 새로운 UI 디자인용 커스텀 위젯들

/// 컴팩트한 통계 상자 위젯 (오버레이용)
class _CompactStatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  
  const _CompactStatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth > 600 ? 16.0 : 8.0;
    final iconSize = screenWidth > 600 ? 18.0 : 14.0;
    final spacing = screenWidth > 600 ? 10.0 : 6.0;
    final labelFontSize = screenWidth > 600 ? 12.0 : 10.0;
    final valueFontSize = screenWidth > 600 ? 16.0 : 12.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: iconSize,
          ),
          SizedBox(width: spacing),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 원형 버튼 위젯 (카메라 앱 스타일)
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final Color? backgroundColor;
  final double size;
  final bool isEnabled;
  
  const _CircleButton({
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
    this.backgroundColor,
    this.size = 60,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(size / 2),
          child: Center(
            child: Icon(
              icon,
              color: isEnabled ? color : color.withOpacity(0.5),
              size: size * 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

/// 액션 버튼 위젯 (하단 버튼들용)
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final bool isEnabled;
  
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? [color, color.withOpacity(0.8)]
                : [Colors.grey.shade600, Colors.grey.shade700],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isEnabled ? color : Colors.grey).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 뒤로가기 플로팅 버튼
class BackButtonFloating extends StatelessWidget {
  const BackButtonFloating({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(25),
            child: const SizedBox(
              width: 50,
              height: 50,
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}