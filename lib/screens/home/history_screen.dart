import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/recording_model.dart';
import '../../models/report_model.dart';
import '../../widgets/primary_button.dart';
import '../../utils/constants.dart';
import '../../services/enhanced_database_helper.dart';
import '../../providers/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RecordingModel> _recordings = [];
  List<ReportModel> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 로그인한 사용자 ID 가져오기
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }
      
      // 실제 DB에서 데이터 조회 - EnhancedDatabaseHelper 직접 사용
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

  // _getMockRecordings() 및 _getMockReports() 메서드 제거됨 - 실제 DB 조회로 대체

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
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
                        '최근 기록',
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

              // 탭바
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelColor: const Color(0xFF667eea),
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.videocam),
                      text: '녹화 기록',
                    ),
                    Tab(
                      icon: Icon(Icons.description),
                      text: '보고서',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                              color: Color(0xFF667eea),
                            ),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildRecordingsTab(),
                              _buildReportsTab(),
                            ],
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

  Widget _buildRecordingsTab() {
    if (_recordings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.videocam,
        title: '녹화 기록이 없습니다',
        message: '새로운 녹화를 시작하여 기록을 남겨보세요',
        actionText: '녹화 시작',
        onAction: () {
          Navigator.pushNamed(context, '/record');
        },
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF667eea),
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: _recordings.length,
        itemBuilder: (context, index) {
          final recording = _recordings[index];
          return _buildRecordingCard(recording);
        },
      ),
    );
  }

  Widget _buildReportsTab() {
    if (_reports.isEmpty) {
      return _buildEmptyState(
        icon: Icons.description,
        title: '보고서가 없습니다',
        message: '녹화 완료 후 보고서를 생성해보세요',
        actionText: '녹화 시작',
        onAction: () {
          Navigator.pushNamed(context, '/record');
        },
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF667eea),
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                icon,
                size: 60,
                color: const Color(0xFF667eea),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingXLarge),
            PrimaryButton(
              text: actionText,
              onPressed: onAction,
              backgroundColor: const Color(0xFF667eea),
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingCard(RecordingModel recording) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/videoDetail',
            arguments: {
              'recordingId': recording.id,
            },
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    ),
                    child: const Icon(
                      Icons.videocam,
                      color: Color(0xFF667eea),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('yyyy.MM.dd HH:mm').format(recording.startTime),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRecordingStatusText(recording.status),
                          style: TextStyle(
                            fontSize: 14,
                            color: _getRecordingStatusColor(recording.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildRecordingStatusChip(recording.status),
                ],
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.volume_up,
                    '${recording.noiseData.maxDecibel?.toStringAsFixed(1) ?? '0.0'}dB',
                    Colors.red,
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  if (recording.duration != null)
                    _buildInfoChip(
                      Icons.timer,
                      _formatDuration(recording.duration!),
                      Colors.blue,
                    ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  if (recording.videoPath != null)
                    _buildInfoChip(
                      Icons.video_file,
                      'Video',
                      Colors.green,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/report',
            arguments: {
              'reportId': report.id,
            },
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getReportStatusColor(report.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    ),
                    child: Icon(
                      _getReportStatusIcon(report.status),
                      color: _getReportStatusColor(report.status),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title.isNotEmpty ? report.title : '제목 없음',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('yyyy.MM.dd HH:mm').format(report.createdAt),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildReportStatusChip(report.status),
                ],
              ),
              if (report.description.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  report.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingStatusChip(RecordingStatus status) {
    final color = _getRecordingStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _getRecordingStatusText(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildReportStatusChip(ReportStatus status) {
    final color = _getReportStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _getReportStatusText(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getRecordingStatusText(RecordingStatus status) {
    switch (status) {
      case RecordingStatus.draft:
        return '임시저장';
      case RecordingStatus.recording:
        return '녹화중';
      case RecordingStatus.completed:
        return '완료';
      case RecordingStatus.processing:
        return '처리중';
      case RecordingStatus.failed:
        return '실패';
      case RecordingStatus.uploaded:
        return '업로드됨';
    }
  }

  Color _getRecordingStatusColor(RecordingStatus status) {
    switch (status) {
      case RecordingStatus.draft:
        return Colors.grey;
      case RecordingStatus.recording:
        return Colors.red;
      case RecordingStatus.completed:
        return Colors.green;
      case RecordingStatus.processing:
        return Colors.orange;
      case RecordingStatus.failed:
        return Colors.red;
      case RecordingStatus.uploaded:
        return Colors.blue;
    }
  }

  IconData _getReportStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return Icons.edit;
      case ReportStatus.processing:
        return Icons.hourglass_empty;
      case ReportStatus.ready:
        return Icons.check_circle;
      case ReportStatus.submitted:
        return Icons.send;
      case ReportStatus.rejected:
        return Icons.error;
      case ReportStatus.approved:
        return Icons.verified;
    }
  }

  Color _getReportStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return Colors.grey;
      case ReportStatus.processing:
        return Colors.orange;
      case ReportStatus.ready:
        return Colors.blue;
      case ReportStatus.submitted:
        return Colors.green;
      case ReportStatus.rejected:
        return Colors.red;
      case ReportStatus.approved:
        return Colors.green;
    }
  }

  String _getReportStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return '작성중';
      case ReportStatus.processing:
        return '처리중';
      case ReportStatus.ready:
        return '준비됨';
      case ReportStatus.submitted:
        return '제출됨';
      case ReportStatus.rejected:
        return '반려됨';
      case ReportStatus.approved:
        return '승인됨';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}