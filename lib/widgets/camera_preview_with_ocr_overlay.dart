import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../pipelines/plate_ocr_pipeline.dart';

class CameraPreviewWithOcrOverlay extends StatefulWidget {
  final CameraController camera;

  const CameraPreviewWithOcrOverlay({
    super.key,
    required this.camera,
  });

  @override
  State<CameraPreviewWithOcrOverlay> createState() => _CameraPreviewWithOcrOverlayState();
}

class _CameraPreviewWithOcrOverlayState extends State<CameraPreviewWithOcrOverlay> {
  PlateOcrResult? _lastResult;
  late Timer _processTimer;
  final PlateOcrPipeline _ocrPipeline = PlateOcrPipeline.instance;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeOcrPipeline();

    // 1초마다 프레임 처리
    _processTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _processFrame();
    });
  }

  Future<void> _initializeOcrPipeline() async {
    try {
      await _ocrPipeline.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('OCR 파이프라인 초기화 실패: $e');
    }
  }

  Future<void> _processFrame() async {
    if (!_isInitialized) {
      return;
    }

    // 카메라 상태 확인
    if (!widget.camera.value.isInitialized || widget.camera.value.hasError) {
      return;
    }

    try {
      // 더미 RGB 데이터로 테스트 (실제 구현에서는 카메라 스트림 사용)
      final dummyRgbBytes = Uint8List.fromList(
        List.generate(640 * 480 * 3, (i) => (i % 256))
      );

      final result = await _ocrPipeline.processFrame(dummyRgbBytes, 640, 480);

      if (result != null && mounted) {
        setState(() {
          _lastResult = result;
        });
      }
    } catch (e) {
      debugPrint('프레임 처리 오류: $e');
    }
  }

  @override
  void dispose() {
    _processTimer.cancel();
    _ocrPipeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 카메라 프리뷰
        SizedBox.expand(
          child: CameraPreview(widget.camera),
        ),

        // OCR 결과 오버레이
        if (_lastResult != null) ...[
          // 감지된 번호판 영역 표시
          Positioned(
            left: _lastResult!.box.x,
            top: _lastResult!.box.y,
            width: _lastResult!.box.w,
            height: _lastResult!.box.h,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green,
                  width: 2.0,
                ),
              ),
            ),
          ),

          // 인식된 텍스트 표시
          Positioned(
            left: _lastResult!.box.x,
            top: _lastResult!.box.y - 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _lastResult!.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],

        // 초기화 상태 표시
        if (!_isInitialized)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'OCR 초기화 중...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
      ],
    );
  }
}