#include "ai/yolo11/postprocess.h"
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <set>
#include <vector>

inline static int clamp(float val, int min, int max) {
    return val > min ? (val < max ? val : max) : min;
}

static float CalculateOverlap(float xmin0, float ymin0, float xmax0, float ymax0,
                              float xmin1, float ymin1, float xmax1, float ymax1) {
    float x1 = fmax(xmin0, xmin1);
    float y1 = fmax(ymin0, ymin1);
    float x2 = fmin(xmax0, xmax1);
    float y2 = fmin(ymax0, ymax1);
    float w = fmax(0.0f, x2 - x1);
    float h = fmax(0.0f, y2 - y1);
    float i = w * h;
    float area0 = fmax(0.0f, xmax0 - xmin0) * fmax(0.0f, ymax0 - ymin0);
    float area1 = fmax(0.0f, xmax1 - xmin1) * fmax(0.0f, ymax1 - ymin1);
    float u = area0 + area1 - i;
    return u <= 0.0f ? 0.0f : (i / u);
}

static int nms(int validCount, std::vector<float> &outputLocations,
               const std::vector<int> &classIds, std::vector<int> &order,
               int filterId, float threshold) {
    for (int i = 0; i < validCount; ++i) {
        int n = order[i];
        if (n < 0 || (size_t)n >= classIds.size() || classIds[n] != filterId) {
            continue;
        }
        if ((size_t)n * 4 + 3 >= outputLocations.size()) {
            continue;
        }
        for (int j = i + 1; j < validCount; ++j) {
            int m = order[j];
            if (m < 0 || (size_t)m >= classIds.size() || classIds[m] != filterId) {
                continue;
            }
            if ((size_t)m * 4 + 3 >= outputLocations.size()) {
                continue;
            }
            float xmin0 = outputLocations[n * 4 + 0];
            float ymin0 = outputLocations[n * 4 + 1];
            float xmax0 = outputLocations[n * 4 + 0] + outputLocations[n * 4 + 2];
            float ymax0 = outputLocations[n * 4 + 1] + outputLocations[n * 4 + 3];

            float xmin1 = outputLocations[m * 4 + 0];
            float ymin1 = outputLocations[m * 4 + 1];
            float xmax1 = outputLocations[m * 4 + 0] + outputLocations[m * 4 + 2];
            float ymax1 = outputLocations[m * 4 + 1] + outputLocations[m * 4 + 3];

            float iou = CalculateOverlap(xmin0, ymin0, xmax0, ymax0, xmin1, ymin1, xmax1, ymax1);

            if (iou > threshold) {
                order[j] = -1;
            }
        }
    }
    return 0;
}


inline static int32_t __clip(float val, float min, float max) {
    return val <= min ? (int32_t)min : (val >= max ? (int32_t)max : (int32_t)val);
}

static int8_t qnt_f32_to_affine(float f32, int32_t zp, float scale) {
    float s = (fabsf(scale) > 1e-6f) ? scale : 1.0f;
    float dst_val = (f32 / s) + zp;
    return (int8_t)__clip(dst_val, -128, 127);
}

static uint8_t qnt_f32_to_affine_u8(float f32, int32_t zp, float scale) {
    float s = (fabsf(scale) > 1e-6f) ? scale : 1.0f;
    float dst_val = (f32 / s) + zp;
    return (uint8_t)__clip(dst_val, 0, 255);
}

static float deqnt_affine_to_f32(int8_t qnt, int32_t zp, float scale) {
    return ((float)qnt - (float)zp) * scale;
}

static float deqnt_affine_u8_to_f32(uint8_t qnt, int32_t zp, float scale) {
    return ((float)qnt - (float)zp) * scale;
}

static void compute_dfl(float* tensor, int dfl_len, float* box) {
    if (dfl_len <= 0 || dfl_len > 32) {
        dfl_len = 16;
    }
    float exp_t[32];
    int len = dfl_len;
    for (int b = 0; b < 4; b++) {
        float max_val = tensor[b * dfl_len];
        for (int i = 1; i < len; i++) {
            if (tensor[i + b * dfl_len] > max_val) {
                max_val = tensor[i + b * dfl_len];
            }
        }
        float exp_sum = 0.0f;
        float acc_sum = 0.0f;
        for (int i = 0; i < len; i++) {
            exp_t[i] = expf(tensor[i + b * dfl_len] - max_val);
            exp_sum += exp_t[i];
        }
        float inv_sum = (exp_sum > 0.0f) ? (1.0f / exp_sum) : 1.0f;
        for (int i = 0; i < len; i++) {
            acc_sum += exp_t[i] * inv_sum * i;
        }
        box[b] = acc_sum;
    }
}

