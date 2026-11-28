#ifndef AI_REGISTER_H
#define AI_REGISTER_H

class InferManager;

void bind_model_files(InferManager& manager);
void register_groups(InferManager& manager);
void register_models(InferManager& manager);

inline void bind_model_id(InferManager& manager) {
    bind_model_files(manager);
}

inline void register_single_model(InferManager& manager) {
    register_groups(manager);
}

inline void register_serial_model(InferManager& manager) {
}

#endif
