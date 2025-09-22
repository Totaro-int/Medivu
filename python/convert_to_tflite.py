"""
Template: Convert ONNX -> (optional) SavedModel -> TFLite.
If you already have a TF SavedModel, adapt to skip ONNX step.
Requires TensorFlow installed in your Python env.
"""
import argparse
from pathlib import Path

# NOTE: For ONNX->TF conversion you might use onnx-tf or tf2onnx externally.
# Here we show SavedModel->TFLite path, assuming you've produced a SavedModel at ./saved_model.
import tensorflow as tf

def to_tflite(saved_model_dir, tflite_out, fp16=False, int8=False, calib_list=None):
    converter = tf.lite.TFLiteConverter.from_saved_model(str(saved_model_dir))

    if int8:
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        if calib_list:
            # Representative dataset for full integer quantization
            def rep_dataset():
                import cv2, numpy as np
                with open(calib_list) as f:
                    files = [l.strip() for l in f if l.strip()]
                for p in files:
                    img = cv2.imread(p)
                    if img is None: 
                        continue
                    # TODO: apply SAME preprocessing as training/inference (resize/normalize)
                    img = cv2.resize(img, (160, 48))  # example for recognizer
                    img = img[:, :, ::-1]  # BGR->RGB if needed
                    img = img.astype("float32") / 255.0
                    img = img[None, ...]
                    yield [img]
            converter.representative_dataset = rep_dataset
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        converter.inference_input_type = tf.uint8  # or int8 if your pipeline expects int8
        converter.inference_output_type = tf.uint8
    elif fp16:
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]
    else:
        # float32
        pass

    tflite_model = converter.convert()
    Path(tflite_out).write_bytes(tflite_model)
    print(f"TFLite saved to {tflite_out}")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--saved-model", type=Path, required=True)
    ap.add_argument("--out", type=Path, default=Path("model.tflite"))
    ap.add_argument("--fp16", action="store_true")
    ap.add_argument("--int8", action="store_true")
    ap.add_argument("--calib-list", type=Path, help="calibration file list (one image path per line)")
    args = ap.parse_args()
    to_tflite(args.saved_model, args.out, fp16=args.fp16, int8=args.int8, calib_list=args.calib_list)
