import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/location_model.dart';
import 'location_service.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  // 한글 폰트 캐시
  pw.Font? _koreanFont;

  /// PDF용 안전한 폰트 로드 (영어 텍스트 사용)
  Future<pw.Font> _getKoreanFont() async {
    if (_koreanFont != null) return _koreanFont!;
    
    try {
      // 안정적인 기본 폰트 사용
      _koreanFont = pw.Font.helvetica();
      return _koreanFont!;
    } catch (e) {
      print('폰트 로드 실패: $e');
      return pw.Font.courier();
    }
  }

  /// 데시벨 측정 리포트 PDF 생성
  Future<String?> generateDecibelReport({
    required double? maxDecibel,
    required double? minDecibel,
    required double? avgDecibel,
    required DateTime? startTime,
    required DateTime? endTime,
    required int? measurementCount,
    String? videoPath,
    String? licensePlateNumber,
    double? licensePlateConfidence,
    String? licensePlateRawText,
    // 위치 정보
    LocationModel? location,
    // 웨어러블 기기 건강상태 데이터 (향후 추가용)
    int? heartRate,
    double? stressLevel,
    int? stepCount,
    double? sleepQuality,
  }) async {
    try {
      print('PDF 생성 시작...');
      
      // 입력 데이터 검증
      if (maxDecibel == null && minDecibel == null && avgDecibel == null) {
        print('❌ 데시벨 데이터가 없어 PDF 생성을 중단합니다.');
        return null;
      }
      
      final pdf = pw.Document();
      final font = await _getKoreanFont();

      // PDF 페이지 생성
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            _buildHeader(font),
            pw.SizedBox(height: 20),
            _buildMeasurementInfo(font, startTime, endTime, measurementCount),
            pw.SizedBox(height: 20),
            _buildDecibelStatistics(font, maxDecibel, minDecibel, avgDecibel),
            pw.SizedBox(height: 20),
            // 위치 정보 섹션
            _buildLocationInfo(font, location),
            pw.SizedBox(height: 20),
            if (videoPath != null) ...[
              _buildVideoInfo(font, videoPath),
              pw.SizedBox(height: 20),
            ],
            // OCR 번호판 정보 섹션 (항상 표시)
            _buildLicensePlateInfo(font, licensePlateNumber, licensePlateConfidence, licensePlateRawText),
            pw.SizedBox(height: 20),
            _buildDecibelLevelAssessment(font, maxDecibel),
            pw.SizedBox(height: 20),
            // 웨어러블 기기 건강상태 섹션
            _buildHealthStatusSection(font, heartRate, stressLevel, stepCount, sleepQuality),
            pw.SizedBox(height: 20),
            _buildFooter(font),
          ],
        ),
      );

      print('PDF 문서 생성 완료, 파일 저장 중...');

      // PDF 파일 저장 - 문서 디렉토리 사용
      final output = await getApplicationDocumentsDirectory();
      final fileName = 'decibel_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${output.path}/$fileName');
      
      print('저장 경로: ${file.path}');
      
      final pdfBytes = await pdf.save();
      print('PDF 바이트 생성 완료: ${pdfBytes.length} bytes');
      
      await file.writeAsBytes(pdfBytes);
      print('PDF 파일 저장 완료: ${file.path}');

      return file.path;
    } catch (e, stackTrace) {
      print('PDF 생성 오류: $e');
      print('스택 트레이스: $stackTrace');
      
      // 오류 로그 개선
      print('디버그 정보:');
      print('  - maxDecibel: $maxDecibel');
      print('  - startTime: $startTime');
      print('  - measurementCount: $measurementCount');
      print('  - location: ${location?.toString()}');
      
      return null;
    }
  }

  /// 헤더 섹션
  pw.Widget _buildHeader(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Decibel Measurement Report',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              font: font,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
            style: pw.TextStyle(
              fontSize: 16,
              color: PdfColors.white,
              font: font,
            ),
          ),
        ],
      ),
    );
  }

  /// 측정 정보 섹션
  pw.Widget _buildMeasurementInfo(pw.Font font, DateTime? startTime, DateTime? endTime, int? measurementCount) {
    final duration = startTime != null && endTime != null
        ? endTime.difference(startTime)
        : null;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Measurement Information',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              font: font,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow(font, 'Start Time', startTime != null
              ? DateFormat('HH:mm:ss').format(startTime)
              : 'N/A'),
          _buildInfoRow(font, 'End Time', endTime != null
              ? DateFormat('HH:mm:ss').format(endTime)
              : 'N/A'),
          _buildInfoRow(font, 'Duration', duration != null 
              ? '${duration.inMinutes}m ${duration.inSeconds % 60}s'
              : 'N/A'),
          _buildInfoRow(font, 'Count', measurementCount != null 
              ? '$measurementCount times'
              : 'N/A'),
        ],
      ),
    );
  }

  /// 데시벨 통계 섹션
  pw.Widget _buildDecibelStatistics(pw.Font font, double? maxDecibel, double? minDecibel, double? avgDecibel) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Decibel Statistics',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              font: font,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildDecibelRow(font, 'Max', maxDecibel, PdfColors.red),
          _buildDecibelRow(font, 'Avg', avgDecibel, PdfColors.orange),
          _buildDecibelRow(font, 'Min', minDecibel, PdfColors.green),
        ],
      ),
    );
  }

  /// 위치 정보 섹션
  pw.Widget _buildLocationInfo(pw.Font font, LocationModel? location) {
    final locationService = LocationService.instance;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text(
                  '📍',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.white,
                    font: font,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                'Measurement Location',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                  font: font,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          
          if (location != null) ...[
            // 실제 위치 데이터가 있는 경우
            if (location.address != null && location.address!.isNotEmpty)
              _buildInfoRow(font, 'Address', location.address!),
            if (location.city != null && location.city!.isNotEmpty)
              _buildInfoRow(font, 'City', location.city!),
            if (location.district != null && location.district!.isNotEmpty)
              _buildInfoRow(font, 'District', location.district!),
            _buildInfoRow(font, 'Latitude', location.latitude.toStringAsFixed(6)),
            _buildInfoRow(font, 'Longitude', location.longitude.toStringAsFixed(6)),
            if (location.accuracy != null)
              _buildInfoRow(font, 'Accuracy', '${location.accuracy!.toStringAsFixed(1)}m'),
            _buildInfoRow(font, 'Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss').format(location.timestamp)),
            pw.SizedBox(height: 10),
            _buildInfoRow(font, 'Google Maps', locationService.getGoogleMapsUrl(location)),
          ] else ...[
            // 위치 데이터가 없는 경우
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey300,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey, width: 1),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        '🌍',
                        style: pw.TextStyle(fontSize: 20, font: font),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'No Location Data',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                          font: font,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Location information was not recorded. GPS may be disabled or location permission may not be granted.',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey,
                      font: font,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Sample Location Data (Demo):',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey,
                font: font,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildInfoRow(font, 'Address', '--'),
            _buildInfoRow(font, 'Latitude', '--'),
            _buildInfoRow(font, 'Longitude', '--'),
            _buildInfoRow(font, 'Accuracy', '-- m'),
          ],
          
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue300,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'ℹ️',
                  style: pw.TextStyle(fontSize: 14, font: font),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    'Location information helps accurately record noise measurement points and increases the reliability of evidence.',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey,
                      font: font,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 녹화 정보 섹션
  pw.Widget _buildVideoInfo(pw.Font font, String videoPath) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Video Information',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              font: font,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow(font, 'File Path', videoPath),
          _buildInfoRow(font, 'File Size', _getFileSize(videoPath)),
        ],
      ),
    );
  }

  /// 데시벨 수준 평가 섹션
  pw.Widget _buildDecibelLevelAssessment(pw.Font font, double? maxDecibel) {
    final maxDb = maxDecibel ?? 0;
    String level;
    String description;
    PdfColor color;

    if (maxDb < 50) {
      level = 'Very Quiet';
      description = 'Library level quiet environment';
      color = PdfColors.green;
    } else if (maxDb < 60) {
      level = 'Quiet';
      description = 'Normal office environment';
      color = PdfColors.lightGreen;
    } else if (maxDb < 70) {
      level = 'Moderate';
      description = 'Normal conversation level';
      color = PdfColors.orange;
    } else if (maxDb < 80) {
      level = 'Loud';
      description = 'Road traffic noise level';
      color = PdfColors.deepOrange;
    } else {
      level = 'Very Loud';
      description = 'Construction equipment level';
      color = PdfColors.red;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Decibel Level Assessment',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              font: font,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            level,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
              font: font,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            description,
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey,
              font: font,
            ),
          ),
        ],
      ),
    );
  }

  /// OCR 번호판 정보 섹션
  pw.Widget _buildLicensePlateInfo(pw.Font font, String? plateNumber, double? confidence, String? rawText) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.purple),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.purple,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text(
                  '🚗',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.white,
                    font: font,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                'License Plate Information',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.purple,
                  font: font,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          if (plateNumber != null && plateNumber.isNotEmpty) ...[
            _buildInfoRow(font, 'License Plate', plateNumber),
            if (confidence != null)
              _buildInfoRow(font, 'Confidence', '${(confidence * 100).toStringAsFixed(1)}%'),
            if (rawText != null && rawText.isNotEmpty)
              _buildInfoRow(font, 'Raw OCR Text', rawText),
          ] else ...[
            // OCR 데이터가 없는 경우 플레이스홀더 표시
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey300,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey, width: 1),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        '📷',
                        style: pw.TextStyle(fontSize: 20, font: font),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'No License Plate Data',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                          font: font,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'No license plate was detected. Either no license plate was recognized during measurement or OCR data is not available.',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey,
                      font: font,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Sample OCR Data (Demo):',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey,
                font: font,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildInfoRow(font, 'Plate Number', '-- --'),
            _buildInfoRow(font, 'Confidence', '--%'),
            _buildInfoRow(font, 'Raw OCR Text', 'N/A'),
          ],
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.purple300,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'ℹ️',
                  style: pw.TextStyle(fontSize: 14, font: font),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    'License plate information is useful for vehicle identification and tracking. OCR data includes license plate information collected during measurement sessions.',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey,
                      font: font,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 웨어러블 기기 건강상태 섹션
  pw.Widget _buildHealthStatusSection(pw.Font font, int? heartRate, double? stressLevel, int? stepCount, double? sleepQuality) {
    // 데이터가 없으면 샘플 데이터 표시 (향후 웨어러블 기기 연동용)
    final hasData = heartRate != null || stressLevel != null || stepCount != null || sleepQuality != null;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.teal),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text(
                  '⌚',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.white,
                    font: font,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                'Health Status (Wearable Device)',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal,
                  font: font,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          
          if (hasData) ...[
            // 실제 데이터가 있는 경우
            if (heartRate != null)
              _buildHealthMetric(font, '💗', 'Heart Rate', '$heartRate bpm', _getHeartRateColor(heartRate)),
            if (stressLevel != null)
              _buildHealthMetric(font, '😰', 'Stress Level', '${stressLevel.toStringAsFixed(1)}/10', _getStressColor(stressLevel)),
            if (stepCount != null)
              _buildHealthMetric(font, '🚶', 'Steps', '$stepCount steps', PdfColors.blue),
            if (sleepQuality != null)
              _buildHealthMetric(font, '😴', 'Sleep Quality', '${sleepQuality.toStringAsFixed(1)}/10', _getSleepQualityColor(sleepQuality)),
          ] else ...[
            // 샘플 데이터 (웨어러블 기기 미연결 상태)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey300,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey, width: 1),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        '🔗',
                        style: pw.TextStyle(fontSize: 20, font: font),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'Wearable Device Not Connected',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                          font: font,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Connect a compatible wearable device to monitor health metrics during noise exposure.',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey,
                      font: font,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Sample Health Metrics (Demo):',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey,
                font: font,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildHealthMetric(font, '💗', 'Heart Rate', '-- bpm', PdfColors.grey),
            _buildHealthMetric(font, '😰', 'Stress Level', '--/10', PdfColors.grey),
            _buildHealthMetric(font, '🚶', 'Steps', '-- steps', PdfColors.grey),
            _buildHealthMetric(font, '😴', 'Sleep Quality', '--/10', PdfColors.grey),
          ],
          
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal300,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'ℹ️',
                  style: pw.TextStyle(fontSize: 14, font: font),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    'Health metrics help assess the impact of noise exposure on wellbeing. Data collected during measurement session.',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey,
                      font: font,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 건강 지표 행 생성
  pw.Widget _buildHealthMetric(pw.Font font, String emoji, String label, String value, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 30,
            child: pw.Text(
              emoji,
              style: pw.TextStyle(fontSize: 16, font: font),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 13,
                color: PdfColors.grey,
                font: font,
              ),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey300,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                  font: font,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 심박수 색상 결정
  PdfColor _getHeartRateColor(int heartRate) {
    if (heartRate < 60) return PdfColors.blue;          // 서맥
    if (heartRate <= 100) return PdfColors.green;       // 정상
    if (heartRate <= 120) return PdfColors.orange;      // 경미한 빈맥
    return PdfColors.red;                                // 빈맥
  }

  /// 스트레스 수준 색상 결정
  PdfColor _getStressColor(double stressLevel) {
    if (stressLevel <= 3) return PdfColors.green;       // 낮음
    if (stressLevel <= 6) return PdfColors.orange;      // 보통
    return PdfColors.red;                                // 높음
  }

  /// 수면 품질 색상 결정
  PdfColor _getSleepQualityColor(double sleepQuality) {
    if (sleepQuality >= 8) return PdfColors.green;      // 우수
    if (sleepQuality >= 6) return PdfColors.orange;     // 보통
    return PdfColors.red;                                // 나쁨
  }

  /// 푸터 섹션
  pw.Widget _buildFooter(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      child: pw.Column(
        children: [
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text(
            'ActFinder - Decibel Measurement Report',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey,
              font: font,
            ),
          ),
          pw.Text(
            'Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey,
              font: font,
            ),
          ),
        ],
      ),
    );
  }

  /// 정보 행 생성
  pw.Widget _buildInfoRow(pw.Font font, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey,
              font: font,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: font,
            ),
          ),
        ],
      ),
    );
  }

  /// 데시벨 행 생성
  pw.Widget _buildDecibelRow(pw.Font font, String label, double? value, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey,
              font: font,
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
            ),
            child: pw.Text(
              value != null ? '${value.toStringAsFixed(2)} dB' : 'N/A',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: color,
                font: font,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 소음 측정 리포트 PDF 생성 (recording_screen.dart에서 사용)
  Future<String> generateNoiseReport({
    required double maxDecibel,
    required double minDecibel,
    required double avgDecibel,
    required int measurementCount,
    required DateTime startTime,
    DateTime? endTime,
    List<double>? readings,
    // OCR 번호판 정보 (선택사항)
    String? licensePlateNumber,
    double? licensePlateConfidence,
    String? licensePlateRawText,
    // 위치 정보 (선택사항)
    LocationModel? location,
  }) async {
    print('PDF 생성 - 번호판 정보: $licensePlateNumber, 신뢰도: $licensePlateConfidence');
    return await generateDecibelReport(
      maxDecibel: maxDecibel,
      minDecibel: minDecibel,
      avgDecibel: avgDecibel,
      startTime: startTime,
      endTime: endTime,
      measurementCount: measurementCount,
      licensePlateNumber: licensePlateNumber,
      licensePlateConfidence: licensePlateConfidence,
      licensePlateRawText: licensePlateRawText,
      location: location,
    ) ?? '';
  }

  /// 테스트용 PDF 생성 (번호판 섹션 포함)
  Future<String?> generateTestPdfWithLicensePlate() async {
    print('테스트 PDF 생성 시작 (번호판 섹션 포함)...');
    return await generateDecibelReport(
      maxDecibel: 85.5,
      minDecibel: 45.2,
      avgDecibel: 65.8,
      startTime: DateTime.now().subtract(const Duration(minutes: 5)),
      endTime: DateTime.now(),
      measurementCount: 50,
      licensePlateNumber: '12가3456',
      licensePlateConfidence: 0.95,
      licensePlateRawText: '12가3456 TEST',
    );
  }

  /// 파일 크기 계산
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
    return 'N/A';
  }
}

extension on PdfColor {
  void withOpacity(double d) {}
}
