"""
Regression evaluation for pre/post conversion accuracy:
- Detection: mAP (requires ground-truth in COCO-like format or your custom format)
- OCR: CER/WER
This is a scaffold: plug your dataloaders/inference for torch/onnx/tflite.
"""
import argparse, json, numpy as np
from pathlib import Path

def cer(ref, hyp):
    # Levenshtein distance / len(ref)
    import numpy as np
    R, H = len(ref), len(hyp)
    dp = np.zeros((R+1, H+1), dtype=int)
    for i in range(R+1): dp[i,0]=i
    for j in range(H+1): dp[0,j]=j
    for i in range(1,R+1):
        for j in range(1,H+1):
            cost = 0 if ref[i-1]==hyp[j-1] else 1
            dp[i,j] = min(dp[i-1,j]+1, dp[i,j-1]+1, dp[i-1,j-1]+cost)
    return dp[R,H] / max(1,R)

def load_ocr_gt(path):
    # Expect JSON list: [{"img":"path","text":"12가3456"}, ...]
    return json.loads(Path(path).read_text())

def infer_ocr_batch(model_kind, model_path, batch):
    # Stub: implement your inference per backend
    # Return list of predicted strings in same order
    # e.g., call PyTorch, ONNX Runtime, or TFLite runtime
    return [""] * len(batch)

def eval_ocr(model_kind, model_path, gt_json):
    data = load_ocr_gt(gt_json)
    imgs = [d["img"] for d in data]
    refs = [d["text"] for d in data]
    preds = infer_ocr_batch(model_kind, model_path, imgs)
    cers = [cer(r, p) for r, p in zip(refs, preds)]
    return {"CER_mean": float(np.mean(cers))}

def eval_det_coco(pred_json_path, gt_json_path):
    # If you export predictions to COCO JSON, you can compute mAP via pycocotools.
    # Placeholder here (to keep dependencies minimal). Integrate pycocotools in your env.
    return {"mAP": None}

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--ocr-gt", type=Path, help="OCR eval GT JSON")
    ap.add_argument("--ocr-model", type=Path, help="Model path")
    ap.add_argument("--ocr-kind", choices=["torch","onnx","tflite"], default="onnx")
    args = ap.parse_args()

    if args.ocr_gt and args.ocr_model:
        print(json.dumps(eval_ocr(args.ocr_kind, args.ocr_model, args.ocr_gt), indent=2))
    else:
        print("Provide --ocr-gt, --ocr-model to run OCR regression.")
