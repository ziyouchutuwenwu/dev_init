import json
import os
import argparse

def convert_bbox_coco_to_yolo(size, bbox):
    dw = 1.0 / size[0]
    dh = 1.0 / size[1]
    x_center = bbox[0] + bbox[2] / 2.0
    y_center = bbox[1] + bbox[3] / 2.0
    w = bbox[2]
    h = bbox[3]
    return x_center * dw, y_center * dh, w * dw, h * dh

def convert_coco_json_to_yolo_labels(json_path, labels_dir):
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    images = {img['id']: img for img in data['images']}
    categories = {cat['id']: idx for idx, cat in enumerate(data['categories'])}

    os.makedirs(labels_dir, exist_ok=True)
    labels_dict = {}

    for ann in data['annotations']:
        image_id = ann['image_id']
        if image_id not in images:
            continue
        img_info = images[image_id]
        w, h = img_info['width'], img_info['height']
        bbox = ann['bbox']
        category_id = ann['category_id']
        if category_id not in categories:
            continue
        class_id = categories[category_id]
        yolo_bbox = convert_bbox_coco_to_yolo((w, h), bbox)
        line = f"{class_id} {' '.join(f'{x:.6f}' for x in yolo_bbox)}\n"

        label_filename = os.path.splitext(img_info['file_name'])[0] + '.txt'
        labels_dict.setdefault(label_filename, []).append(line)

    for filename, lines in labels_dict.items():
        with open(os.path.join(labels_dir, filename), 'w', encoding='utf-8') as f:
            f.writelines(lines)

    print(f"[✓] 转换完成，共生成 {len(labels_dict)} 个标签文件 -> {labels_dir}")

def main():
    parser = argparse.ArgumentParser(description="Convert COCO JSON to YOLO label format")
    parser.add_argument("--json", required=True, help="Path to COCO JSON annotation file")
    parser.add_argument("--out", required=True, help="Output directory for YOLO label files")
    args = parser.parse_args()

    convert_coco_json_to_yolo_labels(args.json, args.out)

if __name__ == "__main__":
    main()