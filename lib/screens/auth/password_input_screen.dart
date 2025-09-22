import 'package:flutter/material.dart';

class PasswordInputScreen extends StatefulWidget {
  final String email;
  
  const PasswordInputScreen({super.key, required this.email});

  @override
  State<PasswordInputScreen> createState() => _PasswordInputScreenState();
}

class _PasswordInputScreenState extends State<PasswordInputScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool isButtonEnabled = false;
  bool isPasswordValid = false;
  bool isPasswordMatch = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validate);
    _confirmController.addListener(_validate);
  }

  void _validate() {
    final password = _passwordController.text;
    final confirmPassword = _confirmController.text;
    
    setState(() {
      isPasswordValid = password.length >= 8;
      isPasswordMatch = password.isNotEmpty && password == confirmPassword;
      isButtonEnabled = isPasswordValid && isPasswordMatch;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showCompletePopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('회원가입 완료'),
        content: const Text('회원가입이 완료되었습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/main',
                (route) => false,
              );
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _completeSignup() {
    _showCompletePopup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 설정'),
        backgroundColor: const Color(0xFF6C7BFF),
        foregroundColor: Colors.white,
        leading: BackButton(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.email}의 비밀번호를 설정해주세요.',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: '비밀번호 (8자 이상)',
                border: const OutlineInputBorder(),
                suffixIcon: isPasswordValid 
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              decoration: InputDecoration(
                hintText: '비밀번호 확인',
                border: const OutlineInputBorder(),
                suffixIcon: isPasswordMatch && _confirmController.text.isNotEmpty
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            if (_confirmController.text.isNotEmpty && !isPasswordMatch)
              const Text(
                '비밀번호가 일치하지 않습니다.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isButtonEnabled
                      ? const Color(0xFF6C7BFF)
                      : Colors.grey.shade300,
                  foregroundColor: isButtonEnabled ? Colors.white : Colors.grey,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: isButtonEnabled ? _completeSignup : null,
                child: const Text('회원가입 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}