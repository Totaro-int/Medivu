import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image/image.dart' as img;
import '../models/license_plate_model.dart';

/// 번호판 후보 영역 정보
class PlateRegion {
  final Rect boundingBox;
  final double confidence;
  final String text;
  final int regionId;

  PlateRegion({
    required this.boundingBox,
    required this.confidence,
    required this.text,
    required this.regionId,
  });
}

/// LicensePlateModel 확장 (copyWith 기능)
extension LicensePlateModelExtension on LicensePlateModel {
  LicensePlateModel copyWith({
    String? id,
    String? plateNumber,
    String? imagePath,
    DateTime? recognizedAt,
    double? confidence,
    String? rawText,
    String? ocrProvider,
    bool? isValidFormat,
  }) {
    return LicensePlateModel(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      imagePath: imagePath ?? this.imagePath,
      recognizedAt: recognizedAt ?? this.recognizedAt,
      confidence: confidence ?? this.confidence,
      rawText: rawText ?? this.rawText,
      ocrProvider: ocrProvider ?? this.ocrProvider,
      isValidFormat: isValidFormat ?? this.isValidFormat,
    );
  }
}

class LicensePlateOCRService {
  static LicensePlateOCRService? _instance;
  static LicensePlateOCRService get instance {
    _instance ??= LicensePlateOCRService._internal();
    return _instance!;
  }
  
  LicensePlateOCRService._internal();
  
  late final TextRecognizer _textRecognizer;
  bool _tesseractInitialized = false;
  
  /// OCR 서비스 초기화 (다중 엔진)
  Future<void> initialize() async {
    try {
      // 1. Google ML Kit 초기화 (기본 텍스트 인식기 사용)
      _textRecognizer = TextRecognizer();
      print('✅ Google ML Kit (범용) 초기화 완료');
      
      // 2. Tesseract OCR 초기화 (백그라운드)
      _initializeTesseract();
      
    } catch (e) {
      print('❌ ML Kit 초기화 실패: $e');
      // 초기화 실패 시 기본 TextRecognizer 사용
      _textRecognizer = TextRecognizer();
      print('🔄 기본 텍스트 인식기로 폴백');
    }
  }

  /// Tesseract OCR 초기화 (비동기)
  Future<void> _initializeTesseract() async {
    try {
      print('🔧 Tesseract OCR 초기화 시작...');
      
      // Tesseract는 실제 사용 시에만 초기화하도록 변경 (더미 테스트 제거)
      _tesseractInitialized = true;
      print('✅ Tesseract OCR 준비 완료 (실제 사용 시 초기화)');
    } catch (e) {
      print('⚠️ Tesseract OCR 준비 실패: $e');
      _tesseractInitialized = false;
    }
  }
  
  /// 이미지에서 번호판 텍스트 인식 (다중 엔진 앙상블 + 컨텍스트 인식)
  Future<LicensePlateModel?> recognizeLicensePlate(String imagePath) async {
    try {
      print('🔍 컨텍스트 인식 번호판 검출 시작: $imagePath');
      
      // 이미지 파일 유효성 검사
      final file = File(imagePath);
      if (!await file.exists()) {
        print('❌ 이미지 파일이 존재하지 않음: $imagePath');
        return null;
      }
      
      final fileSize = await file.length();
      print('📷 이미지 파일 크기: ${(fileSize / 1024).toStringAsFixed(1)}KB');
      
      final results = <LicensePlateModel>[];
      
      // 1단계: 번호판 후보 영역 검출
      final plateRegions = await _detectPlateRegions(imagePath);
      print('📍 검출된 번호판 후보 영역: ${plateRegions.length}개');
      
      // 2단계: 각 영역에 대해 다중 엔진 OCR 수행
      if (plateRegions.isNotEmpty) {
        for (int i = 0; i < plateRegions.length; i++) {
          final region = plateRegions[i];
          print('🎯 영역 $i 분석 중 (신뢰도: ${region.confidence.toStringAsFixed(3)})...');
          
          // 영역 기반 OCR 수행
          final regionResults = await _performRegionBasedOCR(imagePath, region, i);
          results.addAll(regionResults);
        }
      }
      
      // 3단계: 전체 이미지 OCR (후보 영역이 없거나 결과가 부족한 경우)
      if (results.isEmpty || results.every((r) => (r.confidence ?? 0) < 0.7)) {
        print('🔄 전체 이미지 OCR 수행...');
        
        // 전략 1: Google ML Kit (원본)
        var mlkitResult = await _recognizeWithMLKit(imagePath, '전체원본');
        if (mlkitResult != null) {
          results.add(mlkitResult);
          print('✅ ML Kit 전체 결과: ${mlkitResult.plateNumber} (${mlkitResult.confidence?.toStringAsFixed(3)})');
        }
        
        // 전략 2: Tesseract OCR (가능한 경우)
        if (_tesseractInitialized) {
          var tesseractResult = await _recognizeWithTesseract(imagePath, '전체원본');
          if (tesseractResult != null) {
            results.add(tesseractResult);
            print('✅ Tesseract 전체 결과: ${tesseractResult.plateNumber} (${tesseractResult.confidence?.toStringAsFixed(3)})');
          }
        }
      }
      
      // 4단계: 결과가 없으면 다단계 전처리 후 재시도
      if (results.isEmpty) {
        print('🔄 원본 인식 실패, 다단계 전처리 후 재시도...');
        
        // 4-1: 기본 전처리 (밝기/대비 조정)
        final basicEnhancedPath = await _preprocessImageBasic(imagePath);
        if (basicEnhancedPath != imagePath) {
          var mlkitResult = await _recognizeWithMLKit(basicEnhancedPath, '기본전처리');
          if (mlkitResult != null) results.add(mlkitResult);
          
          if (_tesseractInitialized) {
            var tesseractResult = await _recognizeWithTesseract(basicEnhancedPath, '기본전처리');
            if (tesseractResult != null) results.add(tesseractResult);
          }
          
          // 임시 파일 삭제
          _cleanupTempFile(basicEnhancedPath);
        }
        
        // 4-2: 고급 전처리 (전체 파이프라인)
        if (results.isEmpty) {
          final enhancedPath = await _preprocessImage(imagePath);
          if (enhancedPath != imagePath) {
            var mlkitResult = await _recognizeWithMLKit(enhancedPath, '고급전처리');
            if (mlkitResult != null) results.add(mlkitResult);
            
            if (_tesseractInitialized) {
              var tesseractResult = await _recognizeWithTesseract(enhancedPath, '고급전처리');
              if (tesseractResult != null) results.add(tesseractResult);
            }
            
            // 임시 파일 삭제
            _cleanupTempFile(enhancedPath);
          }
        }
        
        // 4-3: 최후 수단 - 크기 조정 및 샤프닝
        if (results.isEmpty) {
          final scaledPath = await _preprocessImageScaled(imagePath);
          if (scaledPath != imagePath) {
            var mlkitResult = await _recognizeWithMLKit(scaledPath, '크기조정');
            if (mlkitResult != null) results.add(mlkitResult);
            
            // 임시 파일 삭제
            _cleanupTempFile(scaledPath);
          }
        }
      }
      
      // 5단계: 컨텍스트 인식 앙상블 결과 선택
      return _selectContextAwareBestResult(results);
      
    } catch (e) {
      print('❌ 번호판 인식 전체 실패: $e');
      return null;
    }
  }

