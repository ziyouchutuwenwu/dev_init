#ifndef NPU_WORKER_POOL_H
#define NPU_WORKER_POOL_H

#include <vector>
#include <queue>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <memory>
#include <functional>
#include "ai/infer_manager/infer_manager.h"
#include "ai/infer_manager/detect_result.h"
#include "hardware/vpu_decoder.h"

struct InferTask {
    int channel_id = -1;
    std::string model_name;
    std::shared_ptr<VpuDecoder::FrameBuffer> frame;
    std::function<void(int ch, uint64_t frame_idx, int64_t pts_ms, int orig_w, int orig_h, const DetectResult& result)> callback;
};

class NpuWorkerPool {
public:
    static NpuWorkerPool& instance();

    bool init(std::shared_ptr<InferManager> master_manager, int core_count = 0);
    void shutdown();
    bool is_initialized() const { return _is_initialized.load(); }

    bool push_task(InferTask task);

    int worker_count() const;

private:
    NpuWorkerPool();
    ~NpuWorkerPool();

    NpuWorkerPool(const NpuWorkerPool&) = delete;
    NpuWorkerPool& operator=(const NpuWorkerPool&) = delete;

    void worker_loop(int worker_id, uint32_t core_mask, std::shared_ptr<InferManager> manager);

    std::atomic<bool> _is_initialized{false};
    std::atomic<bool> _running{false};

    std::queue<InferTask> _queue;
    std::mutex _queue_mutex;
    std::condition_variable _cv;

    struct WorkerContext {
        int id = 0;
        uint32_t core_mask = 0;
        std::shared_ptr<InferManager> manager;
        std::thread thread;
    };
    std::vector<WorkerContext> _workers;
    std::recursive_mutex _pool_mutex;
};

#endif
