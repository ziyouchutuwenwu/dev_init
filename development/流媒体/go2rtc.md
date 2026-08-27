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
  bin: ffmpeg
  file: "-re -stream_loop -1 -i {input}"

streams:
  file_01: "ffmpeg:../videos/13.mp4#video=copy"
  file_02: "ffmpeg:../videos/14.mp4#video=copy"
```

测试

```sh
ffplay -x800 rtsp://127.0.0.1:8554/camera_01
```
