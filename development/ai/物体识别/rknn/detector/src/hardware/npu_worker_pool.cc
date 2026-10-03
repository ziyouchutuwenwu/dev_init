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

bool NpuWorkerPool::init(std::shared_ptr<InferPipeline> master_pipeline, int core_count) {
    std::lock_guard<std::mutex> lock(_pool_mutex);
    if (_is_initialized.load()) {
        return true;
    }
    if (!master_pipeline || !master_pipeline->is_initialized()) {
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
        _workers[i].pipeline = master_pipeline->clone(core_masks[i]);
        if (!_workers[i].pipeline) {
            shutdown();
            return false;
        }
        _workers[i].thread = std::thread(&NpuWorkerPool::worker_loop, this, _workers[i].id, _workers[i].core_mask, _workers[i].pipeline);
    }

    _is_initialized.store(true);
    printf("[NpuWorkerPool] 初始化完成: 启动 %zu 个核心工作线程 (硬件核心数: %d)\n", _workers.size(), core_count);
    fflush(stdout);
    return true;
}

void NpuWorkerPool::shutdown() {
    std::lock_guard<std::mutex> lock(_pool_mutex);
    if (!_is_initialized.load() && !_running.load()) {
        return;
    }

    _running.store(false);
    _cv.notify_all();

    for (auto& w : _workers) {
        if (w.thread.joinable()) {
            w.thread.join();
        }
        if (w.pipeline) {
            w.pipeline->release();
            w.pipeline.reset();
        }
    }
    _workers.clear();

    {
        std::lock_guard<std::mutex> q_lock(_queue_mutex);
        while (!_queue.empty()) {
            _queue.pop();
        }
    }

    _is_initialized.store(false);
}

bool NpuWorkerPool::push_task(InferTask task) {
    if (!_running.load() || !_is_initialized.load()) {
        return false;
    }
    {
        std::lock_guard<std::mutex> lock(_queue_mutex);
        if (_queue.size() > 64) {
            _queue.pop();
        }
        _queue.push(std::move(task));
    }
    _cv.notify_one();
    return true;
}

void NpuWorkerPool::worker_loop(int worker_id, uint32_t core_mask, std::shared_ptr<InferPipeline> pipeline) {
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

        if (!task.frame || task.frame->data.empty() || !pipeline || !pipeline->is_initialized()) {
            if (task.callback) {
                DetectResult empty_res;
                task.callback(task.channel_id, task.frame ? task.frame->frame_idx : 0, task.frame ? task.frame->pts_ms : 0, 0, 0, empty_res);
            }
            continue;
        }

        void* in_buf = pipeline->input_buf();
        int in_w = pipeline->input_width();
        int in_h = pipeline->input_height();
        int in_c = pipeline->input_channel();
        if (!in_buf || in_w <= 0 || in_h <= 0) {
            if (task.callback) {
                DetectResult empty_res;
                task.callback(task.channel_id, task.frame->frame_idx, task.frame->pts_ms, 0, 0, empty_res);
            }
            continue;
        }

        image_buffer_t dst_img;
        memset(&dst_img, 0, sizeof(image_buffer_t));
        dst_img.width = in_w;
        dst_img.height = in_h;
        dst_img.width_stride = in_w;
        dst_img.height_stride = in_h;
        dst_img.format = IMAGE_FORMAT_RGB888;
        dst_img.virt_addr = (unsigned char*)in_buf;
        dst_img.size = (int)(in_w * in_h * in_c);
        dst_img.fd = -1;

        letterbox_t letter_box;
        memset(&letter_box, 0, sizeof(letterbox_t));
        int orig_w = 0, orig_h = 0;

        if (!VpuDecoder::letterbox_frame(task.frame, &dst_img, &letter_box, &orig_w, &orig_h)) {
            if (task.callback) {
                DetectResult empty_res;
                task.callback(task.channel_id, task.frame->frame_idx, task.frame->pts_ms, 0, 0, empty_res);
            }
            continue;
        }

        uint64_t f_idx = task.frame->frame_idx;
        int64_t pts = task.frame->pts_ms;
        task.frame.reset();

        DetectResult result;
        result.orig_width = orig_w;
        result.orig_height = orig_h;
        result.frame_idx = f_idx;
        result.pts_ms = pts;

        bool ok = pipeline->process(dst_img, result);
        if (task.callback) {
            if (!ok) {
                result.objects.clear();
            }
            task.callback(task.channel_id, f_idx, pts, orig_w, orig_h, result);
        }
    }
}
