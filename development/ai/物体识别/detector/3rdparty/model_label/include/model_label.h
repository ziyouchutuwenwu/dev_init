#ifndef MODEL_LABEL_H
#define MODEL_LABEL_H

#ifdef __cplusplus
extern "C" {
#endif

const char* const* get_model_labels_list(const char* model_id);
const char* get_model_desc(const char* model_id);

#ifdef __cplusplus
}
#endif

#endif
