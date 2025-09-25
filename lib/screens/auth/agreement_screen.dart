import 'package:flutter/material.dart';
import 'package:actfinder/screens/auth/email_input_screen.dart';

class AgreementScreen extends StatefulWidget {
  const AgreementScreen({super.key});

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  bool allChecked = false;
  bool term1 = false;
  bool term2 = false;
  bool term3 = false;

  void toggleAll(bool value) {
    setState(() {
      allChecked = value;
      term1 = value;
      term2 = value;
      term3 = value;
    });
  }

  bool get canProceed => term1 && term2;

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
          children: [
            Row(
              children: const [
                Icon(Icons.account_circle, color: Color(0xFF1A2F5D)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ACTFINDER 서비스 이용약관에 동의해주세요.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              value: allChecked,
              onChanged: (v) => toggleAll(v!),
              title: const Text('모두 동의 (선택 정보 포함)'),
            ),
            const Divider(),
            CheckboxListTile(
              value: term1,
              onChanged: (v) {
                setState(() {
                  term1 = v!;
                  allChecked = term1 && term2 && term3;
                });
              },
              title: const Text('[필수] 이용약관 동의'),
            ),
            CheckboxListTile(
              value: term2,
              onChanged: (v) {
                setState(() {
                  term2 = v!;
                  allChecked = term1 && term2 && term3;
                });
              },
              title: const Text('[필수] 개인정보 처리방침 동의'),
            ),
            CheckboxListTile(
              value: term3,
              onChanged: (v) {
                setState(() {
                  term3 = v!;
                  allChecked = term1 && term2 && term3;
                });
              },
              title: const Text('[선택] 푸시 알림 동의'),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canProceed ? const Color(0xFF1A2F5D) : Colors.grey,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: canProceed
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmailInputScreen()),
                );
              }
                  : null,
              child: const Text('동의하고 가입하기'),
            ),
          ],
        ),
      ),
    );
  }
}
