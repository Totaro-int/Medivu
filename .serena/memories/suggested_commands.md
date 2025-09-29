# ActFinder 추천 명령어 모음

## 필수 일상 명령어

### 프로젝트 시작 시
```bash
# 의존성 정리 및 설치
flutter clean && flutter pub get

# 코드 분석 (정보성 경고 제외)
flutter analyze --no-fatal-infos lib/

# 개발 모드 실행
flutter run
```

### 코드 품질 검사
```bash
# 전체 코드 분석
flutter analyze

# 특정 경고 필터링 (예시)
flutter analyze --no-fatal-infos lib/ | grep -E "(unused_|dead_null_aware|prefer_final_fields)" | head -50

# 코드 포맷팅
dart format lib/

# 린트 경고 수 카운트
flutter analyze --no-fatal-infos lib/ | wc -l
```

### 빌드 & 테스트
```bash
# 디버그 빌드
flutter build apk --debug

# 릴리즈 APK
flutter build apk --release

# Play Store용 App Bundle
flutter build appbundle --release

# 테스트 실행
flutter test
```

### OCR 관련 디버깅
```bash
# OCR 성능 테스트용 화면 접근
# /korean-ocr-test 라우트 사용
# /ocr-test 라우트 사용
```

### 데이터베이스 디버깅
```bash
# 디버그 모드에서 데이터베이스 정보 자동 출력
# DatabaseDebug.printDatabaseInfo() 호출됨
```

## 플랫폼별 명령어

### Android
```bash
# Android 디바이스 확인
flutter devices

# Android 에뮬레이터 실행
flutter emulators --launch <emulator_id>

# Android 스튜디오에서 열기
open android/
```

### iOS (macOS 전용)
```bash
# iOS 시뮬레이터 실행
open -a Simulator

# Xcode에서 열기
open ios/Runner.xcworkspace
```

## 문제 해결 명령어

### 의존성 문제
```bash
# 완전 초기화
flutter clean
rm -rf .dart_tool/
flutter pub get
```

### 빌드 문제
```bash
# 안드로이드 빌드 캐시 정리
cd android && ./gradlew clean && cd ..

# Flutter 캐시 정리
flutter clean
flutter pub cache repair
```

### OCR 관련 문제
```bash
# Tesseract 데이터 확인
ls -la assets/tessdata/

# ML Kit 관련 권한 확인
# AndroidManifest.xml에서 카메라 권한 확인
```

## 개발 효율성 명령어

### 코드 생성
```bash
# 빌드 러너 실행 (코드 생성)
flutter packages pub run build_runner build

# 빌드 러너 감시 모드
flutter packages pub run build_runner watch
```

### 성능 분석
```bash
# 성능 프로파일링
flutter run --profile

# 메모리 사용량 확인
flutter run --debug --verbose
```

## 배포 관련 명령어

### 버전 관리
```bash
# pubspec.yaml 버전 확인
grep "version:" pubspec.yaml

# Git 태그 생성
git tag v1.0.0
git push origin v1.0.0
```

### 릴리즈 준비
```bash
# 릴리즈 체크리스트
flutter analyze --no-fatal-infos lib/
flutter test
flutter build apk --release
flutter build appbundle --release
```

## MacOS 특화 명령어
```bash
# Flutter 설치 확인
which flutter

# PATH 확인
echo $PATH | grep flutter

# macOS 개발 도구 확인
xcode-select --print-path
```