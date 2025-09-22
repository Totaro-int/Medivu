class Validators {
  /// 이메일 형식 검증
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요.';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return '올바른 이메일 형식을 입력해주세요.';
    }
    
    return null;
  }
  
  /// 비밀번호 형식 검증
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    
    if (value.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }
    
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return '비밀번호는 영문 대소문자와 숫자를 포함해야 합니다.';
    }
    
    return null;
  }
  
  /// 비밀번호 확인 검증
  static String? validatePasswordConfirm(String? value, String password) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요.';
    }
    
    if (value != password) {
      return '비밀번호가 일치하지 않습니다.';
    }
    
    return null;
  }
  
  /// 이름 검증
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return '이름을 입력해주세요.';
    }
    
    if (value.length < 2) {
      return '이름은 2자 이상이어야 합니다.';
    }
    
    return null;
  }
  
  /// 전화번호 검증
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return '전화번호를 입력해주세요.';
    }
    
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    if (!phoneRegex.hasMatch(value.replaceAll('-', ''))) {
      return '올바른 전화번호 형식을 입력해주세요.';
    }
    
    return null;
  }
  
  /// 필수 입력 검증
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName을(를) 입력해주세요.';
    }
    
    return null;
  }
  
  /// 최소 길이 검증
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.length < minLength) {
      return '$fieldName은(는) $minLength자 이상이어야 합니다.';
    }
    
    return null;
  }
  
  /// 최대 길이 검증
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName은(는) $maxLength자 이하여야 합니다.';
    }
    
    return null;
  }
}
