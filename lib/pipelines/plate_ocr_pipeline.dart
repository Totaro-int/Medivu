// lib/pipelines/plate_ocr_pipeline.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/ml_kit_ocr_service.dart';
import '../models/geometry_models.dart';

class PlateOcrResult {
  final RectF box;
  final String text;
  PlateOcrResult(this.box, this.text);
}

class PlateOcrPipeline {
  static PlateOcrPipeline? _instance;
  final MLKitOcrService _ocrService = MLKitOcrService.instance;
  bool _isInitialized = false;
  bool _isDisposed = false;

  static PlateOcrPipeline get instance {
    _instance ??= PlateOcrPipeline._internal();
    return _instance!;
  }

  PlateOcrPipeline._internal();

  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;

    try {
      await _ocrService.initialize();
      _isInitialized = true;
      print('OCR Pipeline 초기화 완료');
    } catch (e) {
      if (kDebugMode) {
        print('OCR Pipeline 초기화 실패: $e');
      }
      dispose();
    }
  }

  Future<PlateOcrResult?> processFrame(Uint8List rgbBytes, int width, int height, {int rotation = 0}) async {
    if (!_isInitialized || _isDisposed) {
      return null;
    }

    try {
      final results = await _ocrService.processFrame(rgbBytes, width, height);

      if (results.isNotEmpty) {
        // 첫 번째 결과 반환 (가장 신뢰도가 높은 것으로 가정)
        final result = results.first;
        return PlateOcrResult(result.box, result.text);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('OCR 처리 에러: $e');
      }
      return null;
    }
  }

  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _isInitialized = false;

    try {
      _ocrService.dispose();
    } catch (e) {
      if (kDebugMode) {
        print('OCR Pipeline dispose 에러: $e');
      }
    } finally {
      _instance = null;
    }
  }
}

