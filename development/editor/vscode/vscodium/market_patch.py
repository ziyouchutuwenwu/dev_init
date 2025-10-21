#!/usr/bin/env python3

import json
import sys
import os
from pathlib import Path

prog = Path(sys.argv[0]).name

if len(sys.argv) != 2:
    print(f"用法: {prog} /xxx/xxx/product.json", file=sys.stderr)
    sys.exit(1)

product_path = Path(sys.argv[1]).expanduser().resolve()

if not product_path.is_file():
    print(f"错误: 指定的路径不存在或不是文件: {product_path}", file=sys.stderr)
    sys.exit(2)

new_gallery = {
    "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
    "itemUrl": "https://marketplace.visualstudio.com/items"
}

try:
    with open(product_path, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception as e:
    print(f"无法读取 {product_path}: {e}", file=sys.stderr)
    sys.exit(3)

data["extensionsGallery"] = new_gallery

try:
    with open(product_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"已更新 {product_path}")
except Exception as e:
    print(f"写入失败: {e}", file=sys.stderr)
    sys.exit(4)
