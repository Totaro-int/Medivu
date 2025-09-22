import 'package:flutter/material.dart';
import 'password_input_screen.dart';


class EmailInputScreen extends StatefulWidget {
  const EmailInputScreen({super.key});

  @override
  State<EmailInputScreen> createState() => _EmailInputScreenState();
}

class _EmailInputScreenState extends State<EmailInputScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      isButtonEnabled = RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(email);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _goToNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PasswordInputScreen(email: _emailController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
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
            const Text(
              '이메일을 입력해주세요.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'email@gmail.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
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
                onPressed: isButtonEnabled ? _goToNext : null,
                child: const Text('이메일 인증하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
