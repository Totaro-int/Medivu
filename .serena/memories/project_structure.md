# ActFinder 프로젝트 구조

## 루트 디렉터리
```
Medivu/
├── lib/                    # 메인 소스 코드
├── android/               # Android 플랫폼 코드
├── ios/                   # iOS 플랫폼 코드
├── assets/                # 에셋 파일 (이미지, 폰트, tessdata)
├── test/                  # 단위 테스트
├── pubspec.yaml          # 패키지 의존성
├── analysis_options.yaml # 코드 분석 설정
└── README.md             # 프로젝트 문서
```

## lib/ 디렉터리 구조

### 핵심 모듈
- `main.dart` - 앱 진입점 및 라우팅 설정
- `main_enhanced_auth.dart` - 향상된 인증 진입점

### 설정 (config/)
- `app_config.dart` - 앱 전역 설정
- `api_config.dart` - API 엔드포인트 설정

### 코어 (core/)
- `constants/` - 앱 상수 및 예외 정의
  - `app_exception.dart`
  - `ocr_exception.dart`
  - `network_exception.dart`
- `exceptions/app_constants.dart` - 앱 상수

### 모델 (models/)
- `user_model.dart` - 사용자 데이터 모델
- `recording_model.dart` - 녹화 데이터 모델
- `report_model.dart` - 리포트 데이터 모델
- `noise_data_model.dart` - 소음 데이터 모델
- `license_plate_model.dart` - 번호판 데이터 모델
- `location_model.dart` - 위치 데이터 모델
- `geometry_models.dart` - 지오메트리 모델

### 상태 관리 (providers/)
- `auth_provider.dart` - 기본 인증 상태 관리
- `enhanced_auth_provider.dart` - 향상된 인증 상태 관리

### 핵심 로직 (pipelines/)
- `plate_ocr_pipeline.dart` - 번호판 OCR 파이프라인 (ML Kit 기반)

### 서비스 (services/)
- `enhanced_auth_service.dart` - 인증 서비스
- `enhanced_database_helper.dart` - 데이터베이스 헬퍼
- `ml_kit_ocr_service.dart` - ML Kit OCR 서비스
- `license_plate_ocr_service.dart` - 번호판 OCR 서비스
- `plate_ocr_service.dart` - 플레이트 OCR 서비스
- `location_service.dart` - 위치 서비스
- `pdf_service.dart` - PDF 생성 서비스
- `permission_service.dart` - 권한 관리 서비스
- `share_service.dart` - 공유 서비스
- `upload_service.dart` - 업로드 서비스

### 화면 (screens/)
- `auth/` - 인증 관련 화면
  - `login_screen.dart`, `enhanced_login_screen.dart`
  - `enhanced_register_screen.dart`
  - `agreement_screen.dart`
  - `email_input_screen.dart`, `password_input_screen.dart`
- `home/` - 홈 화면
  - `main_home_screen.dart` - 메인 홈
  - `recording_screen.dart` - 녹화 화면
  - `history_screen.dart` - 히스토리
  - `video_list_screen.dart` - 비디오 목록
- `recording/` - 녹화 관련
  - `video_detail_screen.dart` - 비디오 상세
- `report/` - 리포트 화면
  - `report_screen.dart` - 리포트 생성
  - `new_report_screen.dart` - 새 리포트
  - `report_list_screen.dart` - 리포트 목록
- `complaint/` - 신고 화면
  - `noise_complaint_screen.dart` - 소음 신고
- `ocr/` - OCR 테스트
  - `ocr_test_screen.dart` - OCR 테스트
- `test/` - 테스트 화면
  - `korean_ocr_test_screen.dart` - 한글 OCR 테스트

### 유틸리티 (utils/)
- `postprocess.dart` - 후처리 유틸리티
- `korean_ocr_tester.dart` - 한글 OCR 테스터
- `korean_license_utils.dart` - 한국 번호판 유틸리티
- `ocr_performance_analyzer.dart` - OCR 성능 분석
- `database_debug.dart` - 데이터베이스 디버깅
- `permission_utils.dart` - 권한 유틸리티
- `file_utils.dart` - 파일 유틸리티
- `validators.dart` - 유효성 검사
- `navigation_helper.dart` - 네비게이션 헬퍼
- `date_utils.dart` - 날짜 유틸리티

### 위젯 (widgets/)
- `camera_preview_with_ocr_overlay.dart` - OCR 오버레이 카메라
- `noise_meter_widget.dart` - 소음 측정 위젯
- `noise_graph_widget.dart` - 소음 그래프 위젯
- `video_overlay_widget.dart` - 비디오 오버레이
- `camera_controls_widget.dart` - 카메라 컨트롤
- `recording_timer_widget.dart` - 녹화 타이머
- `primary_button.dart` - 기본 버튼
- `back_button.dart` - 뒤로가기 버튼
- `share_dialog.dart` - 공유 다이얼로그
- `actfinder_logo.dart` - 앱 로고

## 에셋 구조
```
assets/
├── logo.png              # 앱 로고
├── tessdata/             # Tesseract OCR 데이터
└── fonts/                # 한글 폰트 (NotoSansKR, RobotoMono)
```