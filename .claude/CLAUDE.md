좋아! Claude Code가 네 로컬 프로젝트(ActFinder/Medivu)를 정확히 이해하고 안전하게 수정·빌드·릴리즈까지 도와줄 수 있도록, 바로 붙여넣어 쓸 수 있는 CLAUDE.md 지침서를 만들어줬어. 이 파일을 리포지토리 루트에 저장하면 돼.

⸻

CLAUDE.md

0) 프로젝트 요약
   •	앱명: ActFinder (Medivu)
   •	목적: 소음 측정 + 번호판 인식으로 생활 소음 신고 지원
   •	주요 스택: Flutter 3.x, Provider, ML Kit OCR, Tesseract OCR, SQLite, PDF
   •	핵심 흐름: 측정 → 번호판 인식 → 리포트 PDF → 신고

⸻

1) 디렉터리 구조(요점)

lib/
config/                   # 전역/엔드포인트 설정
core/constants/           # 예외/상수
models/                   # 데이터 모델 (recording/report/user 등)
pipelines/                # plate_ocr_pipeline.dart (ML Kit 사용)
providers/                # auth_provider, enhanced_auth_provider
screens/                  # auth/home/recording/report/complaint/ocr/test
services/                 # DB/MLKit/OCR/Noise/PDF
utils/                    # 후처리/테스트/디버깅
widgets/                  # 공용 위젯 (카메라+OCR 오버레이 등)
assets/
tessdata/                 # Tesseract 데이터
android/                    # Android 빌드/서명 관련 파일

⚠️ TFLite는 제거됨: detector.dart, recognizer.dart, tracker.dart, assets/models/ 삭제 완료. OCR은 Google ML Kit + Tesseract 기반.

⸻

2) Claude가 할 수 있는 대표 작업 (플레이북)

A. 코드 탐색 & 요약

# 루트 확인
Bash(ls -la)

# 다트 파일 수/경로 확인
Bash(find lib -type f -name "*.dart" | wc -l)
Bash(find lib -type f -name "*.dart" | head -20)

# 중요 파일 열람
Read(pubspec.yaml)
Read(lib/pipelines/plate_ocr_pipeline.dart)
Read(lib/services/ml_kit_ocr_service.dart)
Read(lib/widgets/camera_preview_with_ocr_overlay.dart)

B. 린트/품질 점검

# 전체 분석 (정보성 경고 허용)
Bash(flutter analyze --no-fatal-infos lib/)

# 특정 규칙만 필터링
Bash(flutter analyze --no-fatal-infos lib/ | grep -E "(unused_|dead_null_aware|prefer_final_fields)" | head -50)

C. 빌드/실행

# 디펜던시 정리
Bash(flutter clean && flutter pub get)

# 디버그 APK 빌드
Bash(flutter build apk --debug)

# 릴리즈 번들(.aab) 빌드
Bash(flutter build appbundle --release)

D. 문서/정책 업데이트

# 개인정보 처리방침 열람/수정
Read(PRIVACY_POLICY.md)
Update(PRIVACY_POLICY.md)  # 꼭 변경점만 명확히 기술 (예: 연락처/시행일)

E. 리포트 생성

# 남은 경고 수 리포트
Bash(flutter analyze --no-fatal-infos lib/ | wc -l)

# 빌드 로그 요약 요청
# (Claude가 마지막 Bash 출력 요약해주도록 요청)


⸻

3) 코드 수정 가이드 (안전 가드레일)

반드시 지켜줘
•	삭제 금지: keystore, 서명/배포 설정, android/key.properties (있다면)
•	개인정보 URL 수정 시: PRIVACY_POLICY.md와 앱 내 링크를 함께 일치시킬 것
•	권한 관련 코드(카메라/마이크/위치)는 Manifest와 실제 사용처가 일치해야 함 (불필요 권한 제거 요청 OK)
•	Flutter 위젯 수정 시 빌드 실패 유발 API 변경(시그니처)은 전체 참조 파일을 찾아 함께 수정

수정할 때의 원칙
•	변경 전/후 diff 요약을 코멘트로 남김
•	컴파일 에러/린트 경고가 나면 해결 방안 제시 + 수정
•	성능/사용성 영향(예: 카메라 프레임 처리 주기) 변경 시 숫자 근거 명시

⸻

4) 스타일 규칙 (Dart/Flutter)
   •	로그: print 대신 debugPrint
   •	위젯 생성자: const/super.key 사용
   •	널 처리: 불필요한 ?? 0 제거 (실제 Null 가능성만 체크)
   •	필드: 재할당 없는 컬렉션은 final
   •	파일 임포트: 미사용 import 즉시 제거
   •	비동기: await 누락/무시 금지, 예외는 try/catch 후 사용자 피드백/로그

⸻

5) Android(Play Store) 준비 체크리스트

5.1 버전 & 채널
•	pubspec.yaml → version: X.Y.Z+build (릴리즈마다 증가)
•	내부 테스트 → 클로즈드 테스트 → 프로덕션 단계

