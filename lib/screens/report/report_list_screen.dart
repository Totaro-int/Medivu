import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/report_model.dart';
import '../../widgets/primary_button.dart';
import '../../utils/constants.dart';
import '../../services/enhanced_database_helper.dart';
import '../../providers/enhanced_auth_provider.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  List<ReportModel> _reports = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // 'all', 'draft', 'ready', 'submitted'

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 로그인한 사용자 ID 가져오기
      final authProvider = Provider.of<EnhancedAuthProvider>(context, listen: false);
      final userId = authProvider.userId;
      
      print('🔍 리포트 목록 로드 시작');
      print('  - 로그인 상태: ${authProvider.isLoggedIn}');
      print('  - 사용자 ID (userId): $userId');
      print('  - 사용자 ID 타입: ${userId.runtimeType}');
      print('  - currentUser?.id: ${authProvider.currentUser?.id}');
      
      if (userId == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }
      
      // 실제 DB에서 해당 사용자의 리포트 데이터 조회
      print('  - DB에서 사용자 리포트 데이터 조회 시작...');
      final numericUserId = int.tryParse(userId) ?? 1;
      final reports = await EnhancedDatabaseHelper.instance.getUserReports(numericUserId);
      
      print('  - 조회된 리포트 데이터 개수: ${reports.length}');
      
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 리포트 목록 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('리포트 로딩 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // _getMockReports() 메서드 제거됨 - 실제 DB 조회로 대체

  List<ReportModel> get _filteredReports {
    if (_filterStatus == 'all') {
      return _reports;
    }
    return _reports.where((report) => report.status.name == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _filteredReports;

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
                        '보고서 목록',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.filter_list, color: Colors.white),
                      ),
                      onSelected: (String status) {
                        setState(() {
                          _filterStatus = status;
                        });
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: 'all',
                          child: Row(
                            children: [
                              Icon(
                                Icons.list,
                                color: _filterStatus == 'all' ? const Color(0xFF667eea) : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '전체',
                                style: TextStyle(
                                  color: _filterStatus == 'all' ? const Color(0xFF667eea) : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'draft',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                color: _filterStatus == 'draft' ? const Color(0xFF667eea) : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '작성중',
                                style: TextStyle(
                                  color: _filterStatus == 'draft' ? const Color(0xFF667eea) : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'ready',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: _filterStatus == 'ready' ? const Color(0xFF667eea) : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '준비됨',
                                style: TextStyle(
                                  color: _filterStatus == 'ready' ? const Color(0xFF667eea) : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'submitted',
                          child: Row(
                            children: [
                              Icon(
                                Icons.send,
                                color: _filterStatus == 'submitted' ? const Color(0xFF667eea) : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '제출됨',
                                style: TextStyle(
                                  color: _filterStatus == 'submitted' ? const Color(0xFF667eea) : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                              color: Color(0xFF667eea),
                            ),
                          )
                        : filteredReports.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                color: const Color(0xFF667eea),
                                onRefresh: _loadReports,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(24),
                                  itemCount: filteredReports.length,
                                  itemBuilder: (context, index) {
                                    final report = filteredReports[index];
                                    return _buildReportCard(report);
                                  },
                                ),
                              ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/record');
        },
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String message;
    
    switch (_filterStatus) {
      case 'draft':
        title = '작성중인 리포트가 없습니다';
        message = '새로운 녹화를 시작하여 리포트를 작성해보세요';
        break;
      case 'ready':
        title = '준비된 리포트가 없습니다';
        message = '작성된 리포트를 완료해보세요';
        break;
      case 'submitted':
        title = '제출된 리포트가 없습니다';
        message = '준비된 리포트를 제출해보세요';
        break;
      default:
        title = '보고서가 없습니다';
        message = '새로운 녹화를 시작하여 리포트를 생성해보세요';
    }

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
                color: const Color(0xFFBFC6FF),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.description,
                size: 60,
                color: Color(0xFF7B8AFF),
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
            const SizedBox(height: AppConstants.paddingLarge),
            
            // 디버그 정보 표시
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '전체 리포트: ${_reports.length}개',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '필터: $_filterStatus',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PrimaryButton(
                  text: '새로고침',
                  onPressed: _loadReports,
                  backgroundColor: Colors.orange,
                  width: 120,
                ),
                const SizedBox(width: 16),
                PrimaryButton(
                  text: '녹화 시작',
                  onPressed: () {
                    Navigator.pushNamed(context, '/record');
                  },
                  backgroundColor: const Color(0xFF7B8AFF),
                  width: 120,
                ),
              ],
            ),
          ],
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
                      color: _getStatusColor(report.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    ),
                    child: Icon(
                      _getStatusIcon(report.status),
                      color: _getStatusColor(report.status),
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
                  _buildStatusChip(report.status),
                ],
              ),
              // 측정 데이터 요약 표시
              const SizedBox(height: AppConstants.paddingSmall),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildMeasurementInfo('최대', '${report.recording.noiseData.maxDecibel?.toStringAsFixed(1) ?? '0.0'}dB', Colors.red),
                    const SizedBox(width: 8),
                    _buildMeasurementInfo('평균', '${report.recording.noiseData.avgDecibel?.toStringAsFixed(1) ?? '0.0'}dB', Colors.orange),
                    const SizedBox(width: 8),
                    _buildMeasurementInfo('횟수', '${report.recording.noiseData.measurementCount ?? 0}회', Colors.blue),
                  ],
                ),
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
              const SizedBox(height: AppConstants.paddingMedium),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppConstants.paddingSmall,
                      children: [
                        _buildInfoChip(
                          Icons.volume_up,
                          '${report.recording.noiseData.maxDecibel?.toStringAsFixed(1) ?? '0.0'}dB',
                          Colors.red,
                        ),
                        if (report.recording.duration != null)
                          _buildInfoChip(
                            Icons.timer,
                            _formatDuration(report.recording.duration!),
                            Colors.blue,
                          ),
                        if (report.hasPdf)
                          _buildInfoChip(
                            Icons.picture_as_pdf,
                            'PDF',
                            Colors.green,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (action) => _handleReportAction(action, report),
                    itemBuilder: (BuildContext context) => [
                      if (report.status == ReportStatus.draft)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('편집'),
                            ],
                          ),
                        ),
                      if (report.status == ReportStatus.ready)
                        const PopupMenuItem(
                          value: 'submit',
                          child: Row(
                            children: [
                              Icon(Icons.send, size: 18),
                              SizedBox(width: 8),
                              Text('제출'),
                            ],
                          ),
                        ),
                      if (report.hasPdf)
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 18),
                              SizedBox(width: 8),
                              Text('공유'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('삭제', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ReportStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _getStatusText(status),
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
        color: color.withOpacity(0.1),
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

  IconData _getStatusIcon(ReportStatus status) {
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
      default:
        return Icons.description;
    }
  }

  Color _getStatusColor(ReportStatus status) {
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
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(ReportStatus status) {
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
      default:
        return status.name;
    }
  }

  void _handleReportAction(String action, ReportModel report) {
    switch (action) {
      case 'edit':
        _editReport(report);
        break;
      case 'submit':
        _submitReport(report);
        break;
      case 'share':
        _shareReport(report);
        break;
      case 'delete':
        _deleteReport(report);
        break;
    }
  }

  void _editReport(ReportModel report) {
    Navigator.pushNamed(
      context,
      '/report',
      arguments: {
        'reportId': report.id,
        'editMode': true,
      },
    );
  }

  void _submitReport(ReportModel report) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('리포트 제출'),
          content: const Text('이 리포트를 제출하시겠습니까?\n제출 후에는 수정할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performSubmitReport(report);
              },
              child: const Text('제출'),
            ),
          ],
        );
      },
    );
  }

  void _performSubmitReport(ReportModel report) {
    // TODO: 실제 리포트 제출 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('리포트가 제출되었습니다.')),
    );
    _loadReports(); // 목록 새로고침
  }

  void _shareReport(ReportModel report) {
    // TODO: 리포트 공유 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('공유 기능이 준비 중입니다.')),
    );
  }

  void _deleteReport(ReportModel report) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('리포트 삭제'),
          content: const Text('이 리포트를 삭제하시겠습니까?\n삭제된 리포트는 복구할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performDeleteReport(report);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  void _performDeleteReport(ReportModel report) {
    // TODO: 실제 리포트 삭제 구현
    setState(() {
      _reports.removeWhere((r) => r.id == report.id);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('리포트가 삭제되었습니다.')),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildMeasurementInfo(String label, String value, Color color) {
    return Expanded(
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
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}