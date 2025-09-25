# 🚀 Google Play Store 배포 체크리스트

## ✅ 완료된 작업

### 1. 패키지명 변경
- ✅ `com.example.medivu_app` → `com.medivu.actfinder`
- ✅ Android `build.gradle.kts` 업데이트
- ✅ `AndroidManifest.xml` 업데이트
- ✅ `MainActivity.kt` 패키지 및 디렉토리 구조 변경
- ✅ Linux `CMakeLists.txt` 업데이트

### 2. 앱 서명 설정
- ✅ `android/key.properties` 파일 생성
- ✅ 릴리즈 빌드 서명 설정 추가
- ✅ ProGuard 규칙 파일 생성
- ⚠️ **키스토어 파일 생성 필요** (Java/keytool 설치 후)

### 3. 앱 이름 및 브랜딩
- ✅ `pubspec.yaml`: `medivu_app` → `actfinder`
- ✅ 앱 설명 개선
- ✅ Android 앱 라벨: `ActFinder`
- ✅ 커스텀 로고 확인 (`assets/logo.png`)

### 4. 데이터베이스 구조 확인
- ✅ 엔터프라이즈급 DB 설계 확인
- ✅ 보안 기능 (비밀번호 해싱, 세션 관리) 완비
- ✅ 상용 서비스 준비 완료

## 🔄 다음 단계 (남은 작업)

### 필수 작업
1. **키스토어 생성**
   ```bash
   # Java 설치 후 실행
   keytool -genkey -v -keystore android/app/upload-keystore.jks \
   -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **key.properties 파일 업데이트**
   - 실제 비밀번호로 교체 필요

3. **앱 아이콘 교체**
   - `assets/logo.png`를 각 밀도별 아이콘으로 변환
   - 필요한 크기: 48dp, 72dp, 96dp, 144dp, 192dp

### 스토어 준비 작업
4. **개인정보처리방침 작성**
5. **스크린샷 제작** (최소 8장)
6. **앱 설명 및 키워드 최적화**
7. **Google Play Console 계정 설정**

### 테스트 작업
8. **릴리즈 빌드 테스트**
   ```bash
   flutter build apk --release
   flutter build appbundle --release
   ```

9. **기능 테스트**
   - 소음 측정 기능
   - 번호판 인식 기능
   - 권한 요청 플로우
   - 데이터 저장/불러오기

## 🎯 예상 소요 시간
- **키스토어 생성**: 30분
- **아이콘 제작**: 2-3시간
- **문서 작성**: 4-6시간
- **테스트**: 2-3시간
- **스토어 설정**: 1-2시간

**총 예상**: 1-2일

## 🚨 주의사항
- `android/key.properties` 파일은 절대 Git에 커밋하지 말 것
- 키스토어 파일은 안전한 곳에 백업 보관
- 실제 키스토어 비밀번호는 복잡하게 설정
- 개인정보처리방침은 법무검토 권장