# Flutter Plate OCR Starter Kit

This starter kit includes:
- **Model export** templates (PyTorch → ONNX) and **TFLite conversion** scripts.
- **Calibration dataset** helper for int8 quantization.
- **Regression evaluation** to compare accuracy *before vs after* conversion (mAP for detection, CER/WER for OCR).
- **Flutter/Dart** service skeletons: detector/recognizer wrappers, IOU tracker, pipeline, and Korean plate post-processing utilities.

> Note: All code is template-style and may require adapting to your specific models (e.g., YOLOv8, CRNN/PP-OCR).

## Structure
```
flutter_plate_ocr_starter_kit/
  README.md
  python/
    export_to_onnx.py
    convert_to_tflite.py
    calibration_dataset_prep.py
    regression_eval.py
  dart/
    lib/
      services/
        detector.dart
        recognizer.dart
        tracker.dart
      pipelines/
        plate_ocr_pipeline.dart
      utils/
        postprocess.dart
```

## Quick Start
1. Train your detector (e.g., YOLOv8n) and recognizer (e.g., CRNN/PP-OCR head).
2. Run `python/export_to_onnx.py` to export both models to ONNX.
3. Prepare a **calibration list** (`calib_list.txt`) using `python/calibration_dataset_prep.py` (one image path per line).
4. Convert to TFLite with `python/convert_to_tflite.py` (fp16 or int8).
5. Evaluate **pre/post conversion** with `python/regression_eval.py` to confirm accuracy parity.
6. Place TFLite files in your Flutter project's `assets/models/` and wire up `dart/lib/...` templates.
