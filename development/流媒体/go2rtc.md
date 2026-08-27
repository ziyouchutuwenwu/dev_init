# go2rtc

## 说明

[官网](https://github.com/AlexxIT/go2rtc/)

把各种视频流或者视频转为 webrtc

## 用法

无配置运行

```sh
http://127.0.0.1:1984
```

搜索 `FFmpeg Devices (USB)`，复制到摄像头配置的地方

go2rtc.yaml

```yaml
api:
  origin: "*"

ffmpeg:
  # 下面参数里面的 h264
  h264: "-codec:v libx264 -g:v 30 -preset:v ultrafast -tune:v zerolatency -profile:v main -level:v 4.1 -bf 0"
  opus: "-codec:a libopus -ar 48000 -ac 2"

# http://127.0.0.1:1984/stream.html?src=camera_01
# rtsp://127.0.0.1:8554/camera_01
streams:
  file_01: "ffmpeg:../videos/13.mp4#video=h264#audio=opus#input=file"
  camera_01: rtsp://127.0.0.1:8511/aa
  # 摄像头配置
  camera_02_mjpeg: ffmpeg:device?video=/dev/video0&input_format=mjpeg&video_size=1280x720
  camera_02: ffmpeg:camera_02_mjpeg#video=h264
```

测试

```sh
ffplay -x800 rtsp://127.0.0.1:8554/camera_01
```
