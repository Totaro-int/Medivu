# ActFinder 아키텍처 개요

## 전체 아키텍처

### 계층 구조
```
┌─────────────────┐
│   Presentation  │ <- screens/, widgets/
├─────────────────┤
│   Business      │ <- providers/, pipelines/
├─────────────────┤
│   Service       │ <- services/
├─────────────────┤
│   Data          │ <- models/, database
└─────────────────┘
```

## 핵심 컴포넌트

### 1. 인증 시스템
- **Provider**: `EnhancedAuthProvider` - 상태 관리
- **Service**: `EnhancedAuthService` - 비즈니스 로직
- **Database**: SQLite를 통한 사용자 세션 관리
- **Flow**: 이메일 기반 로그인 → 세션 저장 → 자동 로그인

### 2. OCR 파이프라인
- **Pipeline**: `PlateOcrPipeline` - 전체 워크플로우 조정
- **Primary OCR**: `MLKitOcrService` - Google ML Kit 기반
- **Secondary OCR**: Tesseract OCR (한글 특화)
- **Flow**: 카메라 프레임 → ML Kit 인식 → 한국 번호판 패턴 검증 → 결과 반환

### 3. 소음 측정 시스템
- **Sensor**: `noise_meter` 패키지 활용
- **Storage**: SQLite에 측정 데이터 저장
- **Visualization**: `fl_chart`, `syncfusion_flutter_charts`
- **Flow**: 실시간 측정 → 데이터 저장 → 그래프 표시

### 4. 데이터 관리
- **Database**: `EnhancedDatabaseHelper` (SQLite)
- **Models**: 타입 안전한 데이터 모델
- **Storage**: 로컬 파일 시스템 + SharedPreferences

## 주요 디자인 패턴

### 1. Singleton Pattern
- `PlateOcrPipeline.instance`
- `MLKitOcrService.instance`
- `EnhancedDatabaseHelper.instance`
- `EnhancedAuthProvider.instance`

### 2. Provider Pattern (상태 관리)
- 중앙화된 상태 관리
- UI 자동 업데이트
- 의존성 주입

### 3. Pipeline Pattern (OCR)
- 단계별 처리: 입력 → 전처리 → 인식 → 후처리 → 출력
- 각 단계의 독립성 보장
- 에러 핸들링 중앙화

### 4. Service Layer Pattern
- 비즈니스 로직과 UI 분리
- 재사용 가능한 서비스 컴포넌트
- 테스트 용이성

## 데이터 플로우

### OCR 워크플로우
```
카메라 프레임 → PlateOcrPipeline → MLKitOcrService → 
한국 번호판 패턴 검증 → UI 표시 → 데이터 저장
```

### 소음 측정 워크플로우
```
마이크 센서 → noise_meter → 실시간 데이터 → 
그래프 업데이트 → SQLite 저장 → PDF 리포트
```

### 인증 워크플로우
```
사용자 입력 → EnhancedAuthProvider → EnhancedAuthService → 
SQLite 저장 → 세션 관리 → 자동 로그인
```

## 중요한 기술적 특징

### 1. 하이브리드 OCR 시스템
- **Primary**: Google ML Kit (실시간, 빠름)
- **Fallback**: Tesseract OCR (정확도 높음, 한글 특화)
- **Strategy**: ML Kit 우선 → 실패 시 Tesseract

### 2. 실시간 데이터 처리
- 카메라 프레임 스트리밍
- 실시간 소음 측정
- UI 자동 업데이트 (Provider)

### 3. 로컬 우선 아키텍처
- 네트워크 없이도 핵심 기능 동작
- SQLite 로컬 데이터베이스
- 오프라인 PDF 생성

### 4. 권한 관리
- 단계별 권한 요청
- 사용자 친화적 권한 설명
- 권한 거부 시 대안 제공

## 확장성 고려사항

### 수평 확장
- 새로운 OCR 엔진 추가 용이
- 다양한 측정 센서 통합 가능
- 추가 리포트 형식 지원

### 수직 확장
- 클라우드 연동 가능한 구조
- API 통신 준비된 네트워크 레이어
- 대용량 데이터 처리 가능한 DB 구조

### 플랫폼 확장
- Android/iOS 크로스 플랫폼
- 웹/데스크톱 확장 가능한 구조
- Native 모듈 통합 준비