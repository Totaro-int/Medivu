// lib/pipelines/plate_ocr_pipeline.dart
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import '../services/detector.dart';
import '../services/recognizer.dart';
import '../services/tracker.dart';
import '../utils/postprocess.dart';
import '../models/geometry_models.dart';

class PlateOcrRequest {
  final Uint8List rgbBytes;
  final int width;
  final int height;
  final int rotation;
  PlateOcrRequest({required this.rgbBytes, required this.width, required this.height, required this.rotation});
}

class PlateOcrResult {
  final RectF box;
  final String text;
  PlateOcrResult(this.box, this.text);
}

class PlateOcrPipeline {
  static PlateOcrPipeline? _instance;
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
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
      _receivePort = ReceivePort();
      _isolate = await Isolate.spawn(runPlateOcrIsolate, _receivePort!.sendPort);
      
      await for (final msg in _receivePort!) {
        if (msg is SendPort) {
          _sendPort = msg;
          _isInitialized = true;
          break;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('OCR Pipeline 초기화 실패: $e');
      }
      dispose();
    }
  }

  Future<PlateOcrResult?> processFrame(Uint8List rgbBytes, int width, int height, {int rotation = 0}) async {
    if (!_isInitialized || _isDisposed || _sendPort == null) {
      return null;
    }

    try {
      final request = PlateOcrRequest(
        rgbBytes: rgbBytes,
        width: width,
        height: height,
        rotation: rotation,
      );

      _sendPort!.send(request);
      
      // 결과 대기 (타임아웃 설정)
      final completer = Completer<PlateOcrResult?>();
      late StreamSubscription subscription;
      
      subscription = _receivePort!.listen((msg) {
        if (msg is PlateOcrResult) {
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.complete(msg);
          }
        }
      });

      // 2초 타임아웃
      return await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          subscription.cancel();
          return null;
        },
      );
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
      _receivePort?.close();
      _isolate?.kill();
    } catch (e) {
      if (kDebugMode) {
        print('OCR Pipeline dispose 에러: $e');
      }
    } finally {
      _receivePort = null;
      _sendPort = null;
      _isolate = null;
      _instance = null;
    }
  }
}

Future<void> runPlateOcrIsolate(SendPort initPort) async {
  ReceivePort? port;
  Detector? det;
  Recognizer? rec;
  IouTracker? tracker;

  try {
    det = await Detector.create('assets/models/dummy_detector.tflite');
    rec = await Recognizer.create('assets/models/dummy_recognizer.tflite');
    tracker = IouTracker(iouThresh: 0.5, maxAge: 10);
    port = ReceivePort();
    initPort.send(port.sendPort);

    await for (final msg in port) {
      if (msg == 'dispose') {
        break;
      }
      
      try {
        final PlateOcrRequest r = msg as PlateOcrRequest;
        final dets = det.infer(r.rgbBytes, r.width, r.height);
        final detBoxes = dets.map((d)=> [d.box.x, d.box.y, d.box.w, d.box.h, d.score]).toList();
        final tracks = tracker.update(detBoxes);
        
        if (tracks.isNotEmpty) {
          final t = tracks.first;
          final croppedBytes = _cropRegion(r.rgbBytes, r.width, r.height, t.box);
          final rawText = rec.infer(croppedBytes);
          final text = postprocessKoreanPlate(rawText);
          
          initPort.send(PlateOcrResult(RectF(t.box[0], t.box[1], t.box[2], t.box[3]), text));
        }
      } catch (e) {
        // 개별 프레임 처리 에러는 무시하고 계속 진행
        continue;
      }
    }
  } catch (e) {
    // Isolate 초기화 에러
  } finally {
    // 리소스 정리
    port?.close();
    // Note: Detector와 Recognizer에는 dispose 메서드가 없음
  }
}

// 이미지에서 특정 영역을 크롭하는 함수
Uint8List _cropRegion(Uint8List rgbBytes, int width, int height, List<double> box) {
  final x = box[0].clamp(0.0, width.toDouble()).toInt();
  final y = box[1].clamp(0.0, height.toDouble()).toInt();
  final w = box[2].clamp(0.0, width - x.toDouble()).toInt();
  final h = box[3].clamp(0.0, height - y.toDouble()).toInt();
  
  // 간단한 크롭 구현 (실제로는 더 정교한 이미지 처리 필요)
  final croppedBytes = Uint8List(w * h * 3);
  
  for (int row = 0; row < h; row++) {
    for (int col = 0; col < w; col++) {
      final srcIdx = ((y + row) * width + (x + col)) * 3;
      final dstIdx = (row * w + col) * 3;
      
      if (srcIdx + 2 < rgbBytes.length && dstIdx + 2 < croppedBytes.length) {
        croppedBytes[dstIdx] = rgbBytes[srcIdx];     // R
        croppedBytes[dstIdx + 1] = rgbBytes[srcIdx + 1]; // G
        croppedBytes[dstIdx + 2] = rgbBytes[srcIdx + 2]; // B
      }
    }
  }
  
  return croppedBytes;
}
