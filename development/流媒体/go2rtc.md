# go2rtc

## 说明

[官网](https://go2rtc.org/)

把各种视频流或者视频转为 webrtc

## 用法

### 准备

搜索 `FFmpeg Devices (USB)`，复制到 yaml 里面

```sh
http://127.0.0.1:1984
```

rtsp 准备

```sh
# mp4 转 rtsp
cvlc $HOME/downloads/videos/01.mp4 --loop --demux=avformat --sout '#rtp{sdp=rtsp://:18001/stream}'
```

### 配置

go2rtc.yaml

```yaml
api:
  origin: "*"

streams:
  camera_01: rtsp://127.0.0.1:18001/stream#transport=udp
  camera_02_mjpeg: ffmpeg:device?video=/dev/video0&input_format=mjpeg&video_size=1280x720
  camera_02: ffmpeg:camera_02_mjpeg#video=h264
```

导出的格式，推荐用 http, 延迟低，不卡顿

rtsp 如下

```sh
rtsp://127.0.0.1:8554/camera_01
rtsp://127.0.0.1:8554/camera_02
```

测试

```sh
ffplay rtsp://127.0.0.1:8554/camera_01
```
