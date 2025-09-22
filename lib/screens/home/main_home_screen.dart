import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/enhanced_auth_provider.dart';
import '../../widgets/actfinder_logo.dart';
import '../../services/permission_service.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  String? userEmail;
  final PermissionService _permissionService = PermissionService.instance;

  @override
  void initState() {
    super.initState();
    // AuthProvider 초기화 및 사용자 정보 가져오기
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // EnhancedAuthProvider는 이미 AuthWrapper에서 초기화되었으므로, 사용자 정보만 가져옴
    final authProvider = Provider.of<EnhancedAuthProvider>(context, listen: false);
    setState(() {
      userEmail = authProvider.userEmail;
    });
  }

  void _logout() async {
    final authProvider = Provider.of<EnhancedAuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _goToRecord() async {
    // 권한 체크 후 화면 이동
    final permissionResult = await _permissionService.checkAllPermissions();
    
    if (permissionResult.allGranted) {
      Navigator.pushNamed(context, '/record');
    } else {
      await _showPermissionRequiredDialog(permissionResult);
    }
  }

  /// 권한 필요 다이얼로그 표시
  Future<void> _showPermissionRequiredDialog(PermissionCheckResult result) async {
    if (!mounted) return;

    final title = result.permanentlyDeniedPermissions.isNotEmpty
        ? '⚠️ 권한 설정 필요'
        : '🔐 권한 허용 필요';

    final message = result.permanentlyDeniedPermissions.isNotEmpty
        ? '일부 권한이 영구적으로 거부되었습니다.\n앱 설정에서 직접 권한을 허용해주세요.'
        : '소음 측정 기능을 사용하려면 다음 권한들이 필요합니다:\n\n'
            '• 카메라: 동영상 촬영\n'
            '• 마이크: 소음 측정\n'
            '• 위치: 정확한 위치 기록\n'
            '• 저장소: 데이터 저장';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              if (result.permanentlyDeniedPermissions.isNotEmpty) {
                // 설정으로 이동
                await _permissionService.openSettings();
              } else {
                // 권한 재요청
                final newResult = await _permissionService.requestAllPermissions();
                if (newResult.allGranted) {
                  Navigator.pushNamed(context, '/record');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('모든 권한이 허용되어야 측정을 시작할 수 있습니다.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            child: Text(result.permanentlyDeniedPermissions.isNotEmpty ? '설정으로 이동' : '권한 허용'),
          ),
        ],
      ),
    );
  }

  void _goToVideoList() {
    Navigator.pushNamed(context, '/videoList');
  }

  void _goToReportList() {
    Navigator.pushNamed(context, '/reportList');
  }

  void _goToNoiseComplaint() {
    Navigator.pushNamed(context, '/complaint');
  }

  void _goToSettings() {
    // 설정 화면으로 이동 (향후 구현)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('설정 화면은 향후 추가될 예정입니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _goToOcrTest() async {
    // 카메라 권한 체크 후 OCR 테스트 화면으로 이동
    final permissionResult = await _permissionService.checkAllPermissions();
    
    if (permissionResult.allGranted) {
      Navigator.pushNamed(context, '/ocr-test');
    } else {
      await _showPermissionRequiredDialog(permissionResult);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userName = userEmail?.split('@')[0] ?? '사용자';
    final size = MediaQuery.of(context).size;
    
    // 반응형 크기 설정
    final screenWidth = size.width;
    final titleFontSize = screenWidth > 600 ? 28.0 : 24.0;
    final subtitleFontSize = screenWidth > 600 ? 18.0 : 16.0;
    final buttonFontSize = screenWidth > 600 ? 20.0 : 18.0;
    final sectionTitleFontSize = screenWidth > 600 ? 20.0 : 18.0;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ActFinderLogo(
                      width: 35,
                      height: 35,
                      color: Colors.white,
                      showText: false,
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _logout,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '로그아웃',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        
                        // 환영 메시지
                        Text(
                          '안녕하세요, $userName님!',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '소음 측정으로 더 나은 환경을 만들어보세요',
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            color: const Color(0xFF718096),
                            height: 1.4,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // 시작하기 버튼 (새로운 디자인)
                        Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667eea).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _goToRecord,
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.play_circle_fill,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '측정 시작하기',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // 메뉴 섹션
                        Text(
                          '기록 관리',
                          style: TextStyle(
                            fontSize: sectionTitleFontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // 메뉴 카드들
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // 화면 크기에 따른 동적 조정
                              final screenWidth = MediaQuery.of(context).size.width;
                              final crossAxisCount = screenWidth > 600 ? 3 : 2;
                              // 높이를 더 여유롭게 설정 (더 작은 값 = 더 큰 높이)
                              final aspectRatio = screenWidth > 600 ? 0.9 : 0.8;
                              
                              return GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  // 고정 높이 사용으로 오버플로우 방지
                                  mainAxisExtent: screenWidth > 600 ? 200 : 180,
                                ),
                                itemCount: 5, // 아이템 개수
                                itemBuilder: (context, index) {
                                  final items = [
                                    {
                                      'icon': Icons.videocam_outlined,
                                      'label': '동영상 목록',
                                      'description': '촬영한 영상 확인',
                                      'color': const Color(0xFF4299E1),
                                      'onTap': _goToVideoList,
                                    },
                                    {
                                      'icon': Icons.description_outlined,
                                      'label': '측정 리포트',
                                      'description': '소음 측정 결과',
                                      'color': const Color(0xFF48BB78),
                                      'onTap': _goToReportList,
                                    },
                                    {
                                      'icon': Icons.report_problem_outlined,
                                      'label': '소음 신고',
                                      'description': '측정 데이터로 신고',
                                      'color': const Color(0xFFE53E3E),
                                      'onTap': _goToNoiseComplaint,
                                    },
                                    {
                                      'icon': Icons.settings_outlined,
                                      'label': '앱 설정',
                                      'description': '권한 및 환경설정',
                                      'color': const Color(0xFF805AD5),
                                      'onTap': _goToSettings,
                                    },
                                    {
                                      'icon': Icons.camera_alt_outlined,
                                      'label': 'OCR 테스트',
                                      'description': '번호판 인식 테스트',
                                      'color': const Color(0xFF38B2AC),
                                      'onTap': _goToOcrTest,
                                    },
                                  ];
                                  
                                  final item = items[index];
                                  return _ModernMenuCard(
                                    icon: item['icon'] as IconData,
                                    label: item['label'] as String,
                                    description: item['description'] as String,
                                    color: item['color'] as Color,
                                    onTap: item['onTap'] as VoidCallback,
                                  );
                                },
                              );
                            },
                          ),
                        ),
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
}

