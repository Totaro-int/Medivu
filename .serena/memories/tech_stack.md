# ActFinder 기술 스택

## Flutter & Dart
- **Flutter**: 3.35.4 (stable channel)
- **Dart**: 3.9.2
- **SDK**: ^3.8.1

## 핵심 의존성

### UI & 상태 관리
- `provider: ^6.1.1` - 상태 관리
- `cupertino_icons: ^1.0.8` - iOS 스타일 아이콘
- `flutter_spinkit: ^5.2.0` - 로딩 애니메이션
- `cached_network_image: ^3.3.0` - 네트워크 이미지 캐싱

### 카메라 & 미디어
- `camera: ^0.11.2` - 카메라 기능
- `image_picker: ^1.0.4` - 이미지/비디오 선택
- `video_player: ^2.8.1` - 비디오 재생
- `flutter_webrtc: any` - 실시간 통신

### 소음 측정
- `noise_meter: ^5.1.0` - 데시벨 측정

### OCR & 텍스트 인식
- `google_mlkit_text_recognition: ^0.14.0` - Google ML Kit OCR
- `flutter_tesseract_ocr: ^0.4.25` - Tesseract OCR
- 한글 번호판 인식에 특화된 하이브리드 시스템

### 위치 서비스
- `geolocator: ^14.0.2` - GPS 위치 서비스
- `geocoding: ^4.0.0` - 주소 변환

### 네트워크
- `http: ^1.1.0` - HTTP 클라이언트
- `dio: ^5.4.0` - 고급 HTTP 클라이언트

### 로컬 저장소
- `shared_preferences: ^2.2.2` - 간단한 키-값 저장
- `path_provider: ^2.1.1` - 파일 경로 관리
- `sqflite: ^2.3.0` - SQLite 데이터베이스

### PDF & 파일 처리
- `pdf: ^3.10.7` - PDF 생성
- `printing: ^5.11.1` - PDF 인쇄
- `open_file: ^3.3.2` - 파일 열기
- `file_picker: ^10.2.0` - 파일 선택

### 차트 & 시각화
- `fl_chart: ^1.0.0` - 플러터 차트
- `syncfusion_flutter_charts: ^30.1.41` - Syncfusion 차트

### 권한 & 보안
- `permission_handler: ^12.0.1` - 권한 관리

### 유틸리티
- `intl: ^0.20.2` - 국제화
- `uuid: ^4.2.1` - UUID 생성
- `crypto: ^3.0.3` - 암호화
- `url_launcher: ^6.2.2` - URL 실행
- `device_info_plus: ^11.5.0` - 디바이스 정보
- `package_info_plus: ^8.3.0` - 패키지 정보

## 개발 도구
- `flutter_test` - 테스팅 프레임워크
- `flutter_lints: ^6.0.0` - Dart/Flutter 린트 규칙
- `mockito: ^5.4.4` - 목킹 라이브러리
- `build_runner: ^2.4.7` - 코드 생성