static int process_u8(uint8_t *box_tensor, int32_t box_zp, float box_scale,
                      uint8_t *score_tensor, int32_t score_zp, float score_scale,
                      uint8_t *score_sum_tensor, int32_t score_sum_zp, float score_sum_scale,
                      int grid_h, int grid_w, int stride, int dfl_len, int box_channels, bool is_nhwc,
                      std::vector<float> &boxes,
                      std::vector<float> &objProbs,
                      std::vector<int> &classId,
                      float threshold, int num_classes) {
    if (dfl_len <= 0 || dfl_len > 32) {
        dfl_len = 16;
    }
    int validCount = 0;
    int grid_len = grid_h * grid_w;
    uint8_t score_thres_u8 = qnt_f32_to_affine_u8(threshold, score_zp, score_scale);
    uint8_t score_sum_thres_u8 = qnt_f32_to_affine_u8(threshold, score_sum_zp, score_sum_scale);

    for (int i = 0; i < grid_h; i++) {
        for (int j = 0; j < grid_w; j++) {
            int spatial_idx = i * grid_w + j;
            int max_class_id = -1;

            if (score_sum_tensor != nullptr) {
                if (score_sum_tensor[spatial_idx] < score_sum_thres_u8) {
                    continue;
                }
            }

            uint8_t max_score = score_thres_u8;
            if (is_nhwc) {
                int score_offset = spatial_idx * num_classes;
                for (int c = 0; c < num_classes; c++) {
                    if (score_tensor[score_offset + c] > max_score) {
                        max_score = score_tensor[score_offset + c];
                        max_class_id = c;
                    }
                }
            } else {
                for (int c = 0; c < num_classes; c++) {
                    uint8_t val = score_tensor[c * grid_len + spatial_idx];
                    if (val > max_score) {
                        max_score = val;
                        max_class_id = c;
                    }
                }
            }

            if (max_class_id >= 0) {
                float box[4] = {0};
                float before_dfl[128] = {0};
                int total_dfl = dfl_len * 4;
                if (total_dfl > 128) total_dfl = 128;
                if (box_channels > 0 && total_dfl > box_channels) total_dfl = box_channels;

                if (is_nhwc) {
                    int box_offset = spatial_idx * box_channels;
                    for (int k = 0; k < total_dfl; k++) {
                        before_dfl[k] = deqnt_affine_u8_to_f32(box_tensor[box_offset + k], box_zp, box_scale);
                    }
                } else {
                    for (int k = 0; k < total_dfl; k++) {
                        before_dfl[k] = deqnt_affine_u8_to_f32(box_tensor[k * grid_len + spatial_idx], box_zp, box_scale);
                    }
                }
                float prob = deqnt_affine_u8_to_f32(max_score, score_zp, score_scale);
                if (std::isnan(prob) || std::isinf(prob) || prob <= 0.0f) {
                    continue;
                }

                compute_dfl(before_dfl, dfl_len, box);

                float x1 = (-box[0] + j + 0.5f) * stride;
                float y1 = (-box[1] + i + 0.5f) * stride;
                float x2 = (box[2] + j + 0.5f) * stride;
                float y2 = (box[3] + i + 0.5f) * stride;
                if (std::isnan(x1) || std::isnan(y1) || std::isnan(x2) || std::isnan(y2) ||
                    std::isinf(x1) || std::isinf(y1) || std::isinf(x2) || std::isinf(y2)) {
                    continue;
                }

                boxes.push_back(x1);
                boxes.push_back(y1);
                boxes.push_back(x2 - x1);
                boxes.push_back(y2 - y1);

                objProbs.push_back(prob);
                classId.push_back(max_class_id);
                validCount++;
            }
        }
    }

    return validCount;
}

