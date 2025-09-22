// lib/utils/postprocess.dart
String postprocessKoreanPlate(String raw) {
  print('후처리 입력: $raw');
  
  // 한글은 그대로 두고 숫자/영문만 치환
  String s = raw.trim()
      .replaceAll('O','0').replaceAll('I','1').replaceAll('B','8').replaceAll('S','5')
      .replaceAll('o','0').replaceAll('i','1').replaceAll('b','8').replaceAll('s','5');
  
  // 한국 번호판 패턴들 (우선순위 순)
  final patterns = [
    // 1. 오토바이 번호판 (하단 핵심): 한글 1~2자리 + 공백? + 숫자 4자리
    RegExp(r'[가-힣]{1,2}\s?\d{4}'),
    
    // 2. 일반 자동차 번호판: 숫자 2-3자리 + 한글 1자리 + 숫자 4자리
    RegExp(r'\d{2,3}[가-힣]\d{4}'),
    
    // 3. 기타 변형 (공백 포함)
    RegExp(r'\d{2,3}\s?[가-힣]\s?\d{4}'),
  ];
  
  for (int i = 0; i < patterns.length; i++) {
    final matches = patterns[i].allMatches(s);
    for (final match in matches) {
      final result = match.group(0)!.trim();
      
      // 오토바이 번호판인지 확인 (한글로 시작)
      final isMotorcycle = RegExp(r'^[가-힣]').hasMatch(result);
      final plateType = isMotorcycle ? '오토바이' : '자동차';
      
      print('후처리 결과 ($plateType): $result');
      return result;
    }
  }
  
  print('패턴 매칭 실패, 원본 반환: $s');
  return s;
}