class _ModernMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ModernMenuCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth > 600 ? 24.0 : 16.0;
    final iconSize = screenWidth > 600 ? 28.0 : 24.0;
    final titleFontSize = screenWidth > 600 ? 18.0 : 16.0;
    final descriptionFontSize = screenWidth > 600 ? 14.0 : 12.0;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: color.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 사용 가능한 공간이 너무 작으면 더 압축된 레이아웃 사용
              final isSmallSpace = constraints.maxHeight < 100 || constraints.maxWidth < 120;
              final adaptiveIconSize = isSmallSpace ? (iconSize * 0.7) : iconSize;
              final adaptiveIconPadding = isSmallSpace ? 4.0 : (screenWidth > 600 ? 10.0 : 8.0);
              final adaptiveSpacing = isSmallSpace ? 2.0 : (screenWidth > 600 ? 6.0 : 4.0);
              final adaptiveTitleSize = isSmallSpace ? (titleFontSize * 0.85) : titleFontSize;
              final adaptiveDescSize = isSmallSpace ? (descriptionFontSize * 0.85) : descriptionFontSize;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 아이콘 컨테이너
                  Container(
                    padding: EdgeInsets.all(adaptiveIconPadding),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(isSmallSpace ? 8 : 12),
                    ),
                    child: Icon(
                      icon,
                      size: adaptiveIconSize,
                      color: color,
                    ),
                  ),
                  SizedBox(height: adaptiveSpacing),
                  
                  // 제목 텍스트
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: adaptiveTitleSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // 여유 공간이 있을 때만 설명 텍스트 표시
                  if (constraints.maxHeight > 80) ...[
                    SizedBox(height: adaptiveSpacing * 0.5),
                    Flexible(
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: adaptiveDescSize,
                          color: const Color(0xFF718096),
                          height: 1.1,
                        ),
                        maxLines: isSmallSpace ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}