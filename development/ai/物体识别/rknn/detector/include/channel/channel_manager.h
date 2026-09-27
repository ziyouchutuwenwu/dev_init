#ifndef CHANNEL_MANAGER_H
#define CHANNEL_MANAGER_H

#include <memory>
#include <mutex>
#include <unordered_map>

class Channel;

class ChannelManager {
public:
    static ChannelManager& instance();
    ~ChannelManager();

    std::shared_ptr<Channel> get(int ch);
    std::shared_ptr<Channel> create_one(int ch, int codec_type = 0);
    int release_one(int ch);
    int flush_one(int ch);
    int create_all(int total_streams);
    int release_all();

private:
    ChannelManager() = default;
    ChannelManager(const ChannelManager&) = delete;
    ChannelManager& operator=(const ChannelManager&) = delete;

    std::mutex _mutex;
    std::unordered_map<int, std::shared_ptr<Channel>> _channels;
};

#endif
