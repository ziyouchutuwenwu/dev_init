#ifndef AI_REGISTER_H
#define AI_REGISTER_H

class InferManager;
using ModelManager = InferManager;

void register_single_infers(InferManager& manager);
void register_pipelines(InferManager& manager);
void register_models(InferManager& manager);

inline void register_single_models(InferManager& manager) { register_single_infers(manager); }
inline void register_cascade_models(InferManager& manager) { register_pipelines(manager); }

#endif // AI_REGISTER_H
