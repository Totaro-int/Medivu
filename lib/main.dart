import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 인증 관련 화면
import 'screens/auth/enhanced_login_screen.dart';
import 'screens/auth/agreement_screen.dart';
import 'screens/auth/email_input_screen.dart';
//홈 기능 화면
import 'screens/home/recording_screen.dart' show RecordingScreen; // ✅ 녹화 + 데시벨 측정 화면
import 'screens/recording/video_detail_screen.dart';
import 'screens/home/main_home_screen.dart'; // 메인 홈 화면 import
import 'screens/home/history_screen.dart';
import 'screens/home/video_list_screen.dart'; // 비디오 목록 화면 import
import 'screens/report/report_screen.dart'; // 리포트 화면 import
import 'screens/report/report_list_screen.dart'; // 리포트 목록 화면 import
import 'screens/complaint/noise_complaint_screen.dart'; // 소음 신고 화면 import
import 'screens/ocr/ocr_test_screen.dart'; // OCR 테스트 화면 import
import 'screens/test/korean_ocr_test_screen.dart'; // 한글 OCR 테스트 화면 import
// 데이터베이스 관련
import 'services/enhanced_database_helper.dart';
import 'utils/database_debug.dart';
// Provider 관련
import 'providers/enhanced_auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 데이터베이스 초기화
  await EnhancedDatabaseHelper.instance.database;
  
  // 디버그 모드에서 데이터베이스 정보 출력
  await DatabaseDebug.printDatabaseInfo();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EnhancedAuthProvider.instance),
      ],
      child: MaterialApp(
        title: 'ActFinder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),

      // 정적 라우트 정의
      routes: {
        '/login': (context) => const EnhancedLoginScreen(),
        '/agreement': (context) => const AgreementScreen(),
        '/email': (context) => const EmailInputScreen(),
        '/main': (context) => const MainHomeScreen(), // ✅ 메인 홈 라우트 추가
        '/record': (context) => const RecordingScreen(), // ✅ 녹화 화면
        // '/report' 제거 - 동적 라우트에서 처리
        '/history': (context) => const HistoryScreen(), // ✅ 히스토리 화면
        '/videoList': (context) => const VideoListScreen(), // ✅ 비디오 목록 화면
        '/reportList': (context) => const ReportListScreen(), // ✅ 리포트 목록 화면
        '/complaint': (context) => const NoiseComplaintScreen(), // ✅ 소음 신고 화면
        '/ocr-test': (context) => const OcrTestScreen(), // ✅ OCR 테스트 화면
        '/korean-ocr-test': (context) => const KoreanOCRTestScreen(), // ✅ 한글 OCR 테스트 화면
      },

      //동적 라우트 (예: 상세 페이지 등)
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/videoDetail':
              final args = settings.arguments;
              if (args is String) {
                return MaterialPageRoute(
                  builder: (context) => VideoDetailScreen(videoId: args),
                );
              } else {
                return MaterialPageRoute(
                  builder: (context) => const Scaffold(
                    body: Center(child: Text('비디오 ID가 필요합니다.')),
                  ),
                );
              }

            case '/report':
              final args = settings.arguments;
              print('🚀 /report 라우트 호출됨');
              print('  - arguments: $args');
              print('  - arguments 타입: ${args.runtimeType}');
              
              if (args is Map<String, dynamic>) {
                print('  - Map 형태 arguments로 리포트 화면 생성');
                return MaterialPageRoute(
                  builder: (context) => ReportScreen(
                    maxDecibel: args['maxDecibel'],
                    minDecibel: args['minDecibel'],
                    avgDecibel: args['avgDecibel'],
                    startTime: args['startTime'],
                    endTime: args['endTime'],
                    measurementCount: args['measurementCount'],
                  ),
                  settings: settings, // settings 전달
                );
              } else {
                print('  - 기본 arguments로 리포트 화면 생성');
                return MaterialPageRoute(
                  builder: (context) => const ReportScreen(),
                  settings: settings, // settings 전달
                );
              }



            default:
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(child: Text('존재하지 않는 경로입니다.')),
                ),
              );
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 앱이 포그라운드로 돌아올 때 활동 시간 업데이트
    if (state == AppLifecycleState.resumed) {
      final authProvider = Provider.of<EnhancedAuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn) {
        authProvider.updateActivity();
      }
    }
  }

  Future<void> _initializeApp() async {
    try {
      // 데이터베이스 초기화 확인
      await EnhancedDatabaseHelper.instance.database;
      debugPrint('데이터베이스 초기화 완료');
      
      // EnhancedAuthProvider 초기화 (세션 복원 포함)
      if (mounted) {
        final authProvider = Provider.of<EnhancedAuthProvider>(context, listen: false);
        await authProvider.initialize();
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _hasError = false;
            _errorMessage = null;
          });
        }
        
        // 초기화 성공 로그
        if (authProvider.isLoggedIn) {
          debugPrint('자동 로그인 성공: ${authProvider.userEmail}');
        } else {
          debugPrint('로그인이 필요합니다');
        }
      }
    } catch (e) {
      debugPrint('앱 초기화 에러: $e');
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'ActFinder 초기화 중...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '잠시만 기다려주세요',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                '초기화 중 오류가 발생했습니다',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? '알 수 없는 오류',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitialized = false;
                    _hasError = false;
                    _errorMessage = null;
                  });
                  _initializeApp();
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<EnhancedAuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    '로그인 처리 중...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        }
        
        if (authProvider.error != null) {
          // 에러가 있지만 여전히 로그인 화면으로 이동
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.error!),
                backgroundColor: Colors.red,
              ),
            );
          });
        }
        
        if (authProvider.isLoggedIn) {
          return const MainHomeScreen();
        } else {
          return const EnhancedLoginScreen();
        }
      },
    );
  }
}

