import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/enhanced_auth_provider.dart';
import '../../widgets/actfinder_logo.dart';

class EnhancedRegisterScreen extends StatefulWidget {
  const EnhancedRegisterScreen({super.key});

  @override
  State<EnhancedRegisterScreen> createState() => _EnhancedRegisterScreenState();
}

class _EnhancedRegisterScreenState extends State<EnhancedRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _agreeToPrivacy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms || !_agreeToPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이용약관과 개인정보처리방침에 동의해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<EnhancedAuthProvider>(context, listen: false);
    
    final result = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      displayName: _displayNameController.text.trim().isNotEmpty 
          ? _displayNameController.text.trim() 
          : null,
      phoneNumber: _phoneController.text.trim().isNotEmpty 
          ? _phoneController.text.trim() 
          : null,
    );

    if (mounted) {
      if (result['success']) {
        // 회원가입 성공
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '회원가입이 완료되었습니다.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // 로그인 화면으로 돌아가기 또는 자동 로그인으로 메인 화면으로 이동
        Navigator.of(context).pop();
      } else {
        // 회원가입 실패 - 에러 메시지 표시
        String errorMessage = result['message'] ?? '회원가입에 실패했습니다.';
        
        switch (result['code']) {
          case 'EMAIL_ALREADY_EXISTS':
            errorMessage = '이미 존재하는 이메일입니다. 다른 이메일을 사용해주세요.';
            break;
          case 'INVALID_PASSWORD':
            // 비밀번호 유효성 검사 메시지는 이미 상세하게 제공됨
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이용약관'),
        content: const SingleChildScrollView(
          child: Text(
            '이용약관 내용이 여기에 표시됩니다.\n\n'
            '1. 서비스 이용 약관\n'
            '2. 개인정보 수집 및 이용\n'
            '3. 제3자 정보 제공\n'
            '4. 서비스 제공 및 변경\n'
            '5. 서비스 이용 제한\n'
            '6. 저작권 및 지적재산권\n'
            '7. 손해배상 및 면책조항\n'
            '8. 분쟁해결 및 준거법\n'
            '9. 기타\n\n'
            '상세한 내용은 추후 업데이트될 예정입니다.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('개인정보처리방침'),
        content: const SingleChildScrollView(
          child: Text(
            '개인정보처리방침 내용이 여기에 표시됩니다.\n\n'
            '1. 개인정보의 수집 및 이용 목적\n'
            '2. 수집하는 개인정보의 항목\n'
            '3. 개인정보의 보유 및 이용 기간\n'
            '4. 개인정보의 제3자 제공\n'
            '5. 개인정보 처리의 위탁\n'
            '6. 정보주체의 권리 및 행사 방법\n'
            '7. 개인정보의 파기\n'
            '8. 개인정보 보호책임자\n'
            '9. 개인정보 처리방침의 변경\n\n'
            '상세한 내용은 추후 업데이트될 예정입니다.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    
                    // 로고와 타이틀
                    const ActFinderLogoVertical(
                      width: 80,
                      height: 80,
                      color: Colors.white,
                      textSize: 28,
                      spacing: 16,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '새로운 계정을 만들어보세요',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // 회원가입 카드
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 뒤로 가기 버튼과 제목
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
                                onPressed: () => Navigator.of(context).pop(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '회원가입',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ActFinder 계정을 만들어 시작하세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF718096),
                            ),
                          ),
                          const SizedBox(height: 32),
          
                          // 이메일 입력
                          _buildInputField(
                            controller: _emailController,
                            label: '이메일 *',
                            hintText: 'example@email.com',
                            keyboardType: TextInputType.emailAddress,
                            icon: Icons.email_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '이메일을 입력해주세요';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return '올바른 이메일 형식이 아닙니다';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // 표시 이름 입력
                          _buildInputField(
                            controller: _displayNameController,
                            label: '표시 이름',
                            hintText: '선택사항',
                            icon: Icons.person_outlined,
                            validator: (value) {
                              if (value != null && value.isNotEmpty && value.length < 2) {
                                return '표시 이름은 최소 2자 이상이어야 합니다';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // 전화번호 입력
                          _buildInputField(
                            controller: _phoneController,
                            label: '전화번호',
                            hintText: '010-0000-0000 (선택사항)',
                            keyboardType: TextInputType.phone,
                            icon: Icons.phone_outlined,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (!RegExp(r'^010-\d{4}-\d{4}$').hasMatch(value)) {
                                  return '올바른 전화번호 형식이 아닙니다 (010-0000-0000)';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
          
                          // 비밀번호 입력
                          _buildInputField(
                            controller: _passwordController,
                            label: '비밀번호 *',
                            hintText: '8자 이상, 대소문자, 숫자 포함',
                            obscureText: _obscurePassword,
                            icon: Icons.lock_outlined,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: const Color(0xFF9CA3AF),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '비밀번호를 입력해주세요';
                              }
                              if (value.length < 8) {
                                return '비밀번호는 최소 8자 이상이어야 합니다';
                              }
                              if (!value.contains(RegExp(r'[A-Z]'))) {
                                return '비밀번호에 대문자가 포함되어야 합니다';
                              }
                              if (!value.contains(RegExp(r'[a-z]'))) {
                                return '비밀번호에 소문자가 포함되어야 합니다';
                              }
                              if (!value.contains(RegExp(r'[0-9]'))) {
                                return '비밀번호에 숫자가 포함되어야 합니다';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // 비밀번호 확인 입력
                          _buildInputField(
                            controller: _confirmPasswordController,
                            label: '비밀번호 확인 *',
                            hintText: '비밀번호를 다시 입력하세요',
                            obscureText: _obscureConfirmPassword,
                            icon: Icons.lock_outlined,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: const Color(0xFF9CA3AF),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '비밀번호 확인을 입력해주세요';
                              }
                              if (value != _passwordController.text) {
                                return '비밀번호가 일치하지 않습니다';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
          
                          // 약관 동의
                          Column(
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _agreeToTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreeToTerms = value ?? false;
                                      });
                                    },
                                    activeColor: const Color(0xFF667eea),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Text(
                                          '이용약관에 동의합니다 ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF2D3748),
                                          ),
                                        ),
                                        const Text('*', style: TextStyle(color: Colors.red)),
                                        TextButton(
                                          onPressed: _showTermsDialog,
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: const Text(
                                            '(보기)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF667eea),
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _agreeToPrivacy,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreeToPrivacy = value ?? false;
                                      });
                                    },
                                    activeColor: const Color(0xFF667eea),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Text(
                                          '개인정보처리방침에 동의합니다 ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF2D3748),
                                          ),
                                        ),
                                        const Text('*', style: TextStyle(color: Colors.red)),
                                        TextButton(
                                          onPressed: _showPrivacyDialog,
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: const Text(
                                            '(보기)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF667eea),
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // 회원가입 버튼
                          Consumer<EnhancedAuthProvider>(
                            builder: (context, authProvider, child) {
                              return Container(
                                width: double.infinity,
                                height: 56,
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
                                    onTap: authProvider.isLoading ? null : _handleRegister,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Center(
                                      child: authProvider.isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              '회원가입',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // 로그인 페이지로 이동
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '이미 계정이 있으신가요? ',
                                style: TextStyle(
                                  color: Color(0xFF718096),
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  '로그인',
                                  style: TextStyle(
                                    color: Color(0xFF667eea),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // 하단 링크
                    const Text(
                      'ActFinder • totaro.co.kr',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2D3748),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFFA0AEC0),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF9CA3AF),
                size: 20,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}