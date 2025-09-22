class AppConstants {
  // App Info
  static const String appName = 'ActFinder';
  static const String appVersion = '1.0.0';
  
  // Colors
  static const int primaryColor = 0xFF6750A4; // Deep Purple
  static const int secondaryColor = 0xFF625B71;
  static const int backgroundColor = 0xFFFFFBFE;
  static const int surfaceColor = 0xFFFFFBFE;
  static const int errorColor = 0xFFBA1A1A;
  
  // Text Styles
  static const double titleFontSize = 24.0;
  static const double bodyFontSize = 16.0;
  static const double captionFontSize = 12.0;
  
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Border Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  
  // Animation Duration
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // API Endpoints (로컬 저장 전용 - 서버 사용 안함)
  static const String baseUrl = 'LOCAL_STORAGE_ONLY';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String reportsEndpoint = '/reports';
  static const String videosEndpoint = '/videos';
}