5.2 권한 정합성
•	AndroidManifest.xml: camera/microphone/location
•	실제 사용 코드와 일치하도록 점검, 필요 없으면 삭제

5.3 개인정보 처리방침
•	PRIVACY_POLICY.md 최신화(최종 개정일/시행일)
•	외부 URL(GitHub Pages/Notion/Vercel 등) 준비 → 앱/콘솔에 동일 링크 사용
•	앱 내 경로: 설정 > 개인정보 처리방침 연결 확인

5.4 그래픽 자산
•	아이콘 512×512 PNG
•	Feature Graphic 1024×500 PNG
•	스크린샷 5–8장 (소음 측정, 녹화, 번호판 인식, PDF 생성 등)

5.5 서명 & 빌드

# (미생성 시) keystore 생성 — 로컬 보관/백업(절대 커밋 금지)
keytool -genkey -v -keystore ~/actfinder-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias actfinder

# key.properties 설정 후 .gitignore 등록
# 릴리즈 번들 생성
flutter build appbundle --release

5.6 콘솔 제출
•	콘텐츠 등급 설문 (마이크/카메라/위치 사용 사유 명확히)
•	개인정보 처리방침 URL 입력
•	테스트 트랙 배포 → 크래시/ANR 확인 후 프로덕션 공개

⸻

6) ML/OCR 관련 주의
   •	현재 OCR 경로는 ML Kit + Tesseract만 사용
   •	TFLite 관련 파일/의존성은 추가 금지 (재도입 시 사전 합의 필요)
   •	ml_kit_ocr_service.dart와 plate_ocr_pipeline.dart는 동시에 수정
   •	카메라 오버레이(camera_preview_with_ocr_overlay.dart) 변경 시, 좌표/회전 보정 로직 함께 점검

⸻

7) 자주 하는 요청 템플릿

A. “남은 경고 줄여줘”

Bash(flutter analyze --no-fatal-infos lib/)
# → 상위 50개 유형 요약해줘, 각각 자동 수정 가능 여부/위험도/예시 작업계획 제시

B. “빌드가 실패해”

Bash(flutter clean && flutter pub get)
Bash(flutter build apk --debug)
# → 에러 로그의 최초 발생 지점/원인 후보/수정 PR 패치 초안 제시

C. “개인정보 처리방침 업데이트”

Read(PRIVACY_POLICY.md)
# → 최종 개정일/시행일/연락처/제공항목 변경 사항 반영해 수정 패치 제시

D. “Play 스토어 준비 상태 점검”

# 1) 권한 일치 검사: Manifest vs 실제 코드 사용 비교
Read(android/app/src/main/AndroidManifest.xml)
# 2) 개인정보 링크/문구 일치 검사
Read(PRIVACY_POLICY.md)
# 3) 버전/빌드 넘버 확인
Read(pubspec.yaml)
# → 누락/불일치 목록 + 수정 커밋 메시지 초안


⸻

8) 커밋/PR 규칙
   •	Commit: type(scope): summary (예: fix(ocr): handle null bounding box)
   •	PR 설명: 변경 의도, 영향 범위(화면/서비스), 테스트 방법, 롤백 방법
   •	빌드패스 보장: PR 전 flutter analyze/디버그 빌드 통과 필수

⸻

9) 금지/주의 목록
   •	keystore/비밀키/토큰을 파일/로그/PR에 노출 금지
   •	개인정보 처리방침의 법적 문구를 임의 단순화/삭제 금지 (변경 시 원문 보존 & 변경 내역 기록)
   •	권한 추가는 사용 근거 제시 + UI/문서 반영 동시 진행

⸻

10) 빠른 점검 명령 모음

# 0. 의존성/캐시 정리
Bash(flutter clean && flutter pub get)

# 1. 린트/경고 수 파악
Bash(flutter analyze --no-fatal-infos lib/ | wc -l)

# 2. 디버그 빌드
Bash(flutter build apk --debug)

# 3. 릴리즈 번들
Bash(flutter build appbundle --release)


⸻

11) 연락/소유권 정보 (문서 싱크)
    •	개인정보 보호책임자: 박상준
    •	연락: privacy@medivu.com
    •	PRIVACY_POLICY.md의 최종 개정일/시행일과 콘솔/앱 내 표기를 일치시킬 것
    •	현재 문서 하단 문구: “본 개인정보처리방침은 2025년 9월 23일부터 적용됩니다.”

⸻

마지막 메모
•	Claude가 파일을 수정해야 한다면, 변경 지점/코드/사유를 명확히 서술하고 최소 범위로 패치합니다.
•	위험 변경(권한/보안/배포 키/개인정보)은 항상 사전 확인 요청 문구를 포함하세요.

⸻

이걸 루트에 **CLAUDE.md**로 저장하면 끝!
원하면 내가 지금 내용에 프로젝트 맞춤 커맨드(예: 테스트 기기별 빌드 타스크, 아이콘/그래픽 경로)나 스크립트까지 더해준 버전으로 다듬어줄게.