#include "detect_cli.h"
#include "hardware/npu_infer.h"
#include "ai/pipeline/detect_result.h"
#include "security/license_validator.h"
#include "image_utils.h"
#include "image_drawing.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <string>

int detect_file(const char* image_path, const char* out_json_path, const char* out_image_path) {
    if (!image_path) return -1;

    if (!LicenseValidator::instance().verify_license()) {
        fprintf(stderr, "授权校验未通过，拒绝执行检测！\n");
        return -1;
    }

    image_buffer_t img;
    memset(&img, 0, sizeof(image_buffer_t));
    if (read_image(image_path, &img) != 0) {
        fprintf(stderr, "failed to read input image: %s\n", image_path);
        return -1;
    }

    struct ImgGuard {
        image_buffer_t* m_img;
        ~ImgGuard() {
            if (m_img && m_img->virt_addr) {
                free(m_img->virt_addr);
                m_img->virt_addr = nullptr;
            }
        }
    } img_guard{&img};

    DetectResult results;

    if (!NpuInfer::shareInstance().infer(img, results)) {
        return -1;
    }

    std::string json;
    json.reserve(2048);
    char tmp[512];

    snprintf(tmp, sizeof(tmp), "{\"frame_width\": %d, \"frame_height\": %d, \"detections\": [",
             img.width, img.height);
    json.append(tmp);

    for (size_t i = 0; i < results.objects.size(); i++) {
        const auto& obj = results.objects[i];
        snprintf(tmp, sizeof(tmp),
            "%s{\"class_id\": %d, \"label\": \"%s\", \"confidence\": %.2f, \"rel_box\": [%.4f, %.4f, %.4f, %.4f], \"box\": [%d, %d, %d, %d]}",
            (i > 0 ? ", " : ""),
            obj.class_id, obj.label.c_str(), obj.score,
            obj.rel_box[0], obj.rel_box[1], obj.rel_box[2], obj.rel_box[3],
            obj.box[0], obj.box[1], obj.box[2], obj.box[3]
        );
        json.append(tmp);
    }
    json.append("]}");

    printf("targets: %zu, json: %s\n", results.objects.size(), json.c_str());

    if (out_json_path && out_json_path[0] != '\0') {
        FILE* fp = fopen(out_json_path, "w");
        if (fp) {
            fputs(json.c_str(), fp);
            fclose(fp);
            printf("json results saved to: %s\n", out_json_path);
        }
    }

    if (out_image_path && out_image_path[0] != '\0') {
        char text[256];
        for (size_t i = 0; i < results.objects.size(); i++) {
            const auto& det = results.objects[i];
            int x1 = det.box[0];
            int y1 = det.box[1];
            int x2 = det.box[2];
            int y2 = det.box[3];
            int w = (x2 > x1) ? (x2 - x1) : 0;
            int h = (y2 > y1) ? (y2 - y1) : 0;
            if (w > 0 && h > 0) {
                draw_rectangle(&img, x1, y1, w, h, COLOR_GREEN, 3);
            }
            int ty = y1 - 20;
            if (ty < 0) ty = y1 + 5;
            snprintf(text, sizeof(text), "%s %.1f%%", det.label.c_str(), det.score * 100.0f);
            draw_text(&img, text, x1, ty, COLOR_RED, 10);
        }
        write_image(out_image_path, &img);
        printf("annotated result image saved to: %s\n", out_image_path);
    }

    return (int)results.objects.size();
}

void print_help(const char* prog) {
    printf("=========================================================================\n");
    printf("  hardware detection cli utility\n");
    printf("=========================================================================\n");
    printf("usage:\n");
    printf("  %s <input_image> [output_image] [output_json]\n\n", prog);
    printf("arguments:\n");
    printf("  input_image   path to input image (.jpg / .png / .data) [required]\n");
    printf("  output_image  path to save annotated box image (default: ./result.jpg)\n");
    printf("  output_json   path to save detection json (default: ./result.json)\n\n");
    printf("examples:\n");
    printf("  %s /model/bus.jpg\n", prog);
    printf("  %s ./frame.jpg ./result.jpg ./result.json\n", prog);
    printf("=========================================================================\n");
}

int main(int argc, char* argv[]) {
    if (argc < 2 || strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0) {
        print_help(argv[0]);
        return (argc < 2 ? 1 : 0);
    }

    const char* image_path = argv[1];
    const char* out_image  = (argc > 2) ? argv[2] : "./result.jpg";
    const char* out_json   = (argc > 3) ? argv[3] : "./result.json";

    if (access(image_path, R_OK) != 0) {
        fprintf(stderr, "cannot access input image: %s\n", image_path);
        return 1;
    }

    printf("=========================================================\n");
    printf("  hardware detection running...\n");
    printf("=========================================================\n");
    printf("  • input image   : %s\n", image_path);
    printf("  • output image  : %s\n", out_image);
    printf("  • output json   : %s\n", out_json);
    printf("=========================================================\n\n");

    int ret = detect_file(image_path, out_json, out_image);
    NpuInfer::shareInstance().deinit_engine();

    if (ret >= 0) {
        printf("\n>>> detection completed. result image and json generated.\n");
    } else {
        printf("\n>>> detection failed (code: %d).\n", ret);
    }
    return (ret >= 0 ? 0 : 1);
}
