#ifndef ENGINE_H
#define ENGINE_H

class Engine {
public:
    static Engine& instance();

    int init();
    int deinit();
    bool is_inited() const { return _inited; }
    bool is_infer_ready() const;
    bool try_restore_engine();

private:
    Engine() = default;
    ~Engine();
    Engine(const Engine&) = delete;
    Engine& operator=(const Engine&) = delete;

    bool _inited{false};
};

#endif
