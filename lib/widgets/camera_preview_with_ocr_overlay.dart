import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../pipelines/plate_ocr_pipeline.dart';

class CameraPreviewWithOcrOverlay extends StatefulWidget {
  final CameraController camera;
  
  const CameraPreviewWithOcrOverlay({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  State<CameraPreviewWithOcrOverlay> createState() => _CameraPreviewWithOcrOverlayState();
}

class _CameraPreviewWithOcrOverlayState extends State<CameraPreviewWithOcrOverlay> {
  PlateOcrResult? _lastResult;
  late Timer _processTimer;
  SendPort? _ocrSendPort;
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
      final receivePort = ReceivePort();
      await Isolate.spawn(runPlateOcrIsolate, receivePort.sendPort);
      
      // Isolate에서 보내는 메시지 수신
      receivePort.listen(
        (message) {
          if (!mounted) return; // 위젯이 dispose된 경우 무시
          
          try {
            if (message is SendPort) {
              _ocrSendPort = message;
              setState(() {
                _isInitialized = true;
              });
              print('OCR 파이프라인 초기화 완료');
            } else if (message is PlateOcrResult) {
              setState(() {
                _lastResult = message;
              });
              print('OCR 결과 수신: ${message.text}');
            }
          } catch (e) {
            print('OCR 메시지 처리 오류: $e');
          }
        },
        onError: (error) {
          print('OCR Isolate 오류: $error');
        },
      );
    } catch (e) {
      print('OCR 파이프라인 초기화 실패: $e');
    }
  }
  
  Future<void> _processFrame() async {
    if (!_isInitialized || _ocrSendPort == null) {
      return;
    }
    
    // 카메라 상태 재확인
    if (!widget.camera.value.isInitialized || widget.camera.value.hasError) {
      print('카메라 상태 오류: 초기화되지 않음 또는 오류 발생');
      return;
    }
    
    try {
      // takePicture() 대신 더미 데이터로 OCR 파이프라인 테스트
      // 실제로는 이미지 스트림을 사용해야 함
      final dummyRgbBytes = Uint8List.fromList(
        List.generate(640 * 480 * 3, (i) => (i % 256))
      );
      
      final request = PlateOcrRequest(
        rgbBytes: dummyRgbBytes,
        width: 640,
        height: 480,
        rotation: 0,
      );
      
      _ocrSendPort!.send(request);
      print('OCR 요청 전송 완료');
    } catch (e) {
      print('프레임 처리 오류: $e');
    }
  }
  
  String _getPlateType(String plateText) {
    if (RegExp(r'^[가-힣]').hasMatch(plateText.trim())) {
      return '타입: 오토바이 번호판';
    } else if (RegExp(r'^\d{2,3}[가-힣]').hasMatch(plateText.trim())) {
      return '타입: 자동차 번호판';
    } else {
      return '타입: 확인 중...';
    }
  }

  @override
  void dispose() {
    _processTimer.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // 카메라 상태 다중 체크
    if (!widget.camera.value.isInitialized || widget.camera.value.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              widget.camera.value.hasError 
                ? '카메라 오류: ${widget.camera.value.errorDescription}'
                : '카메라 초기화 중...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Stack(
      children: [
        // 카메라 프리뷰 (안전하게 래핑)
        ClipRect(
          child: AspectRatio(
            aspectRatio: widget.camera.value.aspectRatio,
            child: CameraPreview(widget.camera),
          ),
        ),
        
        // OCR 결과 오버레이
        if (_lastResult != null)
          Positioned(
            left: _lastResult!.box.x,
            top: _lastResult!.box.y,
            child: Container(
              width: _lastResult!.box.w,
              height: _lastResult!.box.h,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                color: Colors.green.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _lastResult!.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      // 시스템 기본 폰트 사용 (한글 지원)
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        
        // 상태 표시
        Positioned(
          top: 50,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OCR 상태: ${_isInitialized ? "활성" : "초기화 중"}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                if (_lastResult != null) ...[
                  Text(
                    '인식된 번호판: ${_lastResult!.text}',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _getPlateType(_lastResult!.text),
                    style: const TextStyle(color: Colors.lightBlue, fontSize: 11),
                  ),
                ],
                Text(
                  '테스트 형식: 12가3456 (자동차), 가 1234 (오토바이)',
                  style: const TextStyle(color: Colors.yellow, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}