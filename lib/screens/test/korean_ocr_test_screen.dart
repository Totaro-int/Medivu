import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/korean_ocr_tester.dart';
import '../../services/license_plate_ocr_service.dart';
import '../../utils/ocr_performance_analyzer.dart';

/// 한글 OCR 성능 테스트 화면
class KoreanOCRTestScreen extends StatefulWidget {
  const KoreanOCRTestScreen({Key? key}) : super(key: key);

  @override
  State<KoreanOCRTestScreen> createState() => _KoreanOCRTestScreenState();
}

class _KoreanOCRTestScreenState extends State<KoreanOCRTestScreen> {
  final _imagePickerController = ImagePicker();
  final _expectedPlateController = TextEditingController();

  String? _selectedImagePath;
  bool _isTestRunning = false;
  Map<String, dynamic>? _testResult;
  List<String> _testLogs = [];
  OCRPerformanceReport? _performanceReport;

  @override
  void dispose() {
    _expectedPlateController.dispose();
    super.dispose();
  }

  /// 이미지 선택
  Future<void> _selectImage() async {
    try {
      final pickedFile = await _imagePickerController.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
          _testResult = null;
        });
      }
    } catch (e) {
      _showErrorSnackBar('이미지 선택 실패: $e');
    }
  }

  /// 카메라로 촬영
  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _imagePickerController.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
          _testResult = null;
        });
      }
    } catch (e) {
      _showErrorSnackBar('카메라 촬영 실패: $e');
    }
  }

  /// 단일 이미지 테스트
  Future<void> _runSingleTest() async {
    if (_selectedImagePath == null) {
      _showErrorSnackBar('테스트할 이미지를 선택해주세요.');
      return;
    }

    final expectedPlate = _expectedPlateController.text.trim();
    if (expectedPlate.isEmpty) {
      _showErrorSnackBar('예상 번호판을 입력해주세요.');
      return;
    }

    setState(() {
      _isTestRunning = true;
      _testResult = null;
      _testLogs.clear();
    });

    try {
      _addLog('🚀 한글 OCR 테스트 시작...');
      _addLog('📁 이미지: ${_selectedImagePath!.split('/').last}');
      _addLog('🎯 예상 번호판: $expectedPlate');

      final result = await KoreanOCRTester.testWithRealImage(
        _selectedImagePath!,
        expectedPlate,
      );

      setState(() {
        _testResult = result;
      });

      _addLog('✅ 테스트 완료!');

    } catch (e) {
      _addLog('❌ 테스트 실패: $e');
    } finally {
      setState(() {
        _isTestRunning = false;
      });
    }
  }

  /// 성능 벤치마크 테스트
  Future<void> _runBenchmarkTest() async {
    setState(() {
      _isTestRunning = true;
      _testResult = null;
      _testLogs.clear();
    });

    try {
      _addLog('🏁 벤치마크 테스트 시작...');
      _addLog('📊 다양한 번호판 패턴 테스트 중...');

      await KoreanOCRTester.performanceTest();

      _addLog('✅ 벤치마크 테스트 완료!');
      _addLog('📝 자세한 결과는 콘솔을 확인하세요.');

    } catch (e) {
      _addLog('❌ 벤치마크 테스트 실패: $e');
    } finally {
      setState(() {
        _isTestRunning = false;
      });
    }
  }

  /// 실시간 성능 리포트 생성
  Future<void> _generatePerformanceReport() async {
    setState(() {
      _isTestRunning = true;
    });

    try {
      _addLog('📊 실시간 성능 분석 시작...');

      final ocrService = LicensePlateOCRService.instance;
      final report = ocrService.generatePerformanceReport();

      setState(() {
        _performanceReport = report;
      });

      _addLog('✅ 성능 리포트 생성 완료!');
      _addLog('📈 총 테스트: ${report.totalTests}개');
      _addLog('🎯 ML Kit 성공률: ${(report.mlkitStats.successRate * 100).toStringAsFixed(1)}%');
      _addLog('🔧 Tesseract 성공률: ${(report.tesseractStats.successRate * 100).toStringAsFixed(1)}%');
      _addLog('💡 권장사항: ${report.recommendation}');

    } catch (e) {
      _addLog('❌ 성능 리포트 생성 실패: $e');
    } finally {
      setState(() {
        _isTestRunning = false;
      });
    }
  }

  /// 하이브리드 전략 시연
  Future<void> _demonstrateHybridStrategy() async {
    setState(() {
      _isTestRunning = true;
      _testLogs.clear();
    });

    try {
      _addLog('🎯 하이브리드 OCR 전략 시연 시작...');

      final hybridStrategy = OCRPerformanceAnalyzer.proposeHybridStrategy();

      _addLog('🔧 하이브리드 전략 세부사항:');
      _addLog('');
      _addLog('📋 Google ML Kit 최적 조건:');
      for (final condition in hybridStrategy.primaryConditions['google_mlkit'] ?? []) {
        _addLog('  • $condition');
      }

      _addLog('');
      _addLog('📋 Tesseract 최적 조건:');
      for (final condition in hybridStrategy.primaryConditions['tesseract'] ?? []) {
        _addLog('  • $condition');
      }

      _addLog('');
      _addLog('🔄 대체 규칙:');
      for (final rule in hybridStrategy.fallbackRules) {
        _addLog('  • $rule');
      }

      _addLog('');
      _addLog('🎯 성능 목표:');
      _addLog('  • 정확도: ${(hybridStrategy.performanceTarget.accuracy * 100).toStringAsFixed(1)}%');
      _addLog('  • 최대 처리시간: ${hybridStrategy.performanceTarget.maxProcessingTime}ms');
      _addLog('  • 배터리 효율성: ${hybridStrategy.performanceTarget.batteryEfficient ? "우선" : "일반"}');

      _addLog('✅ 하이브리드 전략 시연 완료!');

    } catch (e) {
      _addLog('❌ 하이브리드 전략 시연 실패: $e');
    } finally {
      setState(() {
        _isTestRunning = false;
      });
    }
  }

  /// 로그 추가
  void _addLog(String message) {
    setState(() {
      _testLogs.add('[${DateTime.now().toLocal().toString().substring(11, 19)}] $message');
    });
    print(message);
  }

  /// 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('한글 OCR 성능 테스트'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이미지 선택 섹션
            _buildImageSelectionSection(),
            const SizedBox(height: 20),

            // 예상 번호판 입력
            _buildExpectedPlateSection(),
            const SizedBox(height: 20),

            // 테스트 버튼들
            _buildTestButtonsSection(),
            const SizedBox(height: 20),

            // 테스트 결과
            if (_testResult != null) _buildTestResultSection(),
            const SizedBox(height: 20),

            // 성능 리포트
            if (_performanceReport != null) _buildPerformanceReportSection(),
            const SizedBox(height: 20),

            // 테스트 로그
            _buildTestLogsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📷 테스트 이미지',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (_selectedImagePath != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_selectedImagePath!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '이미지가 선택되지 않았습니다',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('갤러리'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('카메라'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpectedPlateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 예상 번호판',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _expectedPlateController,
              decoration: const InputDecoration(
                hintText: '예: 12가3456',
                border: OutlineInputBorder(),
                helperText: '이미지에서 인식되어야 할 번호판을 입력하세요',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtonsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧪 테스트 실행',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isTestRunning ? null : _runSingleTest,
                icon: _isTestRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
                label: Text(_isTestRunning ? '테스트 중...' : '단일 이미지 테스트'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isTestRunning ? null : _runBenchmarkTest,
                icon: _isTestRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.speed),
                label: Text(_isTestRunning ? '벤치마크 중...' : '성능 벤치마크 테스트'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isTestRunning ? null : _generatePerformanceReport,
                icon: _isTestRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.analytics),
                label: Text(_isTestRunning ? '분석 중...' : '실시간 성능 리포트'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isTestRunning ? null : _demonstrateHybridStrategy,
                icon: _isTestRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
                label: Text(_isTestRunning ? '시연 중...' : '하이브리드 전략 시연'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultSection() {
    final result = _testResult!;
    final success = result['success'] as bool;
    final confidence = result['confidence'] as double;
    final processingTime = result['processing_time'] as int;
    final accuracy = result['accuracy'] as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  success ? '✅ 테스트 결과' : '❌ 테스트 결과',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _buildResultRow('예상 번호판', result['expected']),
            _buildResultRow('인식 결과', result['recognized']),
            _buildResultRow('정확도', '${(accuracy * 100).toStringAsFixed(1)}%'),
            _buildResultRow('신뢰도', '${(confidence * 100).toStringAsFixed(1)}%'),
            _buildResultRow('처리시간', '${processingTime}ms'),
            _buildResultRow('OCR 엔진', result['ocr_provider']),
            if (result['raw_text'] != null)
              _buildResultRow('원본 텍스트', result['raw_text']),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildTestLogsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📝 테스트 로그',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _testLogs.isEmpty
                ? const Center(
                    child: Text(
                      '테스트 로그가 여기에 표시됩니다',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _testLogs.length,
                    itemBuilder: (context, index) {
                      return Text(
                        _testLogs[index],
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceReportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 실시간 성능 리포트',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 전체 통계
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📈 전체 통계',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('총 테스트: ${_performanceReport!.totalTests}회'),
                      Text('분석일: ${_performanceReport!.analysisDate.toString().substring(0, 16)}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ML Kit 성능
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.android, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Google ML Kit 성능',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('성공률: ${(_performanceReport!.mlkitStats.successRate * 100).toStringAsFixed(1)}%'),
                      Text('평균 시간: ${_performanceReport!.mlkitStats.avgProcessingTime}ms'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('평균 신뢰도: ${(_performanceReport!.mlkitStats.avgConfidence * 100).toStringAsFixed(1)}%'),
                      Text('테스트 수: ${_performanceReport!.mlkitStats.totalTests}회'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Tesseract 성능
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.memory, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tesseract OCR 성능',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('성공률: ${(_performanceReport!.tesseractStats.successRate * 100).toStringAsFixed(1)}%'),
                      Text('평균 시간: ${_performanceReport!.tesseractStats.avgProcessingTime}ms'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('평균 신뢰도: ${(_performanceReport!.tesseractStats.avgConfidence * 100).toStringAsFixed(1)}%'),
                      Text('테스트 수: ${_performanceReport!.tesseractStats.totalTests}회'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 권장사항
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.purple.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '💡 AI 권장사항',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _performanceReport!.recommendation,
                    style: TextStyle(color: Colors.purple.shade800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}