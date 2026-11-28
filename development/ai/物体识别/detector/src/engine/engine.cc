#include "engine/engine.h"
#include "channel/channel_manager.h"
#include "hardware/channel_decoder.h"
#include "hardware/npu_infer.h"
#include <cstdio>

Engine& Engine::instance() {
    static Engine s_instance;
    return s_instance;
}

Engine::~Engine() {
    deinit();
}

int Engine::init() {
    if (_inited) {
        return 0;
    }
    if (!NpuInfer::shareInstance().init_engine()) {
        fprintf(stderr, "[engine] npu 初始化失败, ai 检测功能暂不可用\n");
    } else {
        printf("[engine] 引擎与模型加载成功并就绪\n");
        fflush(stdout);
    }
    _inited = true;
    return 0;
}

bool Engine::is_infer_ready() const {
    if (!NpuInfer::shareInstance().is_ready()) {
        if (const_cast<Engine*>(this)->try_restore_engine()) {
            return true;
        }
        return false;
    }
    return true;
}

bool Engine::try_restore_engine() {
    if (!NpuInfer::shareInstance().is_ready()) {
        if (NpuInfer::shareInstance().init_engine()) {
            printf("[engine] npu 引擎已成功激活并就绪\n");
            return true;
        }
    }
    return false;
}

int Engine::deinit() {
    if (!_inited) {
        return 0;
    }
    NpuInfer::shareInstance().deinit_engine();
    ChannelManager::instance().release_all();
    ChannelDecoder::shareInstance().release_all();
    _inited = false;
    return 0;
}
