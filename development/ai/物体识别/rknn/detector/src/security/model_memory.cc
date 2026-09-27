#include "security/model_memory.h"
#include "security/switcher.h"
#include "model_license.h"
#include <cstdlib>

ModelMemory::~ModelMemory() {
    release();
}

void ModelMemory::release() {
    if (data) {
#if ENABLE_SECURITY
        if (is_encrypted_mem) {
            free_model_memory(data, size);
        } else {
            free(data);
        }
#else
        free(data);
#endif
        data = nullptr;
        size = 0;
        is_encrypted_mem = false;
    }
}

ModelMemory::ModelMemory(ModelMemory&& other) noexcept {
    data = other.data;
    size = other.size;
    is_encrypted_mem = other.is_encrypted_mem;
    other.data = nullptr;
    other.size = 0;
    other.is_encrypted_mem = false;
}

ModelMemory& ModelMemory::operator=(ModelMemory&& other) noexcept {
    if (this != &other) {
        release();
        data = other.data;
        size = other.size;
        is_encrypted_mem = other.is_encrypted_mem;
        other.data = nullptr;
        other.size = 0;
        other.is_encrypted_mem = false;
    }
    return *this;
}
