import 'package:http/http.dart' as http;
import 'dart:convert';

class PlateOcrService {
  static Future<String?> requestOcr(String videoFileName) async {
    final uri = Uri.parse('http://<SERVER_IP>:<PORT>/recognize');

    try {
      final response = await http.post(
        uri,
        body: jsonEncode({'file_name': videoFileName}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['plate_number'] as String?;
      } else {
        print('번호판 인식 요청 실패: ${response.body}');
        return null;
      }
    } catch (e) {
      print('번호판 요청 중 오류: $e');
      return null;
    }
  }
}