  /// ML Kit으로 인식
  Future<LicensePlateModel?> _recognizeWithMLKit(String imagePath, String strategy) async {
    try {
      print('📱 ML Kit ($strategy) 인식 시도...');
      
      // 파일 존재 확인
      final file = File(imagePath);
      if (!await file.exists()) {
        print('❌ ML Kit: 파일이 존재하지 않음: $imagePath');
        return null;
      }
      
      final inputImage = InputImage.fromFilePath(imagePath);
      print('📷 InputImage 생성 완료: ${inputImage.metadata?.size}');
      
      final recognizedText = await _textRecognizer.processImage(inputImage);
      print('📝 ML Kit 인식 완료. 전체 텍스트: "${recognizedText.text}"');
      print('📝 블록 수: ${recognizedText.blocks.length}');
      
      if (recognizedText.text.isEmpty) {
        print('❌ ML Kit: 인식된 텍스트가 없음');
        return null;
      }
      
      final plateNumber = _extractLicensePlateNumber(recognizedText);
      if (plateNumber == null) return null;
      
      return LicensePlateModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        plateNumber: plateNumber,
        imagePath: imagePath,
        recognizedAt: DateTime.now(),
        confidence: _calculateAdvancedConfidence(recognizedText, plateNumber),
        rawText: recognizedText.text,
        ocrProvider: 'google_mlkit_$strategy',
        isValidFormat: true,
      );
    } catch (e) {
      print('❌ ML Kit ($strategy) 실패: $e');
      return null;
    }
  }

  /// Tesseract OCR으로 인식
  Future<LicensePlateModel?> _recognizeWithTesseract(String imagePath, String strategy) async {
    try {
      print('🔧 Tesseract ($strategy) 인식 시도...');
      
      // 파일 존재 확인
      final file = File(imagePath);
      if (!await file.exists()) {
        print('❌ Tesseract: 파일이 존재하지 않음: $imagePath');
        return null;
      }
      
      final extractedText = await FlutterTesseractOcr.extractText(
        imagePath,
        language: 'eng', // 한국어 언어팩이 없을 수 있으므로 영어만 사용
        args: {
          "preserve_interword_spaces": "1",
          "psm": "8", // 단일 단어 인식
          "oem": "3", // 최신 LSTM 엔진
          "-c": "tessedit_char_whitelist=0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", // 기본 문자만
        }
      ).timeout(const Duration(seconds: 15)); // 타임아웃 연장
      
      if (extractedText.isEmpty) {
        print('🔧 Tesseract: 빈 텍스트 결과');
        return null;
      }
      
      print('🔧 Tesseract 추출 텍스트: "$extractedText"');
      
      // 간단한 RecognizedText 객체 모방 (실제로는 더 복잡한 파싱 필요)
      final plateNumber = _extractPlateFromTesseractText(extractedText);
      if (plateNumber == null) return null;
      
      return LicensePlateModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        plateNumber: plateNumber,
        imagePath: imagePath,
        recognizedAt: DateTime.now(),
        confidence: _calculateTesseractConfidence(extractedText, plateNumber),
        rawText: extractedText,
        ocrProvider: 'tesseract_$strategy',
        isValidFormat: true,
      );
    } catch (e) {
      print('❌ Tesseract ($strategy) 실패: $e');
      // Tesseract 실패 시 비활성화
      _tesseractInitialized = false;
      return null;
    }
  }

  /// Tesseract 텍스트에서 번호판 추출
  String? _extractPlateFromTesseractText(String text) {
    final cleanText = text.trim().replaceAll(RegExp(r'\s+'), '');
    
    // Tesseract (영어 전용)에서는 주로 숫자와 영문자만 인식되므로 간단한 패턴 사용
    final patterns = [
      RegExp(r'\d{2,3}[A-Z]{1,2}\d{4}'), // 자동차: 123가4567 → 123A4567
      RegExp(r'[A-Z]{1,2}\d{4}'), // 간단한 형태: 가1234 → A1234
      RegExp(r'\d{3,4}'), // 숫자만: 1234
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        final plateNumber = match.group(0)!;
        // 영문자를 한글로 매핑하여 반환 (간단한 매핑)
        final koreanPlate = _mapEnglishToKorean(plateNumber);
        if (koreanPlate != null && koreanPlate.length >= 4) {
          return koreanPlate;
        }
      }
    }
    
    // 패턴 매칭 실패 시 원본 텍스트에서 숫자만 추출
    final numbers = cleanText.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length >= 4) {
      return '가${numbers.substring(0, 4)}'; // 기본 형태로 반환
    }
    
    return null;
  }
  
  /// 영문자를 한글로 매핑 (간단한 매핑)
  String? _mapEnglishToKorean(String englishPlate) {
    final mapping = {
      'A': '가', 'B': '나', 'C': '다', 'D': '라', 'E': '마',
      'F': '바', 'G': '사', 'H': '아', 'I': '자', 'J': '차',
      'K': '카', 'L': '타', 'M': '파', 'N': '하', 'O': '거',
      'P': '너', 'Q': '더', 'R': '러', 'S': '머', 'T': '버',
      'U': '서', 'V': '어', 'W': '저', 'X': '처', 'Y': '커', 'Z': '터'
    };
    
    String result = englishPlate;
    for (final entry in mapping.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    
    // 숫자가 포함되어 있는지 확인
    if (result.contains(RegExp(r'\d'))) {
      return result;
    }
    
    return null;
  }

  /// Tesseract 신뢰도 계산
  double _calculateTesseractConfidence(String rawText, String plateNumber) {
    double confidence = 0.6; // Tesseract 기본 점수
    
    // 텍스트 품질
    if (rawText.length >= 5 && rawText.length <= 15) {
      confidence += 0.1;
    }
    
    // 한국 번호판 패턴 매칭
    if (_isValidKoreanLicensePlate(plateNumber)) {
      confidence += 0.2;
    }
    
    // 불필요한 문자 감점
    final cleanRatio = plateNumber.length / rawText.length;
    confidence += cleanRatio * 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }

  /// 번호판 후보 영역 검출 (컨텍스트 인식)
  Future<List<PlateRegion>> _detectPlateRegions(String imagePath) async {
    try {
      print('🎯 번호판 후보 영역 검출 시작...');
      final regions = <PlateRegion>[];
      
      // ML Kit을 사용해 먼저 텍스트 블록 검출
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // 각 텍스트 블록을 번호판 후보로 평가
      for (int i = 0; i < recognizedText.blocks.length; i++) {
        final block = recognizedText.blocks[i];
        final regionConfidence = _evaluateRegionAsCandidatePlate(block);
        
        if (regionConfidence > 0.3) { // 임계값 이상만 후보로 선정
          final region = PlateRegion(
            boundingBox: block.boundingBox,
            confidence: regionConfidence,
            text: block.text,
            regionId: i,
          );
          regions.add(region);
          print('  📍 후보 영역 $i: "${block.text.replaceAll('\n', ' ')}" (${regionConfidence.toStringAsFixed(3)})');
        }
      }
      
      // 신뢰도 순으로 정렬
      regions.sort((a, b) => b.confidence.compareTo(a.confidence));
      
      // 상위 3개 영역만 선택 (성능 최적화)
      final topRegions = regions.take(3).toList();
      print('✅ 선정된 상위 후보 영역: ${topRegions.length}개');
      
      return topRegions;
    } catch (e) {
      print('❌ 번호판 후보 영역 검출 실패: $e');
      return [];
    }
  }

  /// 텍스트 블록을 번호판 후보로 평가
  double _evaluateRegionAsCandidatePlate(TextBlock block) {
    double score = 0.0;
    final text = block.text.replaceAll(RegExp(r'\s+'), '');
    
    // 1. 텍스트 길이 평가 (번호판 길이 범위)
    if (text.length >= 5 && text.length <= 15) {
      score += 0.2;
    }
    
    // 2. 숫자 포함 여부
    final digitCount = text.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (digitCount >= 2) {
      score += 0.2;
      if (digitCount == 4) score += 0.1; // 4자리 숫자는 전형적
    }
    
    // 3. 한글 포함 여부
    final koreanCount = text.replaceAll(RegExp(r'[^가-힣]'), '').length;
    if (koreanCount >= 1) {
      score += 0.2;
      if (koreanCount >= 2) score += 0.1;
    }
    
    // 4. 번호판 패턴 매칭
    final patterns = [
      RegExp(r'[가-힣]{2,4}[가-힣]\d{4}'), // 오토바이
      RegExp(r'\d{2,3}[가-힣]\d{4}'), // 자동차
      RegExp(r'[가-힣]\d{4}'), // 간단한 형태
    ];
    
    for (final pattern in patterns) {
      if (pattern.hasMatch(text)) {
        score += 0.3;
        break;
      }
    }
    
    // 5. 기하학적 특성 (번호판 비율)
    final bbox = block.boundingBox;
    final width = bbox.right - bbox.left;
    final height = bbox.bottom - bbox.top;
    
    if (height > 0) {
      final aspectRatio = width / height;
      if (aspectRatio >= 2.0 && aspectRatio <= 6.0) {
        score += 0.2; // 번호판은 가로가 길다
      }
    }
    
    // 6. 라인 수 (번호판은 보통 1-2줄)
    final lineCount = block.lines.length;
    if (lineCount <= 2) {
      score += 0.1;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// 영역 기반 OCR 수행
  Future<List<LicensePlateModel>> _performRegionBasedOCR(String imagePath, PlateRegion region, int regionIndex) async {
    final results = <LicensePlateModel>[];
    
    try {
      // 영역을 크롭하여 별도 이미지로 추출
      final croppedPath = await _cropRegion(imagePath, region, regionIndex);
      
      if (croppedPath != null) {
        // ML Kit으로 크롭된 영역 인식
        final mlkitResult = await _recognizeWithMLKit(croppedPath, '영역$regionIndex');
        if (mlkitResult != null) {
          results.add(mlkitResult.copyWith(
            confidence: (mlkitResult.confidence ?? 0) * region.confidence, // 영역 신뢰도 적용
          ));
        }
        
        // Tesseract로 크롭된 영역 인식
        if (_tesseractInitialized) {
          final tesseractResult = await _recognizeWithTesseract(croppedPath, '영역$regionIndex');
          if (tesseractResult != null) {
            results.add(tesseractResult.copyWith(
              confidence: (tesseractResult.confidence ?? 0) * region.confidence,
            ));
          }
        }
        
        // 임시 크롭 파일 삭제
        try {
          final tempFile = File(croppedPath);
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (e) {
          print('⚠️ 임시 크롭 파일 삭제 실패: $e');
        }
      }
    } catch (e) {
      print('❌ 영역 기반 OCR 실패 (영역 $regionIndex): $e');
    }
    
    return results;
  }

  /// 영역 크롭
  Future<String?> _cropRegion(String imagePath, PlateRegion region, int regionIndex) async {
    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) return null;
      
      // 경계 박스 좌표 (여백 추가)
      final bbox = region.boundingBox;
      final margin = 5; // 5픽셀 여백
      final x = (bbox.left - margin).clamp(0, originalImage.width - 1).toInt();
      final y = (bbox.top - margin).clamp(0, originalImage.height - 1).toInt();
      final w = (bbox.right - bbox.left + 2 * margin).clamp(1, originalImage.width - x).toInt();
      final h = (bbox.bottom - bbox.top + 2 * margin).clamp(1, originalImage.height - y).toInt();
      
      // 이미지 크롭
      final croppedImage = img.copyCrop(originalImage, x: x, y: y, width: w, height: h);
      
      // 임시 파일로 저장
      final tempDir = Directory.systemTemp;
      final croppedPath = '${tempDir.path}/plate_region_${regionIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage, quality: 95));
      
      print('  📸 영역 $regionIndex 크롭 완료: $croppedPath');
      return croppedPath;
    } catch (e) {
      print('❌ 영역 크롭 실패 (영역 $regionIndex): $e');
      return null;
    }
  }

  /// 컨텍스트 인식 최적 결과 선택 (기존 앙상블 + 컨텍스트)
  LicensePlateModel? _selectContextAwareBestResult(List<LicensePlateModel> results) {
    if (results.isEmpty) return null;
    
    print('🧠 컨텍스트 인식 결과 선택: ${results.length}개 후보');
    
    // 1. 신뢰도 순으로 정렬
    results.sort((a, b) => (b.confidence ?? 0).compareTo(a.confidence ?? 0));
    
    // 2. 동일한 번호판이 여러 엔진/영역에서 인식되었는지 확인
    final plateGroups = <String, List<LicensePlateModel>>{};
    for (final result in results) {
      final cleanPlate = result.plateNumber?.replaceAll(' ', '') ?? '';
      if (cleanPlate.isNotEmpty) {
        plateGroups[cleanPlate] ??= [];
        plateGroups[cleanPlate]!.add(result);
      }
    }
    
    // 3. 복수 소스에서 인식된 결과 우선 (더 높은 가중치)
    for (final entry in plateGroups.entries) {
      if (entry.value.length > 1) {
        final bestInGroup = entry.value.first;
        final avgConfidence = entry.value
            .map((r) => r.confidence ?? 0)
            .reduce((a, b) => a + b) / entry.value.length;
        
        // 다중 소스 합의 시 더 높은 부스트 적용
        final finalConfidence = (avgConfidence * 1.3).clamp(0.0, 1.0); // 30% 부스트
        
        print('🏆 다중 소스 합의: ${entry.key} (평균: ${avgConfidence.toStringAsFixed(3)} → 부스트: ${finalConfidence.toStringAsFixed(3)})');
        
        return bestInGroup.copyWith(
          confidence: finalConfidence,
          ocrProvider: entry.value.map((r) => r.ocrProvider).join('+'),
        );
      }
    }
    
    // 4. 단일 결과 중 최고 신뢰도
    final best = results.first;
    print('🥇 최고 신뢰도 결과: ${best.plateNumber} (${best.confidence?.toStringAsFixed(3)}) [${best.ocrProvider}]');
    
    return best;
  }

  /// 최적의 결과 선택 (앙상블) - 레거시 호환성
  LicensePlateModel? _selectBestResult(List<LicensePlateModel> results) {
    return _selectContextAwareBestResult(results);
  }

  
  /// 실시간 카메라 이미지에서 번호판 인식
  Future<String?> recognizeFromBytes(List<int> imageBytes) async {
    try {
      // 임시 파일로 저장
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_plate_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(imageBytes);
      
      final result = await recognizeLicensePlate(tempFile.path);
      
      // 임시 파일 삭제
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      return result?.plateNumber;
    } catch (e) {
      print('❌ 바이트 이미지 번호판 인식 실패: $e');
      return null;
    }
  }
  
  /// 한국 번호판 패턴 추출 (자동차 + 오토바이) - 개선된 버전
  String? _extractLicensePlateNumber(RecognizedText recognizedText) {
    print('🔍 번호판 패턴 추출 시작...');
    
    // 한국 번호판 패턴들 (더 유연하고 현실적인 OCR 결과를 고려)
    final patterns = [
      // === 숫자가 포함된 패턴 우선 ===
      // 자동차 번호판: 12가3456, 123가4567
      RegExp(r'\d{2,3}[가-힣A-Za-z]\d{4}'),
      
      // 간단한 형태: 가1234 (OCR에서 가장 잘 인식됨)
      RegExp(r'[가-힣A-Za-z]\d{4}'),
      
      // 구형 번호판: 서울12가3456
      RegExp(r'[가-힣]{2}\d{2}[가-힣A-Za-z]\d{4}'),
      
      // 오토바이 부분 패턴: 영등포가1234
      RegExp(r'[가-힣]{2,4}[가-힣A-Za-z]\d{4}'),
      
      // 공백이 있는 패턴들
      RegExp(r'\d{2,3}\s*[가-힣A-Za-z]\s*\d{4}'),
      RegExp(r'[가-힣A-Za-z]\s*\d{4}'),
      
      // === 매우 유연한 패턴 (OCR 오류 대응) ===
      // 숫자만 있는 경우 (4자리 이상)
      RegExp(r'\d{4,8}'),
      
      // 한글+숫자 조합 (순서 상관없음)
      RegExp(r'[가-힣A-Za-z]+\d+'),
      RegExp(r'\d+[가-힣A-Za-z]+'),
      
      // 영문자도 한글로 인식되는 경우 고려
      RegExp(r'[A-Z]{1,2}\d{4}'),
      RegExp(r'\d{2,3}[A-Z]\d{4}'),
    ];
    
    // 인식된 모든 텍스트 로깅
    print('📝 인식된 블록 수: ${recognizedText.blocks.length}');
    for (int i = 0; i < recognizedText.blocks.length; i++) {
      final block = recognizedText.blocks[i];
      print('📝 블록 $i: "${block.text}"');
      for (int j = 0; j < block.lines.length; j++) {
        final line = block.lines[j];
        print('  └─ 라인 $j: "${line.text}"');
      }
    }
    
    // 모든 텍스트를 다양한 방식으로 결합하여 시도 (개선된 버전)
    final textVariations = <String>[];
    
    // 1. 원본 텍스트들
    textVariations.add(recognizedText.text);
    textVariations.add(recognizedText.text.replaceAll(' ', ''));
    textVariations.add(recognizedText.text.replaceAll('\n', ' '));
    textVariations.add(recognizedText.text.replaceAll(RegExp(r'\s+'), ''));
    
    // 2. 블록별 조합
    if (recognizedText.blocks.isNotEmpty) {
      textVariations.add(recognizedText.blocks.map((block) => block.text).join(''));
      textVariations.add(recognizedText.blocks.map((block) => block.text).join(' '));
      
      // 각 블록을 개별적으로도 시도
      for (final block in recognizedText.blocks) {
        textVariations.add(block.text);
        textVariations.add(block.text.replaceAll(RegExp(r'\s+'), ''));
        
        // 블록 내 라인별로도 시도
        for (final line in block.lines) {
          textVariations.add(line.text);
          textVariations.add(line.text.replaceAll(RegExp(r'\s+'), ''));
          
          // 라인 내 엘리먼트별로도 시도
          for (final element in line.elements) {
            textVariations.add(element.text);
          }
        }
      }
    }
    
    // 3. 중복 제거
    final uniqueVariations = textVariations.toSet().toList();
    uniqueVariations.removeWhere((text) => text.isEmpty);
    
    print('🔍 텍스트 변형들 (${uniqueVariations.length}개):');
    for (int i = 0; i < uniqueVariations.length && i < 10; i++) { // 처음 10개만 로깅
      print('  $i: "${uniqueVariations[i]}"');
    }
    
    // 각 텍스트 변형에 대해 패턴 매칭 시도
    for (final text in uniqueVariations) {
      if (text.isEmpty) continue;
      
      for (int i = 0; i < patterns.length; i++) {
        final pattern = patterns[i];
        final matches = pattern.allMatches(text);
        
        for (final match in matches) {
          final plateNumber = match.group(0)!;
          print('🎯 패턴 $i 매칭: "$plateNumber"');
          
          // 영문자를 한글로 변환 시도
          final convertedPlateNumber = _convertEnglishToKorean(plateNumber);
          
          if (_isValidKoreanLicensePlate(plateNumber)) {
            print('✅ 유효한 번호판 발견 (원본): $plateNumber');
            return plateNumber;
          } else if (convertedPlateNumber != plateNumber && _isValidKoreanLicensePlate(convertedPlateNumber)) {
            print('✅ 유효한 번호판 발견 (변환): $convertedPlateNumber');
            return convertedPlateNumber;
          }
        }
      }
    }
    
    // 개별 라인에서도 시도
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final lineVariations = [
          line.text,
          line.text.replaceAll(' ', ''),
          line.text.replaceAll(RegExp(r'\s+'), ''),
        ];
        
        for (final lineText in lineVariations) {
          if (lineText.isEmpty) continue;
          
          for (final pattern in patterns) {
            final matches = pattern.allMatches(lineText);
            for (final match in matches) {
              final plateNumber = match.group(0)!;
              if (_isValidKoreanLicensePlate(plateNumber)) {
                print('✅ 라인에서 유효한 번호판 발견: $plateNumber');
                return plateNumber;
              }
            }
          }
        }
      }
    }
    
    print('❌ 번호판 패턴을 찾을 수 없음');
    
    // 최후의 수단: 숫자가 4자리 이상 있으면 기본 번호판으로 처리
    for (final text in uniqueVariations) {
      final numbers = text.replaceAll(RegExp(r'[^0-9]'), '');
      if (numbers.length >= 4) {
        final basicPlate = '가${numbers.substring(0, 4)}';
        print('🔄 기본 번호판 생성: $basicPlate');
        return basicPlate;
      }
    }
    
    return null;
  }
  
  /// 영문자를 한글로 변환 (OCR 오인식 보정)
  String _convertEnglishToKorean(String text) {
    final mapping = {
      // 자주 혼동되는 영문자-한글 매핑
      'A': '가', 'B': '나', 'C': '다', 'D': '라', 'E': '마', 'F': '바', 'G': '사',
      'H': '아', 'I': '자', 'J': '차', 'K': '카', 'L': '타', 'M': '파', 'N': '하',
      'O': '거', 'P': '너', 'Q': '더', 'R': '러', 'S': '머', 'T': '버', 'U': '서',
      'V': '어', 'W': '저', 'X': '처', 'Y': '커', 'Z': '터',
      
      // 소문자도 포함
      'a': '가', 'b': '나', 'c': '다', 'd': '라', 'e': '마', 'f': '바', 'g': '사',
      'h': '아', 'i': '자', 'j': '차', 'k': '카', 'l': '타', 'm': '파', 'n': '하',
      'o': '거', 'p': '너', 'q': '더', 'r': '러', 's': '머', 't': '버', 'u': '서',
      'v': '어', 'w': '저', 'x': '처', 'y': '커', 'z': '터',
      
      // 숫자 오인식 (예: 0을 o로, 1을 l로)
      'O': '0', 'o': '0', 'I': '1', 'l': '1', 'S': '5', 's': '5',
    };
    
    String result = text;
    for (final entry in mapping.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    
    return result;
  }
  
  /// 한국 번호판 유효성 검증 (자동차 + 오토바이) - 개선된 버전
  bool _isValidKoreanLicensePlate(String plateNumber) {
    // 공백 제거하여 검증
    final cleanPlateNumber = plateNumber.replaceAll(' ', '');
    
    // 길이 검증을 더 유연하게 (OCR 결과 고려)
    if (cleanPlateNumber.length < 3 || cleanPlateNumber.length > 20) {
      print('  ❌ 길이 검증 실패: ${cleanPlateNumber.length}');
      return false;
    }
    
    // 자동차 번호판에 사용되는 한글 문자
    final carValidHangul = [
      '가', '나', '다', '라', '마', '바', '사', '아', '자', '차', '카', '타', '파', '하',
      '거', '너', '더', '러', '머', '버', '서', '어', '저', '처', '커', '터', '퍼', '허',
      '고', '노', '도', '로', '모', '보', '소', '오', '조', '초', '코', '토', '포', '호',
      '구', '누', '두', '루', '무', '부', '수', '우', '주', '추', '쿠', '투', '푸', '후',
      '바', '사', '아', '자', '배', '새', '애', '재'
    ];
    
    // 오토바이 번호판에 사용되는 추가 한글 (지역명, 시군구명)
    final motorcycleValidHangul = [
      '서울', '부산', '대구', '인천', '광주', '대전', '울산', '세종', '경기', '강원',
      '충북', '충남', '전북', '전남', '경북', '경남', '제주',
      '영등포', '강남', '서초', '마포', '종로', '중구', '동작', '관악', '강서', '양천',
      '구로', '금천', '동대문', '중랑', '성북', '강북', '도봉', '노원', '은평', '서대문',
      '용산', '성동', '광진', '송파', '강동',
    ];
    
    // 모든 유효한 한글 조합
    final allValidHangul = [...carValidHangul, ...motorcycleValidHangul];
    
    // 숫자가 포함되어 있는지 확인 (더 유연하게)
    final digitCount = cleanPlateNumber.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (digitCount < 2) { // 최소 2자리 숫자
      print('  ❌ 숫자 부족: $digitCount개');
      return false;
    }
    
    // 한글이 포함되어 있는지 확인 (더 유연하게)
    bool hasValidHangul = false;
    
    // 1. 지역명/구역명 확인
    for (final hangul in allValidHangul) {
      if (plateNumber.contains(hangul)) {
        hasValidHangul = true;
        print('  ✅ 지역명/구역명 발견: $hangul');
        break;
      }
    }
    
    // 2. 개별 한글 문자 확인
    if (!hasValidHangul) {
      for (int i = 0; i < cleanPlateNumber.length; i++) {
        final char = cleanPlateNumber[i];
        if (carValidHangul.contains(char)) {
          hasValidHangul = true;
          print('  ✅ 유효 한글 발견: $char');
          break;
        }
      }
    }
    
    // 3. 한글이 없어도 숫자만으로 유효성 인정 (OCR 실패 시)
    if (!hasValidHangul && digitCount >= 4) {
      print('  ⚠️ 한글 없지만 숫자 4자리 이상으로 인정');
      hasValidHangul = true;
    }
    
    final isValid = hasValidHangul && digitCount >= 2;
    print('  📝 검증 결과: ${isValid ? "✅ 유효" : "❌ 무효"} (한글: $hasValidHangul, 숫자: ${digitCount}개)');
    
    return isValid;
  }
  
  /// 고급 신뢰도 계산 (다중 요소 분석)
  double _calculateAdvancedConfidence(RecognizedText recognizedText, String plateNumber) {
    if (recognizedText.blocks.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    int factorCount = 0;
    
    // 1. 기본 텍스트 품질 점수 (0.0-1.0)
    final textQuality = _calculateTextQuality(recognizedText);
    totalScore += textQuality;
    factorCount++;
    print('  📊 텍스트 품질 점수: ${textQuality.toStringAsFixed(3)}');
    
    // 2. 번호판 형식 적합성 점수 (0.0-1.0)
    final formatScore = _calculateFormatScore(plateNumber);
    totalScore += formatScore;
    factorCount++;
    print('  📊 형식 적합성 점수: ${formatScore.toStringAsFixed(3)}');
    
    // 3. 패턴 매칭 정확도 점수 (0.0-1.0)
    final patternScore = _calculatePatternScore(plateNumber);
    totalScore += patternScore;
    factorCount++;
    print('  📊 패턴 매칭 점수: ${patternScore.toStringAsFixed(3)}');
    
    // 4. 문자 일관성 점수 (0.0-1.0)
    final consistencyScore = _calculateConsistencyScore(recognizedText, plateNumber);
    totalScore += consistencyScore;
    factorCount++;
    print('  📊 문자 일관성 점수: ${consistencyScore.toStringAsFixed(3)}');
    
    // 5. 기하학적 품질 점수 (0.0-1.0)
    final geometryScore = _calculateGeometryScore(recognizedText);
    totalScore += geometryScore;
    factorCount++;
    print('  📊 기하학적 품질 점수: ${geometryScore.toStringAsFixed(3)}');
    
    final finalConfidence = factorCount > 0 ? (totalScore / factorCount).clamp(0.0, 1.0) : 0.0;
    print('  🎯 최종 신뢰도: ${finalConfidence.toStringAsFixed(3)}');
    
    return finalConfidence;
  }

  /// 텍스트 품질 점수 계산
  double _calculateTextQuality(RecognizedText recognizedText) {
    double score = 0.5; // 기본 점수
    
    for (final block in recognizedText.blocks) {
      final text = block.text.trim();
      
      // 텍스트 길이 적정성
      if (text.length >= 5 && text.length <= 12) {
        score += 0.1;
      }
      
      // 숫자와 한글의 균형
      final digitCount = text.replaceAll(RegExp(r'[^0-9]'), '').length;
      final koreanCount = text.replaceAll(RegExp(r'[^가-힣]'), '').length;
      
      if (digitCount >= 2 && koreanCount >= 1) {
        score += 0.2;
      }
      
      // 특수문자나 불필요한 문자 감점
      final specialChars = text.replaceAll(RegExp(r'[가-힣0-9\s]'), '');
      if (specialChars.isEmpty) {
        score += 0.1;
      } else {
        score -= 0.05 * specialChars.length;
      }
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// 형식 적합성 점수 계산
  double _calculateFormatScore(String plateNumber) {
    final clean = plateNumber.replaceAll(' ', '');
    double score = 0.0;
    
    // 길이 적정성
    if (clean.length >= 5 && clean.length <= 10) {
      score += 0.3;
    }
    
    // 한국 번호판 패턴 매칭 정확도
    if (RegExp(r'^[가-힣]{2,4}[가-힣]\d{4}$').hasMatch(clean)) {
      score += 0.4; // 오토바이 패턴
    } else if (RegExp(r'^\d{2,3}[가-힣]\d{4}$').hasMatch(clean)) {
      score += 0.4; // 자동차 패턴
    } else if (RegExp(r'^[가-힣]\d{4}$').hasMatch(clean)) {
      score += 0.3; // 간단한 패턴
    }
    
    // 유효한 한글 사용
    final koreans = clean.replaceAll(RegExp(r'[^가-힣]'), '');
    if (_containsValidKoreanChars(koreans)) {
      score += 0.3;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// 패턴 매칭 점수 계산
  double _calculatePatternScore(String plateNumber) {
    final patterns = [
      (RegExp(r'[가-힣]{2,4}\s+[가-힣]{2,4}\s+[가-힣]\s+\d{4}'), 1.0),
      (RegExp(r'[가-힣]{4,8}[가-힣]\d{4}'), 0.9),
      (RegExp(r'\d{2,3}[가-힣]\d{4}'), 0.9),
      (RegExp(r'[가-힣]{2}\d{2}[가-힣]\d{4}'), 0.8),
      (RegExp(r'[가-힣]\d{4}'), 0.7),
    ];
    
    for (final (pattern, weight) in patterns) {
      if (pattern.hasMatch(plateNumber)) {
        return weight;
      }
    }
    
    return 0.3; // 기본 점수
  }

  /// 문자 일관성 점수 계산
  double _calculateConsistencyScore(RecognizedText recognizedText, String plateNumber) {
    double score = 0.5;
    
    // 원본 텍스트와 추출된 번호판의 일관성
    final originalText = recognizedText.text.replaceAll(RegExp(r'\s+'), '');
    final extractedText = plateNumber.replaceAll(RegExp(r'\s+'), '');
    
    // 문자열 유사도 계산 (간단한 버전)
    final similarity = _calculateStringSimilarity(originalText, extractedText);
    score += similarity * 0.3;
    
    // 블록 간 일관성 (여러 블록이 같은 번호판을 가리키는지)
    var consistentBlocks = 0;
    for (final block in recognizedText.blocks) {
      if (block.text.contains(RegExp(r'[가-힣]')) && block.text.contains(RegExp(r'\d'))) {
        consistentBlocks++;
      }
    }
    
    if (consistentBlocks > 0) {
      score += 0.2;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// 기하학적 품질 점수 계산
  double _calculateGeometryScore(RecognizedText recognizedText) {
    double score = 0.5;
    
    for (final block in recognizedText.blocks) {
      // 블록의 경계 상자 품질 평가
      final corners = block.cornerPoints;
      if (corners.length == 4) {
        // 직사각형 형태인지 확인
        final width1 = (corners[1].x - corners[0].x).abs();
        final width2 = (corners[2].x - corners[3].x).abs();
        final height1 = (corners[3].y - corners[0].y).abs();
        final height2 = (corners[2].y - corners[1].y).abs();
        
        // 너비와 높이의 일관성
        final widthConsistency = 1.0 - (width1 - width2).abs() / ((width1 + width2) / 2);
        final heightConsistency = 1.0 - (height1 - height2).abs() / ((height1 + height2) / 2);
        
        score += (widthConsistency + heightConsistency) * 0.1;
        
        // 번호판 비율 (일반적으로 가로가 세로보다 3-5배 길음)
        final avgWidth = (width1 + width2) / 2;
        final avgHeight = (height1 + height2) / 2;
        if (avgHeight > 0) {
          final aspectRatio = avgWidth / avgHeight;
          if (aspectRatio >= 2.5 && aspectRatio <= 6.0) {
            score += 0.2;
          }
        }
      }
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// 문자열 유사도 계산 (레벤슈타인 거리 기반)
  double _calculateStringSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    final maxLength = s1.length > s2.length ? s1.length : s2.length;
    final distance = _levenshteinDistance(s1, s2);
    
    return 1.0 - (distance / maxLength);
  }

  /// 레벤슈타인 거리 계산
  int _levenshteinDistance(String s1, String s2) {
    final matrix = List.generate(
      s1.length + 1, 
      (i) => List<int>.filled(s2.length + 1, 0)
    );
    
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // 삭제
          matrix[i][j - 1] + 1,      // 삽입
          matrix[i - 1][j - 1] + cost // 대체
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[s1.length][s2.length];
  }

  /// 유효한 한글 문자 포함 여부 확인
  bool _containsValidKoreanChars(String text) {
    final validChars = [
      '가', '나', '다', '라', '마', '바', '사', '아', '자', '차', '카', '타', '파', '하',
      '거', '너', '더', '러', '머', '버', '서', '어', '저', '처', '커', '터', '퍼', '허',
      '고', '노', '도', '로', '모', '보', '소', '오', '조', '초', '코', '토', '포', '호',
      '구', '누', '두', '루', '무', '부', '수', '우', '주', '추', '쿠', '투', '푸', '후'
    ];
    
    for (final char in text.split('')) {
      if (validChars.contains(char)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// 임시 파일 정리 유틸리티
  void _cleanupTempFile(String filePath) {
    try {
      final tempFile = File(filePath);
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
        print('🗑️ 임시 파일 삭제: $filePath');
      }
    } catch (e) {
      print('⚠️ 임시 파일 삭제 실패: $e');
    }
  }

  /// 기본 이미지 전처리 (빠른 처리)
  Future<String> _preprocessImageBasic(String imagePath) async {
    try {
      print('🎨 기본 이미지 전처리 시작: $imagePath');
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) return imagePath;
      
      // 1. 대비 및 밝기 향상만 적용
      var processedImage = img.adjustColor(
        originalImage,
        contrast: 1.5,
        brightness: 1.2,
        gamma: 1.0,
      );
      
      // 전처리된 이미지 저장
      final processedPath = imagePath.replaceFirst(
        RegExp(r'\.(jpg|jpeg|png)$'), 
        '_basic.jpg'
      );
      final processedFile = File(processedPath);
      await processedFile.writeAsBytes(img.encodeJpg(processedImage, quality: 95));
      
      print('✅ 기본 전처리 완료: $processedPath');
      return processedPath;
    } catch (e) {
      print('❌ 기본 이미지 전처리 실패: $e');
      return imagePath;
    }
  }

  /// 크기 조정 및 샤프닝 전처리
  Future<String> _preprocessImageScaled(String imagePath) async {
    try {
      print('🎨 크기 조정 전처리 시작: $imagePath');
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) return imagePath;
      
      // 1. 이미지 크기를 2배로 확대 (OCR 성능 향상)
      var processedImage = img.copyResize(
        originalImage, 
        width: originalImage.width * 2,
        height: originalImage.height * 2,
        interpolation: img.Interpolation.cubic,
      );
      
      // 2. 그레이스케일 변환
      processedImage = img.grayscale(processedImage);
      
      // 3. 강한 샤프닝 적용
      processedImage = img.adjustColor(
        processedImage,
        contrast: 1.8,
        brightness: 1.1,
      );
      
      // 전처리된 이미지 저장
      final processedPath = imagePath.replaceFirst(
        RegExp(r'\.(jpg|jpeg|png)$'), 
        '_scaled.jpg'
      );
      final processedFile = File(processedPath);
      await processedFile.writeAsBytes(img.encodeJpg(processedImage, quality: 100));
      
      print('✅ 크기 조정 전처리 완료: $processedPath');
      return processedPath;
    } catch (e) {
      print('❌ 크기 조정 전처리 실패: $e');
      return imagePath;
    }
  }

  /// 고급 이미지 전처리 파이프라인 (번호판 특화)
  Future<String> _preprocessImage(String imagePath) async {
    try {
      print('🎨 고급 이미지 전처리 시작: $imagePath');
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) return imagePath;
      
      // 1단계: 그레이스케일 변환 (텍스트 인식 최적화)
      var processedImage = img.grayscale(originalImage);
      print('  ✓ 1단계: 그레이스케일 변환 완료');
      
      // 2단계: 가우시안 블러로 노이즈 제거
      processedImage = img.gaussianBlur(processedImage, radius: 1);
      print('  ✓ 2단계: 노이즈 제거 완료');
      
      // 3단계: 대비 및 밝기 향상
      processedImage = img.adjustColor(
        processedImage,
        contrast: 1.3,
        brightness: 1.15,
        gamma: 1.1,
      );
      print('  ✓ 3단계: 대비/밝기 향상 완료');
      
      // 4단계: 언샵 마스크 (샤프닝)
      processedImage = _applySharpenFilter(processedImage);
      print('  ✓ 4단계: 샤프닝 필터 적용 완료');
      
      // 5단계: 적응적 임계값 (이진화)
      processedImage = _applyAdaptiveThreshold(processedImage);
      print('  ✓ 5단계: 적응적 임계값 적용 완료');
      
      // 6단계: 모폴로지 연산 (노이즈 정리)
      processedImage = _applyMorphologyOperations(processedImage);
      print('  ✓ 6단계: 모폴로지 연산 완료');
      
      // 전처리된 이미지 저장
      final processedPath = imagePath.replaceFirst(
        RegExp(r'\.(jpg|jpeg|png)$'), 
        '_enhanced.jpg'
      );
      final processedFile = File(processedPath);
      await processedFile.writeAsBytes(img.encodeJpg(processedImage, quality: 95));
      
      print('✅ 고급 전처리 완료: $processedPath');
      return processedPath;
    } catch (e) {
      print('❌ 고급 이미지 전처리 실패: $e');
      return imagePath; // 전처리 실패시 원본 반환
    }
  }

  /// 언샵 마스크 필터 (샤프닝)
  img.Image _applySharpenFilter(img.Image image) {
    // 언샵 마스크 커널을 수동으로 적용 (image 라이브러리 API 변경으로 인한 대체)
    final result = img.Image.from(image);
    final kernel = [
      [0, -1, 0],
      [-1, 5, -1],
      [0, -1, 0],
    ];
    
    // 수동 컨볼루션 적용
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        double r = 0, g = 0, b = 0;
        
        for (int ky = 0; ky < 3; ky++) {
          for (int kx = 0; kx < 3; kx++) {
            final px = x + kx - 1;
            final py = y + ky - 1;
            final pixel = image.getPixel(px, py);
            final weight = kernel[ky][kx];
            
            r += pixel.r * weight;
            g += pixel.g * weight;
            b += pixel.b * weight;
          }
        }
        
        // 값 범위 제한
        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);
        
        final newPixel = img.ColorRgb8(r.toInt(), g.toInt(), b.toInt());
        result.setPixel(x, y, newPixel);
      }
    }
    
    return result;
  }

  /// 적응적 임계값 적용 (이진화)
  img.Image _applyAdaptiveThreshold(img.Image image) {
    // 단순한 전역 임계값 적용 (OpenCV의 adaptiveThreshold 간소 구현)
    final threshold = _calculateOtsuThreshold(image);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = img.getLuminance(pixel);
        
        // 임계값 기준으로 이진화
        final newPixel = gray > threshold 
            ? img.ColorRgb8(255, 255, 255)  // 흰색
            : img.ColorRgb8(0, 0, 0);       // 검은색
            
        image.setPixel(x, y, newPixel);
      }
    }
    
    return image;
  }

  /// Otsu 알고리즘으로 최적 임계값 계산
  int _calculateOtsuThreshold(img.Image image) {
    // 히스토그램 계산
    final histogram = List<int>.filled(256, 0);
    final totalPixels = image.width * image.height;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = img.getLuminance(pixel).toInt();
        histogram[gray]++;
      }
    }
    
    // Otsu 알고리즘
    double maxVariance = 0;
    int optimalThreshold = 0;
    
    for (int t = 0; t < 256; t++) {
      int w0 = 0, w1 = 0;
      double sum0 = 0, sum1 = 0;
      
      // 배경과 전경 픽셀 수 및 평균 계산
      for (int i = 0; i < t; i++) {
        w0 += histogram[i];
        sum0 += i * histogram[i];
      }
      for (int i = t; i < 256; i++) {
        w1 += histogram[i];
        sum1 += i * histogram[i];
      }
      
      if (w0 == 0 || w1 == 0) continue;
      
      final mean0 = sum0 / w0;
      final mean1 = sum1 / w1;
      final variance = (w0 / totalPixels) * (w1 / totalPixels) * 
                      (mean0 - mean1) * (mean0 - mean1);
      
      if (variance > maxVariance) {
        maxVariance = variance;
        optimalThreshold = t;
      }
    }
    
    return optimalThreshold;
  }

  /// 모폴로지 연산 (노이즈 정리)
  img.Image _applyMorphologyOperations(img.Image image) {
    // Opening 연산: 침식 후 팽창 (작은 노이즈 제거)
    var result = _erode(image, 1);
    result = _dilate(result, 1);
    
    // Closing 연산: 팽창 후 침식 (구멍 메우기)
    result = _dilate(result, 1);
    result = _erode(result, 1);
    
    return result;
  }

  /// 침식 연산
  img.Image _erode(img.Image image, int radius) {
    final result = img.Image.from(image);
    
    for (int y = radius; y < image.height - radius; y++) {
      for (int x = radius; x < image.width - radius; x++) {
        int minValue = 255;
        
        // 커널 영역에서 최소값 찾기
        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            final pixel = image.getPixel(x + dx, y + dy);
            final gray = img.getLuminance(pixel).toInt();
            minValue = minValue < gray ? minValue : gray;
          }
        }
        
        final newPixel = img.ColorRgb8(minValue, minValue, minValue);
        result.setPixel(x, y, newPixel);
      }
    }
    
    return result;
  }

  /// 팽창 연산
  img.Image _dilate(img.Image image, int radius) {
    final result = img.Image.from(image);
    
    for (int y = radius; y < image.height - radius; y++) {
      for (int x = radius; x < image.width - radius; x++) {
        int maxValue = 0;
        
        // 커널 영역에서 최대값 찾기
        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            final pixel = image.getPixel(x + dx, y + dy);
            final gray = img.getLuminance(pixel).toInt();
            maxValue = maxValue > gray ? maxValue : gray;
          }
        }
        
        final newPixel = img.ColorRgb8(maxValue, maxValue, maxValue);
        result.setPixel(x, y, newPixel);
      }
    }
    
    return result;
  }
  
  /// 여러 이미지에서 번호판 일괄 인식
  Future<List<LicensePlateModel>> recognizeMultiplePlates(List<String> imagePaths) async {
    final results = <LicensePlateModel>[];
    
    for (final imagePath in imagePaths) {
      final result = await recognizeLicensePlate(imagePath);
      if (result != null) {
        results.add(result);
      }
    }
    
    return results;
  }
  
  /// OCR 서비스 정리
  Future<void> dispose() async {
    try {
      await _textRecognizer.close();
      print('✅ 번호판 OCR 서비스 정리 완료');
    } catch (e) {
      print('❌ 번호판 OCR 서비스 정리 실패: $e');
    }
  }
}