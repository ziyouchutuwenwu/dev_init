#ifndef MODEL_MEMORY_H
#define MODEL_MEMORY_H

#include <cstdint>
#include <cstddef>

struct ModelMemory {
    uint8_t* data = nullptr;
    size_t size = 0;
    bool is_encrypted_mem = false;

    ModelMemory() = default;
    ~ModelMemory();

    ModelMemory(const ModelMemory&) = delete;
    ModelMemory& operator=(const ModelMemory&) = delete;

    ModelMemory(ModelMemory&& other) noexcept;
    ModelMemory& operator=(ModelMemory&& other) noexcept;

    void release();
};

#endif
