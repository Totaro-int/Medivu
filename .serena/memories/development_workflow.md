# ActFinder 개발 워크플로우

## 개발 환경 설정
- Flutter 3.35.4 (stable channel)
- Dart 3.9.2
- Android Studio / VS Code + Flutter 플러그인

## 일반적인 개발 명령어

### 프로젝트 초기화
```bash
flutter clean              # 빌드 캐시 정리
flutter pub get            # 의존성 설치
```

### 개발 & 테스팅
```bash
flutter run                # 개발 모드 실행
flutter run --debug        # 디버그 모드 실행
flutter run --release      # 릴리즈 모드 실행
flutter test               # 단위 테스트 실행
```

### 코드 품질 검사
```bash
flutter analyze           # 코드 분석 (전체)
flutter analyze --no-fatal-infos lib/  # 정보성 경고 제외 분석
dart format lib/          # 코드 포맷팅
```

### 빌드
```bash
# Android
flutter build apk --debug      # 디버그 APK
flutter build apk --release    # 릴리즈 APK
flutter build appbundle        # Android App Bundle (Play Store용)

# iOS
flutter build ios             # iOS 빌드
```

## 코드 스타일 & 컨벤션

### Dart 코딩 규칙
- **린트**: `package:flutter_lints/flutter.yaml` 사용
- **네이밍**: camelCase (변수, 함수), PascalCase (클래스)
- **상수**: `const` 키워드 적극 활용
- **Null Safety**: 엄격한 null safety 적용

### 로깅
- `print` 대신 `debugPrint` 사용
- 프로덕션에서는 로깅 레벨 조정

### 위젯 구조
- `const` 생성자 사용
- `super.key` 매개변수 활용
- Material 3 디자인 가이드라인 준수

## 프로젝트별 특수 사항

### OCR 관련
- ML Kit과 Tesseract OCR 하이브리드 시스템
- 한국 번호판 패턴에 최적화
- `tessdata/` 디렉터리의 언어 데이터 파일 관리 필요

### 권한 관리
- 카메라, 마이크, 위치 권한 필수
- `permission_handler` 통한 런타임 권한 요청

### 데이터베이스
- SQLite 기반 로컬 저장
- `enhanced_database_helper.dart`를 통한 중앙화된 DB 관리

### 상태 관리
- Provider 패턴 사용
- `enhanced_auth_provider.dart`가 주요 상태 관리

## 테스트 전략
- 단위 테스트: `test/` 디렉터리
- 위젯 테스트: Flutter 테스트 프레임워크
- 모킹: `mockito` 라이브러리 활용

## 배포 준비
1. 버전 업데이트 (`pubspec.yaml`)
2. 코드 분석 & 린트 검사
3. 테스트 실행
4. 릴리즈 빌드 생성
5. Play Store / App Store 배포