static int process_i8(int8_t *box_tensor, int32_t box_zp, float box_scale,
                      int8_t *score_tensor, int32_t score_zp, float score_scale,
                      int8_t *score_sum_tensor, int32_t score_sum_zp, float score_sum_scale,
                      int grid_h, int grid_w, int stride, int dfl_len, int box_channels, bool is_nhwc,
                      std::vector<float> &boxes,
                      std::vector<float> &objProbs,
                      std::vector<int> &classId,
                      float threshold, int num_classes) {
    if (dfl_len <= 0 || dfl_len > 32) {
        dfl_len = 16;
    }
    int validCount = 0;
    int grid_len = grid_h * grid_w;
    int8_t score_thres_i8 = qnt_f32_to_affine(threshold, score_zp, score_scale);
    int8_t score_sum_thres_i8 = qnt_f32_to_affine(threshold, score_sum_zp, score_sum_scale);

    for (int i = 0; i < grid_h; i++) {
        for (int j = 0; j < grid_w; j++) {
            int spatial_idx = i * grid_w + j;
            int max_class_id = -1;

            if (score_sum_tensor != nullptr) {
                if (score_sum_tensor[spatial_idx] < score_sum_thres_i8) {
                    continue;
                }
            }

            int8_t max_score = score_thres_i8;
            if (is_nhwc) {
                int score_offset = spatial_idx * num_classes;
                for (int c = 0; c < num_classes; c++) {
                    if (score_tensor[score_offset + c] > max_score) {
                        max_score = score_tensor[score_offset + c];
                        max_class_id = c;
                    }
                }
            } else {
                for (int c = 0; c < num_classes; c++) {
                    int8_t val = score_tensor[c * grid_len + spatial_idx];
                    if (val > max_score) {
                        max_score = val;
                        max_class_id = c;
                    }
                }
            }

            if (max_class_id >= 0) {
                float box[4] = {0};
                float before_dfl[128] = {0};
                int total_dfl = dfl_len * 4;
                if (total_dfl > 128) total_dfl = 128;
                if (box_channels > 0 && total_dfl > box_channels) total_dfl = box_channels;

                if (is_nhwc) {
                    int box_offset = spatial_idx * box_channels;
                    for (int k = 0; k < total_dfl; k++) {
                        before_dfl[k] = deqnt_affine_to_f32(box_tensor[box_offset + k], box_zp, box_scale);
                    }
                } else {
                    for (int k = 0; k < total_dfl; k++) {
                        before_dfl[k] = deqnt_affine_to_f32(box_tensor[k * grid_len + spatial_idx], box_zp, box_scale);
                    }
                }
                float prob = deqnt_affine_to_f32(max_score, score_zp, score_scale);
                if (std::isnan(prob) || std::isinf(prob) || prob <= 0.0f) {
                    continue;
                }

                compute_dfl(before_dfl, dfl_len, box);

                float x1 = (-box[0] + j + 0.5f) * stride;
                float y1 = (-box[1] + i + 0.5f) * stride;
                float x2 = (box[2] + j + 0.5f) * stride;
                float y2 = (box[3] + i + 0.5f) * stride;
                if (std::isnan(x1) || std::isnan(y1) || std::isnan(x2) || std::isnan(y2) ||
                    std::isinf(x1) || std::isinf(y1) || std::isinf(x2) || std::isinf(y2)) {
                    continue;
                }

                boxes.push_back(x1);
                boxes.push_back(y1);
                boxes.push_back(x2 - x1);
                boxes.push_back(y2 - y1);

                objProbs.push_back(prob);
                classId.push_back(max_class_id);
                validCount++;
            }
        }
    }
    return validCount;
}

