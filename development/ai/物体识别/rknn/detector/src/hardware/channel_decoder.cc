#include "hardware/channel_decoder.h"
#include "hardware/vpu_decoder.h"
#include <cstdio>
#include <vector>

ChannelDecoder& ChannelDecoder::shareInstance() {
    static ChannelDecoder s_instance;
    return s_instance;
}

std::shared_ptr<VpuDecoder> ChannelDecoder::create_decoder(int ch, int codec_type) {
    std::lock_guard<std::mutex> lock(_map_mutex);
    auto it = _decoders.find(ch);
    if (it != _decoders.end()) {
        if (it->second && !it->second->is_released()) {
            if (it->second->codec_type() != codec_type) {
                it->second->set_codec_type(codec_type);
                it->second->release_mpp();
            } else {
                it->second->flush();
                return it->second;
            }
        }
        _decoders.erase(it);
    }
    auto decoder = std::make_shared<VpuDecoder>(codec_type);
    _decoders[ch] = decoder;
    printf("已显式为通道 %d 初始化独立的 vpu 解码器 (codec=%s)\n", ch, (codec_type == 1 ? "HEVC/H.265" : "AVC/H.264"));
    return decoder;
}

std::shared_ptr<VpuDecoder> ChannelDecoder::get(int ch) {
    std::lock_guard<std::mutex> lock(_map_mutex);
    auto it = _decoders.find(ch);
    if (it != _decoders.end()) {
        if (it->second && !it->second->is_released()) {
            return it->second;
        }
        _decoders.erase(it);
    }
    return nullptr;
}

std::shared_ptr<VpuDecoder> ChannelDecoder::get_or_create(int ch, int codec_type) {
    return create_decoder(ch, codec_type);
}

bool ChannelDecoder::release_decoder(int ch) {
    std::shared_ptr<VpuDecoder> dec;
    {
        std::lock_guard<std::mutex> lock(_map_mutex);
        auto it = _decoders.find(ch);
        if (it != _decoders.end()) {
            dec = it->second;
            _decoders.erase(it);
        }
    }
    if (dec) {
        dec->release_mpp();
        printf("已释放通道 %d 的 vpu 解码器及 drm 显存资源\n", ch);
        return true;
    }
    return false;
}

bool ChannelDecoder::flush_decoder(int ch) {
    std::shared_ptr<VpuDecoder> dec;
    {
        std::lock_guard<std::mutex> lock(_map_mutex);
        auto it = _decoders.find(ch);
        if (it != _decoders.end()) {
            dec = it->second;
        }
    }
    if (dec) {
        dec->flush();
        return true;
    }
    return false;
}

void ChannelDecoder::release_all() {
    std::vector<std::shared_ptr<VpuDecoder>> to_release;
    {
        std::lock_guard<std::mutex> lock(_map_mutex);
        for (auto& pair : _decoders) {
            if (pair.second) {
                to_release.push_back(pair.second);
            }
        }
        _decoders.clear();
    }
    for (auto& dec : to_release) {
        dec->release_mpp();
    }
    printf("已释放全部通道的 vpu 解码器资源\n");
}
