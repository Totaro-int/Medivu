"""
Create a calibration list file for TFLite int8 conversion.
It scans a directory and picks diverse samples.
"""
import argparse, random
from pathlib import Path

def build_list(img_dir, out_txt, limit=1000, exts=(".jpg",".jpeg",".png",".bmp")):
    imgs = [p for p in Path(img_dir).rglob("*") if p.suffix.lower() in exts]
    # Simple diversity via random sampling; replace with stratified logic if labels exist.
    random.shuffle(imgs)
    imgs = imgs[:limit]
    with open(out_txt, "w") as f:
        for p in imgs:
            f.write(str(p.resolve()) + "\n")
    print(f"Wrote {len(imgs)} calibration paths to {out_txt}")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--img-dir", required=True)
    ap.add_argument("--out", default="calib_list.txt")
    ap.add_argument("--limit", type=int, default=1000)
    args = ap.parse_args()
    build_list(args.img_dir, args.out, args.limit)
