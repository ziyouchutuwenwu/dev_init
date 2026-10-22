#include "hardware/npu_worker_pool.h"
#include "hardware/npu_infer.h"
#include "rknn_api.h"
#include <cstdio>
#include <cstring>
#include <chrono>

NpuWorkerPool& NpuWorkerPool::instance() {
    static NpuWorkerPool pool;
    return pool;
}

NpuWorkerPool::NpuWorkerPool() = default;

NpuWorkerPool::~NpuWorkerPool() {
    shutdown();
}

int NpuWorkerPool::worker_count() const {
    return static_cast<int>(_workers.size());
}

bool NpuWorkerPool::init(std::shared_ptr<InferManager> master_manager, int core_count) {
    std::lock_guard<std::recursive_mutex> lock(_pool_mutex);
    if (_is_initialized.load()) {
        return true;
    }
    if (!master_manager || !master_manager->is_initialized()) {
        return false;
    }

    if (core_count <= 0) {
        core_count = NpuInfer::detect_npu_core_num();
    }
    if (core_count <= 0) {
        core_count = 1;
    }

    std::vector<uint32_t> core_masks;
    if (core_count == 3) {
        core_masks = {RKNN_NPU_CORE_0, RKNN_NPU_CORE_1, RKNN_NPU_CORE_2};
    } else if (core_count == 2) {
        core_masks = {RKNN_NPU_CORE_0, RKNN_NPU_CORE_1};
    } else {
        core_masks = {RKNN_NPU_CORE_AUTO};
    }

    _running.store(true);
    _workers.resize(core_masks.size());

    for (size_t i = 0; i < core_masks.size(); ++i) {
        _workers[i].id = static_cast<int>(i);
        _workers[i].core_mask = core_masks[i];
        _workers[i].manager = master_manager->clone(core_masks[i]);
        if (!_workers[i].manager) {
            shutdown();
            return false;
        }
        _workers[i].thread = std::thread(&NpuWorkerPool::worker_loop, this, _workers[i].id, _workers[i].core_mask, _workers[i].manager);
    }

    _is_initialized.store(true);
    printf("[NpuWorkerPool] 初始化完成: 启动 %zu 个核心工作线程 (硬件核心数: %d)\n", _workers.size(), core_count);
    fflush(stdout);
    return true;
}

void NpuWorkerPool::shutdown() {
    std::lock_guard<std::recursive_mutex> lock(_pool_mutex);
    if (!_is_initialized.load() && !_running.load()) {
        return;
    }

    _running.store(false);
    _cv.notify_all();

    for (auto& w : _workers) {
        if (w.thread.joinable()) {
            w.thread.join();
        }
        if (w.manager) {
            w.manager->release();
            w.manager.reset();
        }
    }
    _workers.clear();

    std::vector<InferTask> remaining_tasks;
    {
        std::lock_guard<std::mutex> q_lock(_queue_mutex);
        while (!_queue.empty()) {
            remaining_tasks.push_back(std::move(_queue.front()));
            _queue.pop();
        }
    }
    for (auto& t : remaining_tasks) {
        if (t.callback) {
            DetectResult empty_res;
            t.callback(t.channel_id, t.frame ? t.frame->frame_idx : 0, t.frame ? t.frame->pts_ms : 0, 0, 0, empty_res);
        }
    }

    _is_initialized.store(false);
}

bool NpuWorkerPool::push_task(InferTask task) {
    if (!_running.load() || !_is_initialized.load()) {
        return false;
    }
    InferTask dropped;
    bool has_dropped = false;
    {
        std::lock_guard<std::mutex> lock(_queue_mutex);
        if (_queue.size() > 64) {
            dropped = std::move(_queue.front());
            _queue.pop();
            has_dropped = true;
        }
        _queue.push(std::move(task));
    }
    if (has_dropped && dropped.callback) {
        DetectResult empty_res;
        dropped.callback(dropped.channel_id, dropped.frame ? dropped.frame->frame_idx : 0, dropped.frame ? dropped.frame->pts_ms : 0, 0, 0, empty_res);
    }
    _cv.notify_one();
    return true;
}

void NpuWorkerPool::worker_loop(int worker_id, uint32_t core_mask, std::shared_ptr<InferManager> manager) {
    (void)core_mask;
    while (_running.load()) {
        InferTask task;
        {
            std::unique_lock<std::mutex> lock(_queue_mutex);
            _cv.wait(lock, [this] {
                return !_running.load() || !_queue.empty();
            });
            if (!_running.load() && _queue.empty()) {
                break;
            }
            if (_queue.empty()) {
                continue;
            }
            task = std::move(_queue.front());
            _queue.pop();
        }

        if (!task.frame || (task.frame->dma_fd < 0 && task.frame->data.empty()) || !manager || !manager->is_initialized()) {
            if (task.callback) {
                DetectResult empty_res;
                task.callback(task.channel_id, task.frame ? task.frame->frame_idx : 0, task.frame ? task.frame->pts_ms : 0, 0, 0, empty_res);
            }
            task.frame.reset();
            continue;
        }

        auto target_model = manager->get_model(task.model_name);
        if (!target_model || !target_model->is_initialized()) {
            static std::atomic<int> s_warn_cnt{0};
            if (++s_warn_cnt % 30 == 1) {
                fprintf(stderr, "[NpuWorkerPool:Worker-%d] 警告: 通道 %d 请求的模型 [%s] 未就绪或未加载\n",
                        worker_id, task.channel_id, task.model_name.c_str());
            }
        }
        if (!target_model || !target_model->is_initialized()) {
            if (task.callback) {
                DetectResult empty_res;
                task.callback(task.channel_id, task.frame ? task.frame->frame_idx : 0, task.frame ? task.frame->pts_ms : 0, 0, 0, empty_res);
            }
            task.frame.reset();
            continue;
        }

        void* in_buf = target_model->input_buf();
        int in_w = target_model->model_width();
        int in_h = target_model->model_height();
        int in_c = target_model->model_channel();
        if (!in_buf || in_w <= 0 || in_h <= 0) {
            if (task.callback) {
                DetectResult empty_res;
                task.callback(task.channel_id, task.frame->frame_idx, task.frame->pts_ms, 0, 0, empty_res);
            }
            task.frame.reset();
            continue;
        }

        uint64_t f_idx = task.frame->frame_idx;
        int64_t pts = task.frame->pts_ms;

        DetectResult result;
        result.frame_idx = f_idx;
        result.pts_ms = pts;

        bool ok = target_model->infer_frame(task.frame, result);
        if (ok) {
            for (auto& obj : result.objects) {
                if (obj.model_name.empty()) {
                    obj.model_name = target_model->name();
                }
            }
        }
        task.frame.reset();

        if (task.callback) {
            if (!ok) {
                result.objects.clear();
            }
            task.callback(task.channel_id, f_idx, pts, result.orig_width, result.orig_height, result);
        }
    }
}
