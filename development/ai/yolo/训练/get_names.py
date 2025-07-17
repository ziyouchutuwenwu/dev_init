import json
import argparse

def get_names_list_from_coco_json(json_path):
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    categories = {cat['id']: idx for idx, cat in enumerate(data['categories'])}
    names_list = [None] * len(categories)
    for cat in data['categories']:
        yolo_id = categories[cat['id']]
        names_list[yolo_id] = cat['name']
    return names_list

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate YOLO names list from COCO JSON")
    parser.add_argument('--json', required=True, help="Path to COCO JSON annotation file")
    args = parser.parse_args()

    names = get_names_list_from_coco_json(args.json)
    print("names:")
    for name in names:
        print(f"  - {name}")
