#pragma once

#include <map>
#include <memory>
#include <mutex>

class VpuDecoder;

class ChannelDecoder {
public:
    static ChannelDecoder& shareInstance();

    std::shared_ptr<VpuDecoder> create_decoder(int ch, int codec_type = 0);
    std::shared_ptr<VpuDecoder> get(int ch);
    std::shared_ptr<VpuDecoder> get_or_create(int ch, int codec_type = 0);
    bool release_decoder(int ch);
    bool flush_decoder(int ch);
    void release_all();

private:
    ChannelDecoder() = default;
    std::mutex _map_mutex;
    std::map<int, std::shared_ptr<VpuDecoder>> _decoders;
};
