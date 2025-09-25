// lib/services/ml_kit_ocr_service.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/geometry_models.dart';
import '../utils/postprocess.dart';

class PlateDetectionResult {
  final RectF box;
  final String text;
  final double confidence;

  PlateDetectionResult({
    required this.box,
    required this.text,
    required this.confidence,
  });
}

class MLKitOcrService {
  static MLKitOcrService? _instance;
  late TextRecognizer _textRecognizer;
  bool _isInitialized = false;

  static MLKitOcrService get instance {
    _instance ??= MLKitOcrService._internal();
    return _instance!;
  }

  MLKitOcrService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
      _isInitialized = true;
      print('ML Kit OCR Service 초기화 완료');
    } catch (e) {
      print('ML Kit OCR Service 초기화 실패: $e');
      throw e;
    }
  }

  Future<List<PlateDetectionResult>> processFrame(
    Uint8List imageBytes,
    int width,
    int height,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.yuv420,
          bytesPerRow: width,
        ),
      );

      final recognizedText = await _textRecognizer.processImage(inputImage);
      final results = <PlateDetectionResult>[];

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final text = line.text.trim();

          // 한국 번호판 패턴 필터링
          if (_isKoreanPlatePattern(text)) {
            final rect = line.boundingBox;
            final processedText = postprocessKoreanPlate(text);

            results.add(PlateDetectionResult(
              box: RectF(
                rect.left.toDouble(),
                rect.top.toDouble(),
                rect.width.toDouble(),
                rect.height.toDouble(),
              ),
              text: processedText,
              confidence: 0.8, // ML Kit doesn't provide confidence, use default
            ));
          }
        }
      }

      return results;
    } catch (e) {
      print('ML Kit OCR 처리 에러: $e');
      return [];
    }
  }

  bool _isKoreanPlatePattern(String text) {
    // 기본 한글 + 숫자 패턴 체크
    final koreanPlateRegex = RegExp(r'[\d가-힣\s]{4,8}');

    if (!koreanPlateRegex.hasMatch(text)) return false;

    // 한글이 포함되어 있는지 체크
    final hasKorean = RegExp(r'[가-힣]').hasMatch(text);
    // 숫자가 포함되어 있는지 체크
    final hasNumber = RegExp(r'\d').hasMatch(text);

    return hasKorean && hasNumber;
  }

  void dispose() {
    if (_isInitialized) {
      _textRecognizer.close();
      _isInitialized = false;
    }
  }
}