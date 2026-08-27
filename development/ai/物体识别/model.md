# model

## 说明

模型转换

## 代码

export_onnx.py

```python
#!/usr/bin/env python3

import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="Export YOLOv8 PyTorch (.pt) model to ONNX for RKNN conversion")
    parser.add_argument("--weights", type=str, default="yolov8n.pt", help="Path to PyTorch .pt weights file (default: yolov8n.pt)")
    parser.add_argument("--imgsz", type=int, default=640, help="Input image size (default: 640)")
    parser.add_argument("--opset", type=int, default=12, help="ONNX opset version (default: 12)")
    args = parser.parse_args()

    try:
        from ultralytics import YOLO
    except ImportError:
        print("[ERROR] ultralytics not installed. Please run: pip install ultralytics onnx")
        sys.exit(1)

    print(f"--> Loading PyTorch model from: {args.weights}")
    model = YOLO(args.weights)

    print(f"--> Exporting to ONNX format (imgsz={args.imgsz}, opset={args.opset})...")
    output_path = model.export(format="onnx", imgsz=args.imgsz, opset=args.opset)
    print(f"--> [SUCCESS] ONNX model exported successfully: {output_path}")

if __name__ == "__main__":
    main()
```

convert_to_rknn.py

```python
#!/usr/bin/env python3

import argparse
import os
import sys

def main():
    parser = argparse.ArgumentParser(description="Convert ONNX model to Rockchip RKNN (.rknn) format")
    parser.add_argument("--onnx", type=str, default="yolov8n.onnx", help="Path to input ONNX model (default: yolov8n.onnx)")
    parser.add_argument("--output", type=str, default="../model/yolov8.rknn", help="Path to output .rknn model (default: ../model/yolov8.rknn)")
    parser.add_argument("--target_platform", type=str, default="rk3576", choices=["rk3576", "rk3588", "rk3568", "rk3566", "rv1106", "rv1103"], help="Target SoC platform (default: rk3576)")
    parser.add_argument("--quantize", action="store_true", help="Enable INT8 quantization (requires --dataset)")
    parser.add_argument("--dataset", type=str, default=None, help="Path to dataset.txt for quantization calibration")
    args = parser.parse_args()

    if not os.path.exists(args.onnx):
        print(f"[ERROR] Input ONNX file not found: {args.onnx}")
        sys.exit(1)

    if args.quantize and not args.dataset:
        print("[WARNING] Quantization enabled (--quantize) but no --dataset provided. Looking for dataset.txt...")
        if os.path.exists("dataset.txt"):
            args.dataset = "dataset.txt"
        else:
            print("[ERROR] Quantization requires --dataset <path_to_dataset.txt> with calibration image paths.")
            sys.exit(1)

    try:
        from rknn.api import RKNN
    except ImportError:
        print("[ERROR] rknn-toolkit2 is not installed!")
        print("Please install it on PC (x86 Linux): pip install rknn-toolkit2")
        sys.exit(1)

    print("=========================================================================")
    print("  RKNN Model Converter (rknn-toolkit2)")
    print("=========================================================================")
    print(f"  • Input ONNX       : {args.onnx}")
    print(f"  • Output RKNN      : {args.output}")
    print(f"  • Target Platform  : {args.target_platform}")
    print(f"  • Quantization     : {'INT8 (Quantized)' if args.quantize else 'FP16 (Non-quantized)'}")
    if args.quantize:
        print(f"  • Dataset File     : {args.dataset}")
    print("=========================================================================\n")

    rknn = RKNN(verbose=True)

    print("--> 1. Configuring model...")
    rknn.config(
        mean_values=[[0, 0, 0]],
        std_values=[[255, 255, 255]],
        target_platform=args.target_platform,
        optimization_level=3
    )

    print(f"--> 2. Loading ONNX model from: {args.onnx}")
    ret = rknn.load_onnx(model=args.onnx)
    if ret != 0:
        print(f"[ERROR] Failed to load ONNX model (code: {ret})")
        sys.exit(ret)

    print("--> 3. Building RKNN model...")
    ret = rknn.build(do_quantization=args.quantize, dataset=args.dataset)
    if ret != 0:
        print(f"[ERROR] Failed to build RKNN model (code: {ret})")
        sys.exit(ret)

    output_dir = os.path.dirname(args.output)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir, exist_ok=True)

    print(f"--> 4. Exporting RKNN model to: {args.output}")
    ret = rknn.export_rknn(args.output)
    if ret != 0:
        print(f"[ERROR] Failed to export RKNN model (code: {ret})")
        sys.exit(ret)

    print("\n=========================================================================")
    print(f">>> [SUCCESS] RKNN model exported: {args.output}")
    print("=========================================================================")
    rknn.release()

if __name__ == "__main__":
    main()
```
