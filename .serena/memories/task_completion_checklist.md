# ActFinder 작업 완료 체크리스트

## 코드 변경 후 필수 검사 사항

### 1. 코드 품질 검사
```bash
# 린트 및 분석 (정보성 경고 제외)
flutter analyze --no-fatal-infos lib/

# 코드 포맷팅 검사
dart format --set-exit-if-changed lib/

# 특정 린트 규칙 확인 (필요시)
flutter analyze lib/ | grep -E "(unused_|dead_null_aware|prefer_final_fields)"
```

### 2. 컴파일 및 빌드 검증
```bash
# 디버그 빌드로 컴파일 에러 확인
flutter build apk --debug

# 핫 리로드 테스트
flutter run --debug
```

### 3. 테스트 실행
```bash
# 단위 테스트 실행
flutter test

# 특정 테스트 파일 실행 (필요시)
flutter test test/specific_test.dart
```

### 4. 기능별 특수 검증

#### OCR 관련 변경 시
- ML Kit OCR 서비스 동작 확인
- Tesseract OCR 데이터 파일 무결성 검사
- 한국 번호판 패턴 인식 테스트 (`/korean-ocr-test` 화면)
- OCR 성능 분석기 실행

#### 데이터베이스 변경 시
- 데이터베이스 스키마 마이그레이션 확인
- `DatabaseDebug.printDatabaseInfo()` 실행
- 기존 데이터 호환성 검증

#### 권한 관련 변경 시
- AndroidManifest.xml 권한 설정 확인
- 런타임 권한 요청 플로우 테스트
- iOS Info.plist 권한 설정 검증

#### UI/UX 변경 시
- Material 3 디자인 가이드라인 준수 확인
- 다양한 화면 크기에서 레이아웃 테스트
- 접근성 (accessibility) 검증

### 5. 성능 및 메모리 검사
```bash
# 성능 프로파일링 (필요시)
flutter run --profile

# 메모리 누수 검사 (대규모 변경 시)
flutter run --debug --verbose
```

### 6. 릴리즈 준비 (배포 전)
```bash
# 릴리즈 빌드 성공 확인
flutter build apk --release
flutter build appbundle --release

# 버전 번호 업데이트 확인
grep "version:" pubspec.yaml

# 개인정보 처리방침 링크 확인
# 권한 사용 설명 업데이트 확인
```

## 커밋 전 체크리스트

### 필수 사항
- [ ] `flutter analyze --no-fatal-infos lib/` 통과
- [ ] `flutter build apk --debug` 성공
- [ ] 관련 테스트 통과
- [ ] 코드 리뷰 완료

### 권장 사항
- [ ] 변경사항 문서화
- [ ] Breaking change 여부 확인
- [ ] 의존성 변경 시 README 업데이트
- [ ] 새로운 권한 추가 시 사용자 안내 추가

## 배포 전 최종 체크리스트

### Android Play Store
- [ ] `flutter build appbundle --release` 성공
- [ ] 버전 코드 증가 (pubspec.yaml)
- [ ] 개인정보 처리방침 URL 유효성
- [ ] 앱 권한 사용 근거 명시
- [ ] 스크린샷 및 앱 설명 업데이트

### 일반 배포
- [ ] 모든 린트 경고 해결
- [ ] 테스트 커버리지 확인
- [ ] 문서 업데이트
- [ ] 변경 로그 작성

## 문제 발생 시 롤백 절차

### 즉시 롤백이 필요한 경우
- 앱 크래시 발생
- 핵심 기능 (OCR, 소음 측정) 동작 불가
- 데이터 손실 위험
- 보안 취약점 발견

### 롤백 명령어
```bash
# Git을 통한 롤백
git revert <commit-hash>

# 이전 APK로 재배포
# 이전 버전의 앱 번들 사용
```