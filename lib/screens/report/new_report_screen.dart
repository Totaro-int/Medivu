import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/recording_model.dart';
import '../../models/location_model.dart';
import '../../models/license_plate_model.dart';

class NewReportScreen extends StatefulWidget {
  final Map<String, dynamic>? reportData;
  
  const NewReportScreen({super.key, this.reportData});

  @override
  State<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen> {
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // 전달받은 데이터가 있으면 사용, 없으면 기본값
    _data = widget.reportData ?? {
      'maxDecibel': 45.0,
      'minDecibel': 30.0,
      'avgDecibel': 37.5,
      'startTime': DateTime.now().subtract(const Duration(minutes: 5)),
      'endTime': DateTime.now(),
      'measurementCount': 120,
      'currentLocation': null,
      'detectedPlate': null,
      'videoPath': null,
    };
    
    print('📊 보고서 데이터 초기화 완료');
    print('  - 최대 데시벨: ${_data['maxDecibel']}dB');
    print('  - 측정 횟수: ${_data['measurementCount']}회');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('소음 측정 보고서'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _shareReport,
            icon: const Icon(Icons.share),
            tooltip: '보고서 공유',
          ),
          IconButton(
            onPressed: _exportToPDF,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'PDF 내보내기',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildReportHeader(),
            const SizedBox(height: 16),
            _buildTimeSection(),
            const SizedBox(height: 16),
            _buildLocationSection(),
            const SizedBox(height: 16),
            _buildDecibelSection(),
            const SizedBox(height: 16),
            _buildLicensePlateSection(),
            const SizedBox(height: 16),
            _buildWearableSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.assessment,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            '소음 측정 보고서',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '생성일: ${DateFormat('yyyy년 MM월 dd일 HH:mm').format(DateTime.now())}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection() {
    final startTime = _data['startTime'] as DateTime?;
    final endTime = _data['endTime'] as DateTime?;
    final duration = startTime != null && endTime != null 
        ? endTime.difference(startTime) 
        : const Duration(minutes: 5);

    return _buildSectionCard(
      title: '⏰ 측정 시간',
      icon: Icons.access_time,
      iconColor: Colors.blue,
      child: Column(
        children: [
          _buildInfoRow('시작 시간', startTime != null 
              ? DateFormat('yyyy.MM.dd HH:mm:ss').format(startTime)
              : '정보 없음'),
          const Divider(height: 20),
          _buildInfoRow('종료 시간', endTime != null 
              ? DateFormat('yyyy.MM.dd HH:mm:ss').format(endTime)
              : '정보 없음'),
          const Divider(height: 20),
          _buildInfoRow('측정 시간', '${duration.inMinutes}분 ${duration.inSeconds % 60}초'),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final location = _data['currentLocation'] as LocationModel?;
    
    return _buildSectionCard(
      title: '📍 측정 위치',
      icon: Icons.location_on,
      iconColor: Colors.green,
      child: location != null 
          ? Column(
              children: [
                _buildInfoRow('주소', location.address ?? '주소 정보 없음'),
                const Divider(height: 20),
                _buildInfoRow('위도', location.latitude.toStringAsFixed(6)),
                const Divider(height: 20),
                _buildInfoRow('경도', location.longitude.toStringAsFixed(6)),
                const Divider(height: 20),
                _buildInfoRow('정확도', '±${location.accuracy?.toStringAsFixed(1) ?? '알 수 없음'}m'),
              ],
            )
          : const Text(
              '위치 정보가 없습니다.\n측정 시 GPS를 활성화해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
    );
  }

  Widget _buildDecibelSection() {
    final maxDecibel = _data['maxDecibel'] as double? ?? 0.0;
    final minDecibel = _data['minDecibel'] as double? ?? 0.0;
    final avgDecibel = _data['avgDecibel'] as double? ?? 0.0;
    final measurementCount = _data['measurementCount'] as int? ?? 0;

    return _buildSectionCard(
      title: '🔊 소음 측정 결과',
      icon: Icons.graphic_eq,
      iconColor: Colors.red,
      child: Column(
        children: [
          // 메인 데시벨 표시
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.volume_up, color: Colors.red, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    const Text(
                      '최대 소음 레벨',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${maxDecibel.toStringAsFixed(1)} dB',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // 상세 측정 데이터
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('평균', '${avgDecibel.toStringAsFixed(1)} dB', Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard('최소', '${minDecibel.toStringAsFixed(1)} dB', Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('측정 횟수', '$measurementCount회', Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard('노이즈 레벨', _getNoiseLevel(maxDecibel), _getNoiseLevelColor(maxDecibel)),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 소음 기준 안내
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 소음 기준 참고',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• 조용한 도서관: 30-40dB\n'
                  '• 일반 대화: 50-60dB\n'
                  '• 시끄러운 식당: 70-80dB\n'
                  '• 자동차 경적: 90-100dB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicensePlateSection() {
    final detectedPlate = _data['detectedPlate'] as LicensePlateModel?;
    
    return _buildSectionCard(
      title: '🚗 번호판 인식 결과',
      icon: Icons.drive_eta,
      iconColor: Colors.indigo,
      child: detectedPlate != null 
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, color: Colors.indigo, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '인식된 번호판',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              detectedPlate.plateNumber ?? '인식 실패',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('신뢰도', '${((detectedPlate.confidence ?? 0.0) * 100).toStringAsFixed(1)}%'),
                const Divider(height: 20),
                _buildInfoRow('인식 시간', detectedPlate.detectedAt != null 
                    ? DateFormat('HH:mm:ss').format(detectedPlate.detectedAt!)
                    : '정보 없음'),
                if (detectedPlate.rawText != null && detectedPlate.rawText!.isNotEmpty) ...[
                  const Divider(height: 20),
                  _buildInfoRow('원본 텍스트', detectedPlate.rawText!),
                ],
              ],
            )
          : Column(
              children: [
                const Icon(
                  Icons.no_photography,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  '번호판이 인식되지 않았습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '측정 환경이나 카메라 각도를 조정해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWearableSection() {
    return _buildSectionCard(
      title: '⌚ 웨어러블 기기 데이터',
      icon: Icons.watch,
      iconColor: Colors.teal,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.construction,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  '웨어러블 기기 연동 준비중',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '향후 업데이트에서 제공될 예정입니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                
                // 미래에 표시될 데이터 미리보기
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '📊 예정된 측정 항목',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildPlaceholderMetric('심박수', '-- BPM', Icons.favorite)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildPlaceholderMetric('스트레스', '-- %', Icons.psychology)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildPlaceholderMetric('걸음수', '-- 보', Icons.directions_walk)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildPlaceholderMetric('수면질', '-- %', Icons.bedtime)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _exportToPDF,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF로 내보내기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareReport,
                icon: const Icon(Icons.share),
                label: const Text('공유하기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF667eea),
                  side: const BorderSide(color: Color(0xFF667eea)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('닫기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  String _getNoiseLevel(double decibel) {
    if (decibel < 40) return '조용함';
    if (decibel < 60) return '보통';
    if (decibel < 80) return '시끄러움';
    return '매우 시끄러움';
  }

  Color _getNoiseLevelColor(double decibel) {
    if (decibel < 40) return Colors.green;
    if (decibel < 60) return Colors.orange;
    if (decibel < 80) return Colors.red;
    return Colors.purple;
  }

  void _shareReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📤 보고서 공유 기능이 준비 중입니다'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 PDF 내보내기 기능이 준비 중입니다'),
        backgroundColor: Colors.green,
      ),
    );
  }
}