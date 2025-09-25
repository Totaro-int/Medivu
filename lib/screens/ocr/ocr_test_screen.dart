import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../widgets/camera_preview_with_ocr_overlay.dart';

class OcrTestScreen extends StatefulWidget {
  const OcrTestScreen({super.key});

  @override
  State<OcrTestScreen> createState() => _OcrTestScreenState();
}

class _OcrTestScreenState extends State<OcrTestScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // 기존 카메라 컨트롤러 정리
      await _cameraController?.dispose();
      _cameraController = null;
      
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _error = '사용 가능한 카메라가 없습니다.';
          });
        }
        return;
      }

      // 후면 카메라 우선 선택
      CameraDescription selectedCamera = cameras.first;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // Android CameraX 호환성
      );

      await _cameraController!.initialize();
      
      if (mounted && _cameraController != null) {
        setState(() {
          _isInitialized = true;
          _error = '';
        });
      }
    } catch (e) {
      print('카메라 초기화 오류: $e');
      if (mounted) {
        setState(() {
          _error = '카메라 초기화 실패: ${e.toString()}';
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('번호판 OCR 테스트'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = '';
                });
                _initializeCamera();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('카메라 초기화 중...'),
          ],
        ),
      );
    }

    return CameraPreviewWithOcrOverlay(camera: _cameraController!);
  }
}