static int process_fp32(float *box_tensor, float *score_tensor, float *score_sum_tensor,
                        int grid_h, int grid_w, int stride, int dfl_len, int box_channels, bool is_nhwc,
                        std::vector<float> &boxes,
                        std::vector<float> &objProbs,
                        std::vector<int> &classId,
                        float threshold, int num_classes) {
    if (dfl_len <= 0 || dfl_len > 32) {
        dfl_len = 16;
    }
    int validCount = 0;
    int grid_len = grid_h * grid_w;
    for (int i = 0; i < grid_h; i++) {
        for (int j = 0; j < grid_w; j++) {
            int spatial_idx = i * grid_w + j;
            int max_class_id = -1;

            if (score_sum_tensor != nullptr) {
                if (score_sum_tensor[spatial_idx] < threshold) {
                    continue;
                }
            }

            float max_score = threshold;
            if (is_nhwc) {
                int score_offset = spatial_idx * num_classes;
                for (int c = 0; c < num_classes; c++) {
                    if (score_tensor[score_offset + c] > max_score) {
                        max_score = score_tensor[score_offset + c];
                        max_class_id = c;
                    }
                }
            } else {
                for (int c = 0; c < num_classes; c++) {
                    float val = score_tensor[c * grid_len + spatial_idx];
                    if (val > max_score) {
                        max_score = val;
                        max_class_id = c;
                    }
                }
            }

            if (max_class_id >= 0) {
                float box[4] = {0};
                float before_dfl[128] = {0};
                int total_dfl = dfl_len * 4;
                if (total_dfl > 128) total_dfl = 128;
                if (box_channels > 0 && total_dfl > box_channels) total_dfl = box_channels;

                if (is_nhwc) {
                    int box_offset = spatial_idx * box_channels;
                    for (int k = 0; k < total_dfl; k++) {
                        before_dfl[k] = box_tensor[box_offset + k];
                    }
                } else {
                    for (int k = 0; k < total_dfl; k++) {
                        before_dfl[k] = box_tensor[k * grid_len + spatial_idx];
                    }
                }
                float prob = max_score;
                if (std::isnan(prob) || std::isinf(prob) || prob <= 0.0f) {
                    continue;
                }

                compute_dfl(before_dfl, dfl_len, box);

                float x1 = (-box[0] + j + 0.5f) * stride;
                float y1 = (-box[1] + i + 0.5f) * stride;
                float x2 = (box[2] + j + 0.5f) * stride;
                float y2 = (box[3] + i + 0.5f) * stride;
                if (std::isnan(x1) || std::isnan(y1) || std::isnan(x2) || std::isnan(y2) ||
                    std::isinf(x1) || std::isinf(y1) || std::isinf(x2) || std::isinf(y2)) {
                    continue;
                }

                boxes.push_back(x1);
                boxes.push_back(y1);
                boxes.push_back(x2 - x1);
                boxes.push_back(y2 - y1);

                objProbs.push_back(prob);
                classId.push_back(max_class_id);
                validCount++;
            }
        }
    }
    return validCount;
}

