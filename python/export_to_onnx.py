"""
Template: Export detector (YOLOv8-like) and recognizer (CRNN-like) to ONNX.
Adjust the model loading / input size / dynamic axes based on your codebase.
"""
import torch
import argparse
from pathlib import Path

def export_detector(pth, onnx_out, img_size=(640, 640)):
    model = torch.load(pth, map_location="cpu")
    model.eval()
    x = torch.zeros(1, 3, img_size[0], img_size[1])
    torch.onnx.export(
        model, x, onnx_out,
        input_names=["images"], output_names=["preds"],
        opset_version=12,
        dynamic_axes=None  # fix input size for mobile ease
    )
    print(f"Detector ONNX saved to {onnx_out}")

def export_recognizer(pth, onnx_out, img_size=(48, 160)):  # H x W for CRNN-style
    model = torch.load(pth, map_location="cpu")
    model.eval()
    x = torch.zeros(1, 3, img_size[0], img_size[1])
    torch.onnx.export(
        model, x, onnx_out,
        input_names=["images"], output_names=["logits"],
        opset_version=12,
        dynamic_axes=None
    )
    print(f"Recognizer ONNX saved to {onnx_out}")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--det-pth", type=Path, required=False, help="Detector .pth")
    ap.add_argument("--rec-pth", type=Path, required=False, help="Recognizer .pth")
    ap.add_argument("--det-onnx", type=Path, default=Path("detector.onnx"))
    ap.add_argument("--rec-onnx", type=Path, default=Path("recognizer.onnx"))
    ap.add_argument("--det-size", type=str, default="640,640")
    ap.add_argument("--rec-size", type=str, default="48,160")
    args = ap.parse_args()

    if args.det_pth:
        h, w = map(int, args.det_size.split(","))
        export_detector(args.det_pth, args.det_onnx, (h, w))

    if args.rec_pth:
        h, w = map(int, args.rec_size.split(","))
        export_recognizer(args.rec_pth, args.rec_onnx, (h, w))
