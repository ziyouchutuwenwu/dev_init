#include "engine/engine.h"
#include "channel/channel_manager.h"
#include "hardware/channel_decoder.h"
#include "hardware/npu_infer.h"
#include "security/license_validator.h"
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
    bool lic_ok = LicenseValidator::instance().verify_license();
    LicenseValidator::instance().start_monitor();

    if (lic_ok) {
        if (!NpuInfer::shareInstance().init_engine()) {
            fprintf(stderr, "[engine] npu 初始化失败, ai 检测功能暂不可用\n");
        } else {
            printf("[engine] 引擎与模型加载成功并就绪\n");
            fflush(stdout);
        }
    } else {
        fprintf(stderr, "[engine] 授权验证失败，未能加载模型\n");
    }
    _inited = true;
    return 0;
}

bool Engine::is_infer_ready() const {
    if (!LicenseValidator::instance().is_licensed()) {
        return false;
    }
    if (!NpuInfer::shareInstance().is_ready()) {
        if (const_cast<Engine*>(this)->try_restore_engine()) {
            return true;
        }
        return false;
    }
    return true;
}

bool Engine::try_restore_engine() {
    if (LicenseValidator::instance().is_licensed() && !NpuInfer::shareInstance().is_ready()) {
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
    LicenseValidator::instance().stop_monitor();
    ChannelManager::instance().release_all();
    ChannelDecoder::shareInstance().release_all();
    NpuInfer::shareInstance().deinit_engine();
    _inited = false;
    return 0;
}
