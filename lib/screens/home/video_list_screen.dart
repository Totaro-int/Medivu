import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/recording_model.dart';
import '../../widgets/primary_button.dart';
import '../../utils/constants.dart';
import '../../services/enhanced_database_helper.dart';
import '../../providers/enhanced_auth_provider.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  List<RecordingModel> _videos = [];
  bool _isLoading = true;
  String _sortBy = 'date'; // 'date', 'size', 'duration'
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 로그인한 사용자 ID 가져오기
      final authProvider = Provider.of<EnhancedAuthProvider>(context, listen: false);
      final userId = authProvider.userId;
      
      print('🔍 동영상 목록 로드 시작');
      print('  - 로그인 상태: ${authProvider.isLoggedIn}');
      print('  - 현재 사용자: ${authProvider.currentUser}');
      print('  - 사용자 ID: $userId');
      print('  - 사용자 ID 타입: ${userId.runtimeType}');
      
      if (userId == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }
      
      // 실제 DB에서 해당 사용자의 녹화 데이터 조회 - EnhancedDatabaseHelper 직접 사용
      print('  - DB에서 사용자 녹화 데이터 조회 시작...');
      final numericUserId = int.tryParse(userId) ?? 1;
      final recordings = await EnhancedDatabaseHelper.instance.getUserSessions(numericUserId);
      
      print('  - 조회된 녹화 데이터 개수: ${recordings.length}');
      
      setState(() {
        _videos = recordings;
        _sortVideos();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비디오 로딩 실패: $e')),
        );
      }
    }
  }

  // _getMockVideos() 메서드 제거됨 - 실제 DB 조회로 대체

  void _sortVideos() {
    _videos.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'date':
          comparison = a.startTime.compareTo(b.startTime);
          break;
        case 'duration':
          final aDuration = a.duration ?? Duration.zero;
          final bDuration = b.duration ?? Duration.zero;
          comparison = aDuration.compareTo(bDuration);
          break;
        case 'size':
          // 파일 크기 정보가 없으므로 비디오 길이로 대체 정렬
          final aDuration = a.duration?.inSeconds ?? 0;
          final bDuration = b.duration?.inSeconds ?? 0;
          comparison = aDuration.compareTo(bDuration);
          break;
      }
      
      return _isAscending ? comparison : -comparison;
    });
  }

  void _changeSortOrder(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _isAscending = !_isAscending;
      } else {
        _sortBy = sortBy;
        _isAscending = false;
      }
      _sortVideos();
    });
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
                        '동영상 목록',
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
                        child: const Icon(Icons.sort, color: Colors.white),
                      ),
                      onSelected: _changeSortOrder,
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: 'date',
                          child: Row(
                            children: [
                              Icon(
                                Icons.date_range,
                                color: _sortBy == 'date' ? const Color(0xFF667eea) : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '날짜순',
                                style: TextStyle(
                                  color: _sortBy == 'date' ? const Color(0xFF667eea) : Colors.black,
                                ),
                              ),
                              if (_sortBy == 'date')
                                Icon(
                                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 16,
                                  color: const Color(0xFF667eea),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'duration',
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer,
                                color: _sortBy == 'duration' ? const Color(0xFF667eea) : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '길이순',
                                style: TextStyle(
                                  color: _sortBy == 'duration' ? const Color(0xFF667eea) : Colors.black,
                                ),
                              ),
                              if (_sortBy == 'duration')
                                Icon(
                                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 16,
                                  color: const Color(0xFF667eea),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'size',
                          child: Row(
                            children: [
                              Icon(
                                Icons.storage,
                                color: _sortBy == 'size' ? const Color(0xFF667eea) : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '크기순',
                                style: TextStyle(
                                  color: _sortBy == 'size' ? const Color(0xFF667eea) : Colors.black,
                                ),
                              ),
                              if (_sortBy == 'size')
                                Icon(
                                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 16,
                                  color: const Color(0xFF667eea),
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
                        : _videos.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                color: const Color(0xFF667eea),
                                onRefresh: _loadVideos,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(24),
                                  itemCount: _videos.length,
                                  itemBuilder: (context, index) {
                                    final video = _videos[index];
                                    return _buildVideoCard(video);
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
        child: const Icon(Icons.videocam, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              child: const Icon(
                Icons.videocam_off,
                size: 60,
                color: Color(0xFF667eea),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            const Text(
              '저장된 동영상이 없습니다',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            const Text(
              '새로운 녹화를 시작해보세요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingXLarge),
            PrimaryButton(
              text: '녹화 시작',
              onPressed: () {
                Navigator.pushNamed(context, '/record');
              },
              backgroundColor: const Color(0xFF667eea),
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(RecordingModel video) {
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
            arguments: video.id,
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              // 썸네일 (임시로 아이콘 사용)
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.play_circle_fill,
                      color: Color(0xFF667eea),
                      size: 32,
                    ),
                    if (video.duration != null)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            _formatDuration(video.duration!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('yyyy.MM.dd HH:mm').format(video.startTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (video.location?.address != null)
                      Text(
                        video.location!.address!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: AppConstants.paddingSmall,
                      children: [
                        _buildInfoChip(
                          Icons.volume_up,
                          '${video.noiseData.maxDecibel?.toStringAsFixed(1) ?? '0.0'}dB',
                          Colors.red,
                        ),
                        if (video.hasLicensePlate)
                          _buildInfoChip(
                            Icons.drive_eta,
                            '번호판',
                            Colors.blue,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              Column(
                children: [
                  _buildStatusIndicator(video.status),
                  const SizedBox(height: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (action) => _handleVideoAction(action, video),
                    itemBuilder: (BuildContext context) => [
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
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.description, size: 18),
                            SizedBox(width: 8),
                            Text('리포트 생성'),
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

  Widget _buildStatusIndicator(RecordingStatus status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case RecordingStatus.recording:
        color = Colors.red;
        icon = Icons.fiber_manual_record;
        break;
      case RecordingStatus.processing:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case RecordingStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case RecordingStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        break;
      case RecordingStatus.uploaded:
        color = Colors.blue;
        icon = Icons.cloud_done;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 14,
        color: color,
      ),
    );
  }

  void _handleVideoAction(String action, RecordingModel video) {
    switch (action) {
      case 'share':
        _shareVideo(video);
        break;
      case 'report':
        _generateReport(video);
        break;
      case 'delete':
        _deleteVideo(video);
        break;
    }
  }

  void _shareVideo(RecordingModel video) {
    // TODO: 비디오 공유 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('공유 기능이 준비 중입니다.')),
    );
  }

  void _generateReport(RecordingModel video) {
    Navigator.pushNamed(
      context,
      '/report',
      arguments: {
        'maxDecibel': video.noiseData.maxDecibel,
        'minDecibel': video.noiseData.minDecibel,
        'avgDecibel': video.noiseData.avgDecibel,
        'startTime': video.startTime,
        'endTime': video.endTime,
        'measurementCount': video.noiseData.measurementCount,
      },
    );
  }

  void _deleteVideo(RecordingModel video) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('비디오 삭제'),
          content: const Text('이 비디오를 삭제하시겠습니까?\n삭제된 비디오는 복구할 수 없습니다.'),
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
                _performDeleteVideo(video);
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

  Future<void> _performDeleteVideo(RecordingModel video) async {
    try {
      // 실제 DB에서 비디오 삭제
      // Direct use of EnhancedDatabaseHelper instead of service layer
      await EnhancedDatabaseHelper.instance.deleteSession(int.parse(video.id));
      
      setState(() {
        _videos.removeWhere((v) => v.id == video.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비디오가 삭제되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비디오 삭제 실패: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}