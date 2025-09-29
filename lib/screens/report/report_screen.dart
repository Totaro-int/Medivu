import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../services/pdf_service.dart';
import '../../services/enhanced_database_helper.dart';
import '../../widgets/share_dialog.dart';
import '../../models/report_model.dart';
import '../../models/recording_model.dart';
import '../../models/noise_data_model.dart';
import 'package:open_file/open_file.dart';
import 'package:uuid/uuid.dart';
import '../../services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportScreen extends StatefulWidget {
  final String? videoPath;
  final double? maxDecibel;
  final double? minDecibel;
  final double? avgDecibel;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? measurementCount;
  final String? reportId;

  const ReportScreen({
    super.key,
    this.videoPath,
    this.maxDecibel,
    this.minDecibel,
    this.avgDecibel,
    this.startTime,
    this.endTime,
    this.measurementCount,
    this.reportId,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportModel? _report;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic>? args = 
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      print('🔍 리포트 로드 시작');
      print('  - args: $args');
      
      if (args != null && args['reportId'] != null) {
        // 기존 리포트 로드
        print('  - 기존 리포트 ID로 로드: ${args['reportId']}');
        final reportId = int.tryParse(args['reportId'].toString()) ?? 0;
        final report = await EnhancedDatabaseHelper.instance.getReport(reportId);
        if (report != null) {
          print('✅ 기존 리포트 로드 성공');
          setState(() {
            _report = report;
          });
        } else {
          print('❌ 기존 리포트를 찾을 수 없음 - 새 리포트 생성으로 대체');
          _report = _createReportFromArguments(args);
        }
      } else {
        // 새 리포트 생성 (recording_screen에서 넘어온 데이터 사용)
        print('  - 새 리포트 생성');
        _report = _createReportFromArguments(args);
        if (_report != null) {
          print('✅ 새 리포트 생성 성공');
        } else {
          print('❌ 새 리포트 생성 실패');
        }
      }
      
      print('  - 최종 리포트 상태: ${_report != null ? '성공' : '실패'}');
    } catch (e) {
      print('❌ 리포트 데이터 로드 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('리포트 로드 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  ReportModel? _createReportFromArguments(Map<String, dynamic>? args) {
    print('📝 리포트 생성 시작');
    print('  - args: $args');
    
    // args가 null이어도 기본 리포트 생성

    try {
      final now = DateTime.now();
      final startTime = args?['startTime'] ?? now.subtract(const Duration(minutes: 1));
      final endTime = args?['endTime'] ?? now;
      
      final noiseData = NoiseDataModel(
        currentDecibel: args?['avgDecibel'] ?? 45.0,
        maxDecibel: args?['maxDecibel'] ?? 50.0,
        minDecibel: args?['minDecibel'] ?? 30.0,
        avgDecibel: args?['avgDecibel'] ?? 40.0,
        measurementCount: args?['measurementCount'] ?? 15, // 기본값 제공
        readings: [],
        startTime: startTime,
        endTime: endTime,
      );
      
      print('  - 노이즈 데이터 생성 완료: max=${noiseData.maxDecibel}, count=${noiseData.measurementCount}');

      final recording = RecordingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: startTime,
        endTime: endTime,
        noiseData: noiseData,
        userId: '1', // 기본 사용자 ID
        status: RecordingStatus.completed,
        videoPath: args?['videoPath'],
        location: args?['currentLocation'],
        licensePlate: args?['detectedPlate'],
      );
      
      print('  - 녹화 모델 생성 완료');

      final report = ReportModel(
        id: const Uuid().v4(),
        title: '소음 측정 리포트',
        description: '${DateFormat('yyyy.MM.dd HH:mm').format(recording.startTime)} 측정',
        recording: recording,
        status: ReportStatus.ready,
        createdAt: DateTime.now(),
        userId: recording.userId,
      );
      
      print('✅ 리포트 생성 완료: ${report.title}');
      return report;
    } catch (e) {
      print('리포트 생성 실패: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('리포트'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 빈 상태 처리 - 리포트가 완전히 없을 때만 (더 상세한 디버그)
    if (_report == null) {
      print('❌ 리포트가 null입니다 - 빈 상태 화면 표시');
      return Scaffold(
        appBar: AppBar(
          title: const Text('측정 리포트'),
          backgroundColor: const Color(0xFF7B8AFF),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  '리포트 데이터 로드 실패',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '리포트 생성에 문제가 있었습니다. 다시 시도해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('측정 화면으로 돌아가기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B8AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    print('✅ 리포트 데이터 존재 - 리포트 화면 표시');
    print('  - measurementCount: ${_report!.recording.noiseData.measurementCount}');
    print('  - maxDecibel: ${_report!.recording.noiseData.maxDecibel}');

    final recording = _report!.recording;
    final noiseData = recording.noiseData;
    final duration = recording.duration;

    return Scaffold(
      appBar: AppBar(
        title: const Text('측정 리포트'),
        backgroundColor: const Color(0xFF7B8AFF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReport(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 리포트 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7B8AFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.assessment,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '데시벨 측정 리포트',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('yyyy년 MM월 dd일 HH:mm').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 측정 정보
            _buildSection(
              title: '측정 정보',
              icon: Icons.info,
              children: [
                _buildInfoRow('측정 시작', 
                    DateFormat('HH:mm:ss').format(noiseData.startTime)),
                _buildInfoRow('측정 종료', noiseData.endTime != null 
                    ? DateFormat('HH:mm:ss').format(noiseData.endTime!)
                    : '정보 없음'),
                _buildInfoRow('측정 시간', duration != null 
                    ? '${duration.inMinutes}분 ${duration.inSeconds % 60}초'
                    : '정보 없음'),
                _buildInfoRow('측정 횟수', '${noiseData.measurementCount}회'),
              ],
            ),
            const SizedBox(height: 20),

            // 데시벨 통계
            _buildSection(
              title: '데시벨 통계',
              icon: Icons.volume_up,
              children: [
                _buildDecibelRow('최대 데시벨', noiseData.maxDecibel, Colors.red),
                _buildDecibelRow('평균 데시벨', noiseData.avgDecibel, Colors.orange),
                _buildDecibelRow('최소 데시벨', noiseData.minDecibel, Colors.green),
              ],
            ),
            const SizedBox(height: 20),

            // 위치 정보
            if (recording.location != null) ...[
              _buildSection(
                title: '측정 위치',
                icon: Icons.location_on,
                children: [
                  _buildLocationInfo(recording.location!),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // 번호판 정보
            if (recording.licensePlate != null) ...[
              _buildSection(
                title: '감지된 번호판',
                icon: Icons.directions_car,
                children: [
                  _buildLicensePlateInfo(recording.licensePlate!),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // 녹화 정보
            if (recording.videoPath != null) ...[
              _buildSection(
                title: '녹화 정보',
                icon: Icons.videocam,
                children: [
                  _buildInfoRow('파일 경로', recording.videoPath!),
                  _buildInfoRow('파일 크기', _getFileSize(recording.videoPath!)),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // 데시벨 수준 평가
            _buildSection(
              title: '데시벨 수준 평가',
              icon: Icons.assessment,
              children: [
                _buildDecibelLevelCard(noiseData),
              ],
            ),
            const SizedBox(height: 20),

            // PDF 다운로드 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // PDF 생성 및 저장
                  final pdfPath = await PdfService().generateDecibelReport(
                    maxDecibel: noiseData.maxDecibel,
                    minDecibel: noiseData.minDecibel,
                    avgDecibel: noiseData.avgDecibel,
                    startTime: noiseData.startTime,
                    endTime: noiseData.endTime,
                    measurementCount: noiseData.measurementCount,
                    videoPath: recording.videoPath,
                    location: recording.location,
                    licensePlateNumber: recording.licensePlate?.plateNumber,
                    licensePlateConfidence: recording.licensePlate?.confidence,
                    licensePlateRawText: recording.licensePlate?.rawText,
                  );
                  
                  if (pdfPath != null) {
                    // PDF 파일 열기
                    final result = await OpenFile.open(pdfPath);
                    if (result.type != ResultType.done) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('PDF 저장 완료: $pdfPath')),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PDF가 생성되고 열렸습니다')),
                        );
                      }
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PDF 생성에 실패했습니다.')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.file_download),
                label: const Text('PDF 다운로드'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF48BB78),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // PDF 직접 수정 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // 리포트를 편집 모드로 다시 로드
                  if (_report != null) {
                    Navigator.pushReplacementNamed(
                      context,
                      '/report',
                      arguments: {
                        'reportId': _report!.id,
                        'editMode': true,
                      },
                    );
                  }
                },
                icon: const Icon(Icons.edit_document),
                label: const Text('PDF 내용 직접 수정'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4299E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF7B8AFF)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecibelRow(String label, double? value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value != null ? '${value.toStringAsFixed(2)} dB' : '정보 없음',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecibelLevelCard(NoiseDataModel noiseData) {
    final maxDb = noiseData.maxDecibel ?? 0;
    String level;
    String description;
    Color color;

    if (maxDb < 50) {
      level = '매우 조용함';
      description = '도서관 수준의 조용한 환경';
      color = Colors.green;
    } else if (maxDb < 60) {
      level = '조용함';
      description = '일반적인 사무실 환경';
      color = Colors.lightGreen;
    } else if (maxDb < 70) {
      level = '보통';
      description = '일반적인 대화 수준';
      color = Colors.orange;
    } else if (maxDb < 80) {
      level = '시끄러움';
      description = '도로교통 소음 수준';
      color = Colors.deepOrange;
    } else {
      level = '매우 시끄러움';
      description = '건설장비 수준의 소음';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volume_up, color: color),
              const SizedBox(width: 8),
              Text(
                level,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _getFileSize(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final size = file.lengthSync();
        if (size < 1024) {
          return '$size B';
        } else if (size < 1024 * 1024) {
          return '${(size / 1024).toStringAsFixed(1)} KB';
        } else {
          return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
      }
    } catch (e) {
      // 파일 접근 오류 무시
    }
    return '정보 없음';
  }

  Widget _buildLocationInfo(dynamic location) {
    final locationService = LocationService.instance;
    final locationString = locationService.formatLocationInfo(location);
    final accuracyString = locationService.formatAccuracy(location.accuracy);
    final mapsUrl = locationService.getGoogleMapsUrl(location);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('주소', locationString),
        _buildInfoRow('위도', location.latitude.toStringAsFixed(6)),
        _buildInfoRow('경도', location.longitude.toStringAsFixed(6)),
        _buildInfoRow('정확도', accuracyString),
        if (location.timestamp != null)
          _buildInfoRow('측정 시간', DateFormat('HH:mm:ss').format(location.timestamp)),
        const SizedBox(height: 12),
        // Google Maps로 위치 보기 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                final uri = Uri.parse(mapsUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Google Maps를 열 수 없습니다')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('링크 열기 실패: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.map, size: 20),
            label: const Text('Google Maps에서 보기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLicensePlateInfo(dynamic licensePlate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('번호판', licensePlate.plateNumber ?? '인식 실패'),
        if (licensePlate.confidence != null)
          _buildInfoRow('신뢰도', '${(licensePlate.confidence! * 100).toStringAsFixed(1)}%'),
        if (licensePlate.detectedAt != null)
          _buildInfoRow('감지 시간', DateFormat('HH:mm:ss').format(licensePlate.detectedAt!)),
        _buildInfoRow('유효성', licensePlate.isValidFormat == true ? '✓ 유효한 형식' : '⚠ 확인 필요'),
      ],
    );
  }

  void _shareReport(BuildContext context) {
    // 현재 데이터로 임시 ReportModel 생성
    final mockReport = _report!;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShareDialog(report: mockReport);
      },
    );
  }

} 