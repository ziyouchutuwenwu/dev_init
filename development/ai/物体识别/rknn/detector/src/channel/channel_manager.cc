#include "channel/channel_manager.h"
#include "channel/channel.h"
#include "engine/engine.h"
#include "hardware/channel_decoder.h"
#include "hardware/vpu_decoder.h"
#include "hardware/npu_infer.h"

ChannelManager& ChannelManager::instance() {
    static ChannelManager s_instance;
    return s_instance;
}

ChannelManager::~ChannelManager() {
    release_all();
}

std::shared_ptr<Channel> ChannelManager::get(int ch) {
    if (ch < 0 || ch >= 128) {
        return nullptr;
    }
    std::lock_guard<std::mutex> lock(_mutex);
    auto it = _channels.find(ch);
    if (it != _channels.end()) {
        if (it->second && it->second->is_valid()) {
            return it->second;
        }
        _channels.erase(it);
    }
    return nullptr;
}

std::shared_ptr<Channel> ChannelManager::create_one(int ch, int codec_type) {
    if (ch < 0 || ch >= 128) {
        return nullptr;
    }
    std::lock_guard<std::mutex> lock(_mutex);
    auto it = _channels.find(ch);
    if (it != _channels.end()) {
        if (it->second && it->second->is_valid()) {
            auto dec = ChannelDecoder::shareInstance().get(ch);
            if (dec && dec->codec_type() == codec_type) {
                return it->second;
            }
        }
        _channels.erase(it);
    }
    auto channel = std::make_shared<Channel>(ch, codec_type);
    if (!channel->is_valid()) {
        return nullptr;
    }
    _channels[ch] = channel;
    return channel;
}

int ChannelManager::release_one(int ch) {
    if (ch < 0 || ch >= 128) {
        return -1;
    }
    std::lock_guard<std::mutex> lock(_mutex);
    auto it = _channels.find(ch);
    if (it != _channels.end()) {
        _channels.erase(it);
        return 0;
    }
    return -1;
}

int ChannelManager::flush_one(int ch) {
    if (ch < 0 || ch >= 128) {
        return -1;
    }
    std::shared_ptr<Channel> channel;
    {
        std::lock_guard<std::mutex> lock(_mutex);
        auto it = _channels.find(ch);
        if (it != _channels.end()) {
            channel = it->second;
        }
    }
    if (channel) {
        return channel->flush();
    }
    ChannelDecoder::shareInstance().flush_decoder(ch);
    NpuInfer::shareInstance().flush_channel(ch);
    return 0;
}

int ChannelManager::create_all(int total_streams) {
    if (total_streams <= 0 || total_streams > 128) {
        return -1;
    }
    if (Engine::instance().init() != 0) {
        return -1;
    }
    for (int ch = 0; ch < total_streams; ++ch) {
        if (!create_one(ch)) {
            for (int r = 0; r < ch; ++r) {
                release_one(r);
            }
            return -1;
        }
    }
    return 0;
}

int ChannelManager::release_all() {
    std::lock_guard<std::mutex> lock(_mutex);
    _channels.clear();
    return 0;
}