int post_process(rknn_app_context_t *app_ctx, void *outputs, letterbox_t *letter_box,
                 float conf_threshold, float nms_threshold, object_detect_result_list *od_results) {
    if (!app_ctx || !outputs || !od_results) {
        return -1;
    }
    if (app_ctx->io_num.n_output < 6 || !app_ctx->output_attrs) {
        return -1;
    }
    if (app_ctx->model_width <= 0 || app_ctx->model_height <= 0) {
        return -1;
    }
    int output_per_branch = app_ctx->io_num.n_output / 3;
    if (output_per_branch < 2) {
        return -1;
    }
    rknn_output *_outputs = (rknn_output *)outputs;
    std::vector<float> filterBoxes;
    std::vector<float> objProbs;
    std::vector<int> classId;
    filterBoxes.reserve(512);
    objProbs.reserve(128);
    classId.reserve(128);
    int validCount = 0;
    int stride = 0;
    int grid_h = 0;
    int grid_w = 0;
    int model_in_w = app_ctx->model_width;
    int model_in_h = app_ctx->model_height;

    memset(od_results, 0, sizeof(object_detect_result_list));

    for (int i = 0; i < 3; i++) {
        int box_idx = i * output_per_branch;
        int score_idx = i * output_per_branch + 1;
        if (!_outputs[box_idx].buf || !_outputs[score_idx].buf) {
            continue;
        }

        int box_channels = 0;
        int num_classes = 0;
        bool is_nhwc = false;
#ifdef RKNPU1
        box_channels = app_ctx->output_attrs[box_idx].dims[2];
        grid_h = app_ctx->output_attrs[box_idx].dims[1];
        grid_w = app_ctx->output_attrs[box_idx].dims[0];
        num_classes = app_ctx->output_attrs[score_idx].dims[2];
#else
        if (app_ctx->output_attrs[box_idx].n_dims == 3) {
            if (app_ctx->output_attrs[box_idx].fmt == RKNN_TENSOR_NHWC ||
                app_ctx->output_attrs[box_idx].dims[2] == 64 ||
                (app_ctx->output_attrs[box_idx].dims[2] % 4 == 0 && app_ctx->output_attrs[box_idx].dims[0] != 64)) {
                is_nhwc = true;
                grid_h = app_ctx->output_attrs[box_idx].dims[0];
                grid_w = app_ctx->output_attrs[box_idx].dims[1];
                box_channels = app_ctx->output_attrs[box_idx].dims[2];
            } else {
                is_nhwc = false;
                box_channels = app_ctx->output_attrs[box_idx].dims[0];
                grid_h = app_ctx->output_attrs[box_idx].dims[1];
                grid_w = app_ctx->output_attrs[box_idx].dims[2];
            }
        } else {
            if (app_ctx->output_attrs[box_idx].fmt == RKNN_TENSOR_NHWC ||
                (app_ctx->output_attrs[box_idx].n_dims == 4 && app_ctx->output_attrs[box_idx].dims[3] == 64 && app_ctx->output_attrs[box_idx].dims[1] != 64)) {
                is_nhwc = true;
                grid_h = app_ctx->output_attrs[box_idx].dims[1];
                grid_w = app_ctx->output_attrs[box_idx].dims[2];
                box_channels = app_ctx->output_attrs[box_idx].dims[3];
            } else {
                is_nhwc = false;
                box_channels = app_ctx->output_attrs[box_idx].dims[1];
                grid_h = app_ctx->output_attrs[box_idx].dims[2];
                grid_w = app_ctx->output_attrs[box_idx].dims[3];
            }
        }

        uint32_t score_ndims = app_ctx->output_attrs[score_idx].n_dims;
        if (is_nhwc) {
            num_classes = (score_ndims > 0) ? app_ctx->output_attrs[score_idx].dims[score_ndims - 1] : 0;
        } else {
            num_classes = (score_ndims == 4) ? app_ctx->output_attrs[score_idx].dims[1] :
                          ((score_ndims == 3) ? app_ctx->output_attrs[score_idx].dims[0] : 0);
        }
#endif
        if (box_channels < 4 || grid_h <= 0 || grid_w <= 0 || num_classes <= 0) {
            continue;
        }

        int dfl_len = box_channels / 4;
        if (dfl_len <= 0 || dfl_len > 32) {
            dfl_len = 16;
        }
        if (dfl_len * 4 > box_channels) {
            dfl_len = box_channels / 4;
        }

        stride = model_in_h / grid_h;
        if (stride <= 0) {
            stride = 1;
        }

        void *score_sum = nullptr;
        int32_t score_sum_zp = 0;
        float score_sum_scale = 1.0f;
        if (output_per_branch >= 3) {
            int score_sum_idx = i * output_per_branch + 2;
            if (score_sum_idx < (int)app_ctx->io_num.n_output) {
                uint32_t se = app_ctx->output_attrs[score_sum_idx].n_elems;
                if (se == 0 && app_ctx->output_attrs[score_sum_idx].n_dims > 0) {
                    se = 1;
                    for (uint32_t d = 0; d < app_ctx->output_attrs[score_sum_idx].n_dims; ++d) {
                        if (app_ctx->output_attrs[score_sum_idx].dims[d] > 0) {
                            se *= app_ctx->output_attrs[score_sum_idx].dims[d];
                        }
                    }
                }
                if (se >= (uint32_t)(grid_h * grid_w)) {
                    score_sum = _outputs[score_sum_idx].buf;
                    score_sum_zp = app_ctx->output_attrs[score_sum_idx].zp;
                    score_sum_scale = app_ctx->output_attrs[score_sum_idx].scale;
                }
            }
        }

        if (app_ctx->is_quant) {
            if (app_ctx->output_attrs[box_idx].type == RKNN_TENSOR_UINT8) {
                validCount += process_u8((uint8_t *)_outputs[box_idx].buf, app_ctx->output_attrs[box_idx].zp, app_ctx->output_attrs[box_idx].scale,
                                         (uint8_t *)_outputs[score_idx].buf, app_ctx->output_attrs[score_idx].zp, app_ctx->output_attrs[score_idx].scale,
                                         (uint8_t *)score_sum, score_sum_zp, score_sum_scale,
                                         grid_h, grid_w, stride, dfl_len, box_channels, is_nhwc,
                                         filterBoxes, objProbs, classId, conf_threshold, num_classes);
            } else {
                validCount += process_i8((int8_t *)_outputs[box_idx].buf, app_ctx->output_attrs[box_idx].zp, app_ctx->output_attrs[box_idx].scale,
                                         (int8_t *)_outputs[score_idx].buf, app_ctx->output_attrs[score_idx].zp, app_ctx->output_attrs[score_idx].scale,
                                         (int8_t *)score_sum, score_sum_zp, score_sum_scale,
                                         grid_h, grid_w, stride, dfl_len, box_channels, is_nhwc,
                                         filterBoxes, objProbs, classId, conf_threshold, num_classes);
            }
        } else {
            validCount += process_fp32((float *)_outputs[box_idx].buf, (float *)_outputs[score_idx].buf, (float *)score_sum,
                                       grid_h, grid_w, stride, dfl_len, box_channels, is_nhwc,
                                       filterBoxes, objProbs, classId, conf_threshold, num_classes);
        }
    }

    if (validCount <= 0) {
        return 0;
    }
    std::vector<int> indexArray(validCount);
    for (int i = 0; i < validCount; ++i) {
        indexArray[i] = i;
    }
    auto comp = [&](int a, int b) {
        if (objProbs[a] != objProbs[b]) {
            return objProbs[a] > objProbs[b];
        }
        return a < b;
    };
    if (validCount > 1024) {
        std::partial_sort(indexArray.begin(), indexArray.begin() + 1024, indexArray.end(), comp);
        validCount = 1024;
        indexArray.resize(validCount);
    } else {
        std::sort(indexArray.begin(), indexArray.end(), comp);
    }

    std::set<int> class_set(std::begin(classId), std::end(classId));
    for (auto c : class_set) {
        nms(validCount, filterBoxes, classId, indexArray, c, nms_threshold);
    }

    int last_count = 0;
    od_results->count = 0;
    float scale = 1.0f;
    float x_pad = 0.0f;
    float y_pad = 0.0f;
    if (letter_box) {
        scale = (letter_box->scale > 0.0001f) ? letter_box->scale : 1.0f;
        x_pad = letter_box->x_pad;
        y_pad = letter_box->y_pad;
    }

    for (int i = 0; i < validCount; ++i) {
        if (indexArray[i] == -1 || last_count >= OBJ_NUMB_MAX_SIZE) {
            continue;
        }
        int n = indexArray[i];
        if (n < 0 || (size_t)n >= classId.size() || (size_t)n * 4 + 3 >= filterBoxes.size()) {
            continue;
        }

        float x1 = filterBoxes[n * 4 + 0] - x_pad;
        float y1 = filterBoxes[n * 4 + 1] - y_pad;
        float x2 = x1 + filterBoxes[n * 4 + 2];
        float y2 = y1 + filterBoxes[n * 4 + 3];
        int id = classId[n];
        float obj_conf = objProbs[n];

        float inv_scale = (scale > 0.0001f) ? (1.0f / scale) : 1.0f;
        int left = (int)(fmax(0.0f, x1) * inv_scale);
        int top = (int)(fmax(0.0f, y1) * inv_scale);
        int right = (int)(fmax(0.0f, x2) * inv_scale);
        int bottom = (int)(fmax(0.0f, y2) * inv_scale);
        if (right < left) right = left;
        if (bottom < top) bottom = top;

        od_results->results[last_count].box.left = left;
        od_results->results[last_count].box.top = top;
        od_results->results[last_count].box.right = right;
        od_results->results[last_count].box.bottom = bottom;
        od_results->results[last_count].prop = obj_conf;
        od_results->results[last_count].cls_id = id;
        last_count++;
    }
    od_results->count = last_count;
    return 0;
}
