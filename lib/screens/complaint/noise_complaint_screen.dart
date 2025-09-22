import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/recording_model.dart';
import '../../models/report_model.dart';
import '../../widgets/primary_button.dart' hide IconButton;
import '../../services/enhanced_database_helper.dart';
import '../../services/pdf_service.dart';
import '../../providers/auth_provider.dart';

class NoiseComplaintScreen extends StatefulWidget {
  const NoiseComplaintScreen({super.key});

  @override
  State<NoiseComplaintScreen> createState() => _NoiseComplaintScreenState();
}

class _NoiseComplaintScreenState extends State<NoiseComplaintScreen> {
  List<RecordingModel> _recordings = [];
  List<ReportModel> _reports = [];
  bool _isLoading = true;

  final List<ComplaintLink> _complaintLinks = [
    ComplaintLink(
      name: '국민신문고',
      description: '정부 기관 통합 민원 서비스',
      icon: Icons.account_balance,
      url: 'https://www.epeople.go.kr/index.jsp',
      color: const Color(0xFF2563EB),
    ),
    ComplaintLink(
      name: '환경부 신고센터',
      description: '소음·진동 환경 신고',
      icon: Icons.eco,
      url: 'https://minwon.me.go.kr/index.do',
      color: const Color(0xFF059669),
    ),
    ComplaintLink(
      name: '경찰청 신고',
      description: '소음으로 인한 생활방해',
      icon: Icons.security,
      url: 'https://www.safetyreport.go.kr/#main',
      color: const Color(0xFF1565C0),
    ),
    // ComplaintLink(
    //   name: '소비자분쟁조정위원회',
    //   description: '소음 피해 분쟁 조정',
    //   icon: Icons.gavel,
    //   url: 'https://www.ccn.go.kr/',
    //   color: const Color(0xFF7C3AED),
    // ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }
      
      // Direct use of EnhancedDatabaseHelper instead of service layer
      final numericUserId = int.tryParse(userId) ?? 1;
      final recordings = await EnhancedDatabaseHelper.instance.getUserSessions(numericUserId);
      final reports = await EnhancedDatabaseHelper.instance.getUserReports(numericUserId);
      
      setState(() {
        _recordings = recordings;
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로딩 실패: $e')),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      print('🔗 URL 열기 시도: $url');
      final Uri uri = Uri.parse(url);
      
      // URL 유효성 검사
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        throw 'Invalid URL scheme: ${uri.scheme}';
      }
      
      // Android에서는 canLaunchUrl이 때때로 false를 반환하므로 바로 실행 시도
      print('🚀 URL 직접 실행 시도...');
      final result = await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      print('URL 실행 결과: $result');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 외부 브라우저에서 페이지를 열었습니다'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ URL 열기 실패: $e');
      
      // 대안: 시스템 기본 브라우저로 열기 시도
      try {
        print('🔄 시스템 기본 모드로 재시도...');
        await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 기본 브라우저에서 페이지를 열었습니다'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e2) {
        print('❌ 재시도도 실패: $e2');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('링크 열기 실패. 수동으로 브라우저에서 $url 을 열어주세요.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: '복사',
                textColor: Colors.white,
                onPressed: () {
                  // URL을 클립보드에 복사
                  // import 'package:flutter/services.dart'; 가 필요
                },
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _generateAndSharePDF(dynamic selectedData) async {
    try {
      final pdfService = PdfService();
      String? pdfPath;

      if (selectedData is RecordingModel) {
        pdfPath = await pdfService.generateDecibelReport(
          maxDecibel: selectedData.noiseData.maxDecibel,
          minDecibel: selectedData.noiseData.minDecibel,
          avgDecibel: selectedData.noiseData.avgDecibel,
          startTime: selectedData.startTime,
          endTime: selectedData.endTime,
          measurementCount: selectedData.noiseData.measurementCount ?? 0,
          licensePlateNumber: null, // 실제 OCR 데이터로 교체
          licensePlateConfidence: null,
          licensePlateRawText: null,
        );
      } else if (selectedData is ReportModel) {
        pdfPath = await pdfService.generateDecibelReport(
          maxDecibel: selectedData.recording.noiseData.maxDecibel,
          minDecibel: selectedData.recording.noiseData.minDecibel,
          avgDecibel: selectedData.recording.noiseData.avgDecibel,
          startTime: selectedData.recording.startTime,
          endTime: selectedData.recording.endTime,
          measurementCount: selectedData.recording.noiseData.measurementCount ?? 0,
        );
      }

      if (pdfPath != null && mounted) {
        // PDF 생성 성공 메시지와 함께 파일 경로를 클립보드에 복사
        await Clipboard.setData(ClipboardData(text: pdfPath));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF가 생성되었습니다. 파일 경로가 클립보드에 복사되었습니다.'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: '확인',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 생성 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE53E3E),
              Color(0xFFC53030),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 헤더
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        '소음 신고',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 40), // Balance the back button
                  ],
                ),
              ),

              // 메인 컨텐츠
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFE53E3E),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                
                                // 안내 메시지
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53E3E).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE53E3E).withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Color(0xFFE53E3E),
                                        size: 24,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '측정한 소음 데이터와 함께 아래 관련 기관에 신고하세요',
                                          style: TextStyle(
                                            color: Color(0xFFE53E3E),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 30),
                                
                                // 측정 데이터 요약
                                if (_recordings.isNotEmpty || _reports.isNotEmpty) ...[
                                  const Text(
                                    '측정 데이터',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDataSummarySection(),
                                  const SizedBox(height: 30),
                                ],
                                
                                // 신고 기관 링크들
                                const Text(
                                  '신고 기관',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                ..._complaintLinks.map((link) => _buildComplaintLinkCard(link)),
                                
                                const SizedBox(height: 30),
                                
                                // 도움말 섹션
                                _buildHelpSection(),
                                
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataSummarySection() {
    if (_recordings.isEmpty && _reports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.folder_open,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '측정 데이터가 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '먼저 소음을 측정하고 데이터를 생성해주세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: '측정하러 가기',
              onPressed: () {
                Navigator.pushNamed(context, '/record');
              },
              backgroundColor: const Color(0xFFE53E3E),
              width: 160,
            ),
          ],
        ),
      );
    }

    // 최근 데이터 요약 표시
    return Column(
      children: [
        if (_recordings.isNotEmpty) ...[
          _buildLatestRecordingCard(_recordings.first),
          const SizedBox(height: 12),
        ],
        if (_reports.isNotEmpty) ...[
          _buildLatestReportCard(_reports.first),
          const SizedBox(height: 12),
        ],
        if (_recordings.length + _reports.length > 2)
          TextButton(
            onPressed: () {
              // 전체 데이터 보기 기능 (선택사항)
            },
            child: Text('총 ${_recordings.length + _reports.length}개 데이터 보유'),
          ),
      ],
    );
  }

  Widget _buildLatestRecordingCard(RecordingModel recording) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4299E1).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4299E1).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF4299E1).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.videocam,
              color: Color(0xFF4299E1),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 측정 영상',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4299E1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('yyyy.MM.dd HH:mm').format(recording.startTime),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '최대: ${recording.noiseData.maxDecibel?.toStringAsFixed(1) ?? '0.0'}dB',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _generateAndSharePDF(recording),
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFE53E3E)),
            tooltip: 'PDF 생성',
          ),
        ],
      ),
    );
  }

  Widget _buildLatestReportCard(ReportModel report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF48BB78).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF48BB78).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF48BB78).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description,
              color: Color(0xFF48BB78),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 측정 리포트',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF48BB78),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.title.isNotEmpty ? report.title : '제목 없음',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('yyyy.MM.dd').format(report.createdAt),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _generateAndSharePDF(report),
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFE53E3E)),
            tooltip: 'PDF 생성',
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintLinkCard(ComplaintLink link) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchUrl(link.url),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: link.color.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: link.color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: link.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    link.icon,
                    color: link.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        link.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: link.color,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Color(0xFF667eea),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                '신고 도움말',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHelpItem('1. 측정 데이터 준비', '소음 측정 영상 또는 리포트의 PDF를 생성하세요'),
          _buildHelpItem('2. 신고 기관 선택', '소음 유형과 발생 위치에 맞는 기관을 선택하세요'),
          _buildHelpItem('3. 증빙 자료 제출', '측정 데이터와 함께 사진, 동영상 등을 첨부하세요'),
          _buildHelpItem('4. 신고 접수 확인', '신고 접수 후 처리 과정을 추적하세요'),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF667eea),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ComplaintLink {
  final String name;
  final String description;
  final IconData icon;
  final String url;
  final Color color;

  ComplaintLink({
    required this.name,
    required this.description,
    required this.icon,
    required this.url,
    required this.color,
  });
}