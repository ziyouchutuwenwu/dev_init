# mediamtx

## 说明

[官网](https://github.com/bluenviron/mediamtx)

流媒体网关，把某个输入，转换为很多种流媒体输出

## 用法

mediamtx.yml

```yaml
logLevel: debug
logDestinations: [stdout]

rtsp: yes
rtspAddress: :8511

webrtc: yes
webrtcAddress: :8512

rtmp: yes
rtmpAddress: :8513

hls: yes
hlsAddress: :8514

# 抗丢包，rtmp 替代者
srt: yes
srtAddress: :8515

# rtsp://127.0.0.1:8511/aa
# http://127.0.0.1:8512/aa/
paths:
  aa:
    # 支持相对路径
    runOnInit: ffmpeg -re -stream_loop -1 -i ../videos/13.mp4 -c:v libx264 -preset ultrafast -tune zerolatency -g 30 -c:a libopus -f rtsp rtsp://127.0.0.1:$RTSP_PORT/$MTX_PATH
    runOnInitRestart: yes
```
