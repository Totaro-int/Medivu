import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Enhanced Auth System
import 'providers/enhanced_auth_provider.dart';
import 'screens/auth/enhanced_login_screen.dart';
import 'screens/home/main_home_screen.dart';
import 'services/enhanced_database_helper.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 데이터베이스 초기화
  await EnhancedDatabaseHelper.instance.database;
  
  // Enhanced 데이터베이스 초기화
  await EnhancedDatabaseHelper.instance.database;
  
  runApp(const EnhancedAuthApp());
}

class EnhancedAuthApp extends StatelessWidget {
  const EnhancedAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EnhancedAuthProvider.instance),
      ],
      child: MaterialApp(
        title: 'noise0 Enhanced Auth',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const EnhancedAuthWrapper(),
        routes: {
          '/login': (context) => const EnhancedLoginScreen(),
          '/main': (context) => const MainHomeScreen(),
        },
      ),
    );
  }
}

class EnhancedAuthWrapper extends StatefulWidget {
  const EnhancedAuthWrapper({super.key});

  @override
  State<EnhancedAuthWrapper> createState() => _EnhancedAuthWrapperState();
}

class _EnhancedAuthWrapperState extends State<EnhancedAuthWrapper> 
    with WidgetsBindingObserver {
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
      // Enhanced 데이터베이스 초기화 확인
      await EnhancedDatabaseHelper.instance.database;
      print('✅ Enhanced 데이터베이스 초기화 완료');
      
      // Enhanced AuthProvider 초기화 (세션 복원 포함)
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
          print('✅ Enhanced 자동 로그인 성공: ${authProvider.userEmail}');
        } else {
          print('ℹ️ Enhanced 로그인이 필요합니다');
        }
      }
    } catch (e) {
      print('❌ Enhanced 앱 초기화 에러: $e');
      
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
                'Enhanced noise0 초기화 중...',
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
                'Enhanced 시스템 초기화 중 오류가 발생했습니다',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? '알 수 없는 오류',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () async {
                      // 데이터베이스 재초기화
                      await EnhancedDatabaseHelper.instance.database;
                      setState(() {
                        _isInitialized = false;
                        _hasError = false;
                        _errorMessage = null;
                      });
                      _initializeApp();
                    },
                    child: const Text('DB 재초기화'),
                  ),
                ],
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
                action: SnackBarAction(
                  label: '닫기',
                  onPressed: () => authProvider.clearError(),
                ),
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