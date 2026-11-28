#ifndef DETECT_CLI_H
#define DETECT_CLI_H

#ifdef __cplusplus
extern "C" {
#endif

int detect_file(const char* image_path, const char* out_json_path, const char* out_image_path);
int detect_file_with_model(const char* image_path, const char* out_json_path, const char* out_image_path, const char* model_id);

#ifdef __cplusplus
}
#endif

#endif
